`timescale 1ns / 1ps

module comparador_temp(
    input logic signed [10:0] temp_entrada,     // temperatura de entrada del sensor
    output logic es_bajo,                       // temp < 180 (para contador frío)
    output logic es_alto                        // temp > 259 (para contador calor)
);

    // Parámetros de rango ya escalado
    parameter TEMP_BAJO = 180;   // 18°C se fija la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 259;   // 25.9°C se fija la temperatura como limite maximo para alto

    // Comparación de la temperatura
    assign es_bajo = (temp_entrada < TEMP_BAJO); // devuelve si la temperatura registrada esta en el rango bajo
    assign es_alto = (temp_entrada > TEMP_ALTO); // devuelve si la temperatura registrada esta en el rango alto

endmodule