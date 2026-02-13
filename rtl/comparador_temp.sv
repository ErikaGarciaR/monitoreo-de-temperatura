`timescale 1ns / 1ps

module comparador_temp(
    input logic signed [10:0] temp_entrada,     // temperatura de entrada del sensor
    output logic fuera_rango                    // indicador fuera de rango normal
);

    // Parámetros de rango ya escalado
    parameter TEMP_BAJO = 180;   // 18°C se fija la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 259;   // 25.9°C se fija la temperatura como limite maximo para alto

    // Comparación de la temperatura
    assign fuera_rango = (temp_entrada < TEMP_BAJO) || (temp_entrada > TEMP_ALTO); // devuelve si la temperatura registrada esta fuera de lo normal 

endmodule