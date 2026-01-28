`timescale 1ns / 1ps

module comparador_temp(
    input logic signed [10:0] temp_reg,   // temperatura desde obtenida de modulo registro_temp
    output logic fuera_rango             // indicador fuera de rango normal
);

    // Parámetros de rango ya escalado
    parameter TEMP_BAJO = 180;   // 18°C se fija la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 250;   // 25°C se fija la temperatura como limite maximo para alto

    // Comparación de la temperatura
    assign fuera_rango = (temp_reg < TEMP_BAJO) || (temp_reg > TEMP_ALTO); // devuelve si la temperatura registrada esta fuera de lo normal 

endmodule