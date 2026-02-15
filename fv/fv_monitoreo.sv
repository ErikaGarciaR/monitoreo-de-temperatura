// fv/fv_monitoreo.sv

module fv_monitoreo (
    // Agregar todas las señales a vigilar
    input logic clk,
    input logic arst_n,
    input logic signed [10:0] temp_entrada,
    input logic alerta,
    input logic ventilador,
    input logic calefactor,
    input logic [1:0] estado_actual

);

    // Verificacion Reset
    `AST(mon, alerta_en_reset,     (!arst_n) |->, (alerta == 0))
    `AST(mon, ventilador_en_reset, (!arst_n) |->, (ventilador == 0))
    `AST(mon, calefactor_en_reset, (!arst_n) |->, (calefactor == 0))

    // Persistencia en frio
    
    `AST(mon, persistencia_frio, ((temp_entrada < 11'sd180)[*6]) |->, (alerta == 1 && calefactor == 1))

    // Persistencia en calor
    `AST(mon, persistencia_calor, ((temp_entrada > 11'sd259)[*6]) |->,(alerta == 1 && ventilador == 1))

    //Estabilidad en normal
    `AST(mon, estabilidad_normal, (temp_entrada >= 11'sd180 && temp_entrada <= 11'sd259) |=>, (alerta == 0))

    // Recuperación a normal
    `AST(mon, recuperacion_normal, (estado_actual == 2'b00) |->, (alerta == 0))

    // 4. Exclusión Mutua 
    `AST(mon, exclusion, 1'b1 |->, (!(calefactor && ventilador)))

    //
    
    `AST(mon, salida_alerta,(alerta == 1 && $past(temp_entrada) >=11'sd180 && $past(temp_entrada) <=11'sd259) |=>,(alerta == 0))

    // El calefactor no debe encenderse si la temperatura no es baja
   `AST(mon, seguridad_calefactor, (calefactor == 1) |->, ($past(temp_entrada,5) <11'sd180))

    // El ventilador no debe encenderse si la temperatura no es alta
    `AST(mon, seguridad_ventilador, (ventilador == 1) |->,($past(temp_entrada, 5) > 11'sd259))
    // Para transiciones en los limites para temperaturas bajas
    `AST(mon, transicion_frio_normal,($past(temp_entrada) < 180 && temp_entrada >= 180 && temp_entrada <= 259) |=>,(estado_actual == 2'b00)[*2])
    `AST(mon, transicion_frio_calor,($past(temp_entrada) < 180 && temp_entrada > 259) |=>,(estado_actual == 2'b10)[*2])

endmodule

// Conexion de las señales de fv_monitoreo con las señales internas de monitoreo_top 
bind monitoreo_top fv_monitoreo fv_mon_inst (.*);