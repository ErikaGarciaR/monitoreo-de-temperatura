`timescale 1ns / 1ps

module top_wishbone #(
    parameter AW = 16,
    parameter DW = 32
) (
    // Interfaz con testbench
    input  logic          clk,
    input  logic          rst_n,
    input  logic [AW-1:0] m0_cmd_addr,
    input  logic [DW-1:0] m0_cmd_wdata,
    input  logic          m0_cmd_we,
    input  logic          m0_cmd_valid,
    output logic          m0_cmd_ready,
    output logic [DW-1:0] m0_rsp_rdata,
    output logic          m0_rsp_valid,



    // Entrada de temperatura externa
    input  logic signed [10:0] temp_sensor,
    input  logic               sensor_valid,
    // Salidas del monitor
    output logic               alerta,
    output logic               calefactor,
    output logic               ventilador,
    output logic        [ 1:0] estado_actual,
    output logic        [ 2:0] cont_bajo,
    output logic        [ 2:0] cont_alto
);
  // Señales internas para conectar master con monitor

  logic [AW-1:0] wb_adr;
  logic [DW-1:0] wb_dat_m2s;
  logic [DW-1:0] wb_dat_s2m;
  logic          wb_we;
  logic [   3:0] wb_sel;
  logic          wb_stb;
  logic          wb_cyc;
  logic          wb_ack;
  // MASTER 
  wb_master #(
      .AW(AW),
      .DW(DW)
  ) u_m0 (
      .clk      (clk),
      .rst_n    (rst_n),
      .cmd_addr (m0_cmd_addr),
      .cmd_wdata(m0_cmd_wdata),
      .cmd_we   (m0_cmd_we),
      .cmd_valid(m0_cmd_valid),
      .cmd_ready(m0_cmd_ready),
      .rsp_rdata(m0_rsp_rdata),
      .rsp_valid(m0_rsp_valid),
      .wbm_adr_o(wb_adr),
      .wbm_dat_o(wb_dat_m2s),
      .wbm_dat_i(wb_dat_s2m),
      .wbm_we_o (wb_we),
      .wbm_sel_o(wb_sel),
      .wbm_stb_o(wb_stb),
      .wbm_cyc_o(wb_cyc),
      .wbm_ack_i(wb_ack),
      .wbm_err_i(1'b0)
  );

  // MONITOR 
  monitoreo_top #(
      .AW(AW),
      .DW(DW)
  ) u_monitor (
      .clk          (clk),
      .rst_n        (rst_n),
      .temp_entrada (temp_sensor),
      .sensor_valid (sensor_valid),
      .alerta       (alerta),
      .calefactor   (calefactor),
      .ventilador   (ventilador),
      .estado_actual(estado_actual),
      .cont_bajo    (cont_bajo),
      .cont_alto    (cont_alto),
      .wbs_adr_i    (wb_adr),
      .wbs_dat_i    (wb_dat_m2s),
      .wbs_dat_o    (wb_dat_s2m),
      .wbs_we_i     (wb_we),
      .wbs_sel_i    (wb_sel),
      .wbs_stb_i    (wb_stb),
      .wbs_cyc_i    (wb_cyc),
      .wbs_ack_o    (wb_ack),
      .wbs_err_o    ()
  );

endmodule
