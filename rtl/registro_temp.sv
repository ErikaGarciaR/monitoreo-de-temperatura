`timescale 1ns / 1ps

module registro_temp (
    input logic clk,                            // reloj del sistema
    input logic arst_n,                         // reset asincrono
    input logic signed [10:0] temp_entrada,     // temperatura digitalizada (-400 a 850)
    output logic signed [10:0] temp_registrado // valor almacenado de temperatura
);

    // Guarda la temperatura y controla el contador
    always_ff @( posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            temp_registrado <= 220; // valor estable
        end else begin
            temp_registrado <= temp_entrada;  // almacena el valor actual de temperatura

        end
    end

endmodule