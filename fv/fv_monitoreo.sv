// fv/fv_monitoreo.sv

module fv_monitoreo (
    // Agregar todas las señales a vigilar
    input logic clk,
    input logic arst_n,
    input logic signed [10:0] temp_entrada,
    input logic alerta,
    input logic ventilador,
    input logic calefactor,
    logic [1:0] estado_actual

);

    // Verificacion Reset
    `AST(mon, alerta_en_reset,     (!arst_n) |->, (alerta == 0))
    `AST(mon, ventilador_en_reset, (!arst_n) |->, (ventilador == 0))
    `AST(mon, calefactor_en_reset, (!arst_n) |->, (calefactor == 0))

    // Persistencia en frio
    
    `AST(mon, persistencia_frio, ((temp_entrada < 11'd180)[*6]) |=>, (alerta == 1 && calefactor == 1))

    // Recuperación a normal
    `AST(mon, recu_normal, (estado_actual == 2'b00) |->, (alerta == 0))

    // 4. Exclusión Mutua 
    `AST(mon, exclusion, 1'b1 |->, (!(calefactor && ventilador)))


endmodule

// Conexion de las señales de fv_monitoreo con las señales internas de monitoreo_top 
bind monitoreo_top fv_monitoreo fv_mon_inst (.*);