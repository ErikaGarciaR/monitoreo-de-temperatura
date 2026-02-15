// property_defines.svh
`define AST(block=mem_sys_sdram, name=no_name, precond=1'b1 |->, consq=1'b0) \
``block``_ast_``name``: assert property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);

`define ASM(block=mem_sys_sdram, name=no_name, precond=1'b1 |->, consq=1'b0) \
``block``_asm_``name``: assume property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);

`define COV(block=mem_sys_sdram, name=no_name, precond=1'b1 |->, consq=1'b0) \
``block``_cov_``name``: cover property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);

`define REUSE(top=1'b0, block=mem_sys_sdram, name=no_name, precond=1'b1 |->, consq=1'b0)                        \
  if(top==1'b1) begin                                                                                           \
    ``block``_asm_``name``: assume property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);        \
  end else begin                                                                                                \
    ``block``_ast_``name``: assert property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);        \
  end