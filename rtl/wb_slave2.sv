`timescale 1ns / 1ps

module wb_slave2 #(
    parameter AW = 16,
    parameter DW = 32
) (
    // Wishbone esclavo
    input  logic          clk,
    input  logic          rst_n,
    input  logic [AW-1:0] wbs_adr_i,
    input  logic [DW-1:0] wbs_dat_i,
    output logic [DW-1:0] wbs_dat_o,
    input  logic          wbs_we_i,
    input  logic [   3:0] wbs_sel_i,
    input  logic          wbs_stb_i,
    input  logic          wbs_cyc_i,
    output logic          wbs_ack_o,
    output logic          wbs_err_o,

    // Entrada de temperatura externa del interface
    input  logic signed [10:0] temp_entrada,
    input  logic               sensor_valid,
    // Salidas  (para ver en testbench)
    output logic               alerta,
    output logic               calefactor,
    output logic               ventilador,
    output logic        [ 1:0] estado_actual,
    output logic        [ 2:0] cont_bajo,
    output logic        [ 2:0] cont_alto
);
  ///////////////////////////////////////////////////////////////////////////////
  // Señales internas
  logic es_bajo, es_alto;
  logic per_bajo, per_alto;
  logic signed [10:0] temp_reg;  // Registro de temperatura
  logic               data_valid;  // Bit de dato válido
  logic wb_valid, wb_read;
  logic [31:0] control_reg;
  // Registro de control (RW)
  // Bits de control
  logic enable;
  logic reset_count;
  logic modo_test;
  // Registro de status (RO)
  logic [31:0] status_reg;
  //Senales internos para la FSM
  logic alerta_int, calefactor_int, ventilador_int;

  logic reset_interno;
  assign reset_interno = rst_n & enable;
  // 1. COMPARADOR 
  comparador_temp u_comp (
      .temp_entrada(temp_entrada),
      .es_bajo(es_bajo),
      .es_alto(es_alto)
  );

  // 2. PERSISTENCIA 
  persistencia_ctr #(
      .N(5)
  ) u_persistencia (
      .clk         (clk),
      .arst_n      (reset_interno),
      .es_bajo     (es_bajo),
      .es_alto     (es_alto),
      .sensor_valid(sensor_valid),
      .cont_bajo   (cont_bajo),
      .cont_alto   (cont_alto),
      .per_bajo    (per_bajo),
      .per_alto    (per_alto)
  );

  // 3. FSM 
  estado_temp u_fsm (
      .clk            (clk),
      .arst_n         (rst_n),
      .temp_registrado(temp_entrada),
      .per_bajo       (per_bajo),
      .per_alto       (per_alto),
      .alerta         (alerta_int),
      .calefactor     (calefactor_int),
      .ventilador     (ventilador_int),
      .estado_actual  (estado_actual)
  );

  //para controlar con enable 
  assign alerta      = alerta_int & enable;
  assign calefactor  = calefactor_int & enable;
  assign ventilador  = ventilador_int & enable;
  //////////////////////////////////////////////////////////////////////////////////



  assign enable      = control_reg[0];  // habilita desde master
  assign reset_count = control_reg[1];
  assign modo_test   = control_reg[3];
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      temp_reg   <= '0;
      data_valid <= 1'b0;
    end else begin
      // Cada nueva medición del sensor
      if (sensor_valid && enable) begin
        temp_reg   <= temp_entrada;  // Guardar último valor
        data_valid <= 1'b1;  // Avisa al procesador
      end

      // Desactivar cuando el procesador lee la temperatura
      if (wb_read && wbs_adr_i == 16'h0000) begin
        data_valid <= 1'b0;
        $display("[%0t] MONITOR: data_valid desactivado por lectura 0x3000", $time);
      end
    end
  end



  assign status_reg = {
    30'b0,  // bits [31:2] reservados
    alerta,  // bit 1: alerta activa
    data_valid  // bit 0: temperatura 
  };


  ////////////////////////////////////////////////////////////////////////////////////////////
  // WISHBONE 


  assign wb_valid = wbs_stb_i && wbs_cyc_i;
  assign wb_read = wb_valid && !wbs_we_i;
  assign wbs_err_o = 1'b0;

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      wbs_ack_o   <= 1'b0;
      wbs_dat_o   <= '0;
      control_reg <= '0;
    end else begin
      wbs_ack_o <= 1'b0;  // Default

      // LECTURAS
      if (wb_read) begin
        $display("[%0t] MONITOR: wb_read=1, addr=0x%04h", $time, wbs_adr_i);
        case (wbs_adr_i)
          // Direcciones para el sistema de monitoreo

          16'h0000: wbs_dat_o <= {{21{temp_reg[10]}}, temp_reg};
          16'h0004: wbs_dat_o <= {29'b0, cont_bajo};
          16'h0008: wbs_dat_o <= {29'b0, cont_alto};
          16'h000C: wbs_dat_o <= {31'b0, per_bajo};
          16'h0010: wbs_dat_o <= {31'b0, per_alto};
          16'h0014: wbs_dat_o <= {30'b0, estado_actual};
          16'h0018: wbs_dat_o <= {31'b0, alerta};
          16'h001C: wbs_dat_o <= {31'b0, calefactor};
          16'h0020: wbs_dat_o <= {31'b0, ventilador};

          // DIRECCIONES PARA CONTROL Y STATUS
          16'h3010: wbs_dat_o <= control_reg;  // CONTROL
          16'h3014: wbs_dat_o <= status_reg;  // STATUS

          default: wbs_dat_o <= 32'hDEADBEEF;
        endcase
        wbs_ack_o <= 1'b1;
        $display("[%0t] MONITOR: Lectura dir=0x%04h data=0x%08h", $time, wbs_adr_i, wbs_dat_o);
      end

      // ESCRITURAS 
      if (wb_valid && wbs_we_i) begin
        // Escritura en registro de control
        if (wbs_adr_i == 16'h3010) begin
          control_reg <= wbs_dat_i;
          wbs_ack_o   <= 1'b1;
          $display("[%0t] MONITOR: Control escrito = 0x%08h", $time, wbs_dat_i);

        end else begin
          $display("[%0t] MONITOR: Escritura ignorada en dir=0x%04h", $time, wbs_adr_i);
          wbs_ack_o <= 1'b1;
        end
      end
    end
  end

endmodule
