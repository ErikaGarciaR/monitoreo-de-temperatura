// =============================================================================
// wb_master.sv
// Wishbone B4 master
//
// Command interface (from testbench / parent):
//   cmd_valid  – assert for one cycle to start a transaction
//   cmd_ready  – high when master is idle (safe to assert cmd_valid)
//   cmd_addr   – target byte address
//   cmd_wdata  – write data
//   cmd_we     – 1 = write, 0 = read
//
// Response interface:
//   rsp_valid  – one-cycle pulse when the WB ACK is received
//   rsp_rdata  – captured read data (valid when rsp_valid=1)
//
// The master drives STB/CYC together and waits for ACK.
// A single outstanding transaction at a time.
// =============================================================================

`timescale 1ns / 1ps

module wb_master #(
    parameter AW = 16,
    parameter DW = 32
) (
    input logic clk,
    input logic rst_n,

    // ---- Command interface ----
    input  logic [AW-1:0] cmd_addr,
    input  logic [DW-1:0] cmd_wdata,
    input  logic          cmd_we,
    input  logic          cmd_valid,
    output logic          cmd_ready,

    // ---- Response interface ----
    output logic [DW-1:0] rsp_rdata,
    output logic          rsp_valid,

    // ---- Wishbone master port ----
    output logic [AW-1:0] wbm_adr_o,
    output logic [DW-1:0] wbm_dat_o,
    input  logic [DW-1:0] wbm_dat_i,
    output logic          wbm_we_o,
    output logic [   3:0] wbm_sel_o,
    output logic          wbm_stb_o,
    output logic          wbm_cyc_o,
    input  logic          wbm_ack_i,
    input  logic          wbm_err_i
);

  typedef enum logic {
    IDLE   = 1'b0,
    ACTIVE = 1'b1
  } state_e;

  state_e state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      wbm_adr_o <= '0;
      wbm_dat_o <= '0;
      wbm_we_o  <= 1'b0;
      wbm_sel_o <= 4'b0;
      wbm_stb_o <= 1'b0;
      wbm_cyc_o <= 1'b0;
      rsp_rdata <= '0;
      rsp_valid <= 1'b0;
    end else begin
      rsp_valid <= 1'b0;  // default: no response pulse

      case (state)
        IDLE: begin
          if (cmd_valid) begin
            wbm_adr_o <= cmd_addr;
            wbm_dat_o <= cmd_wdata;
            wbm_we_o  <= cmd_we;
            wbm_sel_o <= 4'hF;  // all byte lanes active
            wbm_stb_o <= 1'b1;
            wbm_cyc_o <= 1'b1;
            state     <= ACTIVE;
          end
        end

        ACTIVE: begin
          if (wbm_ack_i || wbm_err_i) begin
            wbm_stb_o <= 1'b0;
            wbm_cyc_o <= 1'b0;
            rsp_rdata <= wbm_dat_i;  // captured for reads
            rsp_valid <= 1'b1;
            state     <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  assign cmd_ready = (state == IDLE);

endmodule
