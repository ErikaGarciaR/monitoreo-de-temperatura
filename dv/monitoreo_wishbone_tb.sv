`define T_NORMAL_B


`timescale 1ns / 1ps
import monitoreo_pkg::*;

module monitoreo_tb ();

  initial begin
    $timeformat(-9, 0, " ns", 10);
  end

  bit          clk;  //reloj del sistema
  bit          arst_n;  // reset asincrono activo en bajo
  // ---SEÑALES WISHBONE ---
  logic [15:0] m0_cmd_addr;
  logic [31:0] m0_cmd_wdata;
  logic        m0_cmd_we;
  logic        m0_cmd_valid;
  logic        m0_cmd_ready;
  logic [31:0] m0_rsp_rdata;
  logic        m0_rsp_valid;

  logic [31:0] read_data;
  parameter AW = 16;
  parameter DW = 32;
  // ---------------------------------
  // Instancia de la interfaz
  interface_monitoreo intf (
      clk,
      arst_n
  );

  // Instancia del dut
  top2_wishbone #(
      .AW(AW),
      .DW(DW)
  ) dut (
      .clk          (clk),
      .rst_n        (arst_n),
      .m0_cmd_addr  (m0_cmd_addr),
      .m0_cmd_wdata (m0_cmd_wdata),
      .m0_cmd_we    (m0_cmd_we),
      .m0_cmd_valid (m0_cmd_valid),
      .m0_cmd_ready (m0_cmd_ready),
      .m0_rsp_rdata (m0_rsp_rdata),
      .m0_rsp_valid (m0_rsp_valid),
      .temp_sensor  (intf.temp_entrada),
      .sensor_valid (intf.sensor_valid),
      .alerta       (intf.alerta),
      .calefactor   (intf.calefactor),
      .ventilador   (intf.ventilador),
      .estado_actual(intf.estado_actual),
      .cont_alto    (intf.cont_alto),
      .cont_bajo    (intf.cont_bajo)
  );
  // Inicializacion de reloj
  initial clk = 0;
  always #5ns clk = ~clk;  // Periodo 10ns (100 MHz)

  initial begin
    arst_n            = 0;  // Reset activo desde tiempo 0
    intf.temp_entrada = 220;
    intf.sensor_valid = 0;
    m0_cmd_addr       = '0;
    m0_cmd_wdata      = '0;
    m0_cmd_we         = 1'b0;
    m0_cmd_valid      = 1'b0;
    read_data         = 32'b0;
    #100ns;  // Espera 2 ciclos completos
    arst_n = 1;  // Libera reset
    $display(
        "================================================================================================");
    $display("[TB] Reset liberado en tiempo %0t", $time);
  end

  // instanciar objetos de la clase
  temp_bajo        t_frio;
  temp_alto        t_calor;
  temp_normal      t_normal;
  temp_persistente t_pers;
  temp_fuera_rango t_limite;


  // ------------------------------------------------------------------------------------------
  // Tareas de escritura/lectura
  task automatic m0_write(input logic [AW-1:0] addr, input logic [DW-1:0] data);
    $display("[%0t] M0 WR addr=0x%04h data=0x%08h", $time, addr, data);
    @(posedge clk);
    while (!m0_cmd_ready) @(posedge clk);
    m0_cmd_addr  <= addr;
    m0_cmd_wdata <= data;
    m0_cmd_we    <= 1'b1;
    m0_cmd_valid <= 1'b1;
    @(posedge clk);
    m0_cmd_valid <= 1'b0;
    while (!m0_rsp_valid) @(posedge clk);
    $display("[%0t] M0 WR ACK received", $time);
  endtask

  task automatic m0_read(input logic [AW-1:0] addr, output logic [DW-1:0] data);
    $display("[%0t] M0 RD addr=0x%04h", $time, addr);
    @(posedge clk);
    while (!m0_cmd_ready) @(posedge clk);
    m0_cmd_addr  <= addr;
    m0_cmd_wdata <= '0;
    m0_cmd_we    <= 1'b0;
    m0_cmd_valid <= 1'b1;
    @(posedge clk);
    m0_cmd_valid <= 1'b0;
    while (!m0_rsp_valid) @(posedge clk);
    data = m0_rsp_rdata;
    $display("[%0t] M0 RD data=0x%08h", $time, data);
  endtask

  // ------------------------------------------------------------------------------------------

  initial begin

    wait (arst_n == 1'b1);
    @(posedge clk);

    // inicializacion
    t_frio   = new();
    t_calor  = new();
    t_normal = new();
    t_pers   = new(150);
    t_limite = new();


    $display(
        "--- ---------------------------------Iniciando  verificacion de control -------------------------");

    // 1. Probar CONTROL
    $display("\n--- CONTROL (0x3010) ---");
    m0_read(16'h3010, read_data);
    $display("Control inicial: 0x%08h", read_data);

    m0_write(16'h3010, 32'h00000009);
    m0_read(16'h3010, read_data);
    if (read_data == 32'h00000009) $display(" CONTROL OK");
    else $display("CONTROL ERROR");

    // 2. Probar STATUS con una temperatura
    $display("\n--- STATUS (0x3014) ---");
    m0_read(16'h3014, read_data);
    $display("Status inicial: data_valid=%b", read_data[0]);
    $display(
        "-------------------------------------- Simulación terminada--------------------------------- ---");
    //.............................Casos operacion basica.............................
`ifdef T_NORMAL_B
    test_recuperacion_bajo();
`endif

    $display(
        "\n-------------------------------------- Verificación de Auto-Limpieza ------------------------");
    //  dato manual para probar el bit por fuera
    intf.enviar_temperatura(250);
    repeat (2) @(posedge clk);

    m0_read(16'h3014, read_data);
    if (read_data[0]) $display("Status: data_valid se activó con nuevo dato");

    //
    m0_read(16'h0000, read_data);
    repeat (2) @(posedge clk);

    m0_read(16'h3014, read_data);
    if (read_data[0] == 0) $display("Status: data_valid se limpió correctamente tras la lectura");

    repeat (5) @(posedge clk);
    $display(
        "-------------------------------------- Simulación terminada--------------------------------- ---");
    $finish;

  end


  // casos de prueba 
  //================================================================================

  task test_recuperacion_bajo();
    logic [31:0] temp_leida;
    logic [31:0] status_val;

    $display("\n[TEST CASE] T_RECU_AUTO - Forzando Alerta y luego Recuperación BAJO a NORMAL");
    // 1. Forzando persistencia 
    if (!t_frio.randomize()) $fatal("No se pudo generar valor de frio inicial");
    t_pers = new(t_frio.valor);  // Forzamos inicio en zona de frío
    //$display("\n[TB] Temperatura inicializada %0d", t_pers.valor);
    repeat (5) begin
      void'(t_pers.randomize() with {valor < 180;});
      intf.enviar_temperatura(t_pers.valor);
      intf.reporte_estado();
    end
    @(posedge clk);

    intf.reporte_estado();
    if (intf.estado_actual !== 2'b11) begin
      $error("[FAIL] No se alcanzó ALERTA");
      intf.reporte_estado();
      return;
    end

    $display("\n[%0t] [MASTER] Iniciando monitoreo de STATUS_REG...", $time);

    status_val = 0;
    // Mientras el bit 1 (alerta) sea 0
    while ((status_val & 32'h0000_0002) == 0) begin
      m0_read(16'h3014, status_val);

      if ((status_val & 2) == 0) begin
        $display("[%0t] [MASTER] Alerta no detectada aún. Reintentando...", $time);
        @(posedge clk);
      end
    end

    // Solo cuando hay alerta, el maestro lee el dato de la temperatura
    $display("\n[%0t] [MASTER] ¡ALERTA CONFIRMADA EN STATUS!", $time);
    m0_read(16'h0000, temp_leida);
    $display("[%0t] [MASTER] Temperatura de falla capturada: %0d", $time, $signed(
                                                                              temp_leida[10:0]));

    // probando la recuperacion a normal
    $display("[TB] Enviando temperatura normal  para recuperar...");
    if (!t_normal.randomize()) $fatal("No se pudo generar valor de normal inicial");
    repeat (2) begin
      intf.enviar_temperatura(t_normal.valor);
      intf.reporte_estado();
    end
    @(posedge clk);
    // procesando el cambio
    intf.reporte_estado();
    if (intf.alerta == 0 && intf.estado_actual == 2'b00) begin
      $display("[TB] El sistema se normalizó correctamente.");
      intf.reporte_estado();
    end else begin
      $display("[TB] El sistema NO se recuperó. Estado: %b, Alerta: %b", intf.estado_actual,
               intf.alerta);
    end

  endtask


endmodule


