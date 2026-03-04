`timescale 1ns / 1ps

module persistencia_ctr #(parameter N = 5)(
    input  logic clk,               // reloj del sistema
    input  logic arst_n,            // reset asincrono
    input  logic es_bajo,           // temp < 180
    input  logic es_alto,           // temp > 259
    output logic [2:0] cont_bajo,   // Contador para temperatura baja
    output logic [2:0] cont_alto,   // Contador para temperatura alta
    output logic per_bajo,          // Persistencia de frío
    output logic per_alto           // Persistencia de calor
);
    
    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            // Reset asíncrono: ambos contadores se inicializan a cero
            cont_bajo <= 3'd0;
            cont_alto <= 3'd0;
        end else begin
            if (es_bajo) begin
                if (cont_bajo < N) 
                    cont_bajo <= cont_bajo + 1;
                // Si ya alcanzó N, mantiene el valor (no incrementa más)
            end else begin
                // Si la condición deja de cumplirse, resetea el contador
                cont_bajo <= 3'd0;
            end
            // Contador de calor: incrementa mientras es_alto esté activo
            if (es_alto) begin
                if (cont_alto< N) 
                    cont_alto <= cont_alto + 1;
                    // Si ya alcanzó N, mantiene el valor
            end else begin
                // Si la condición deja de cumplirse, resetea el contador
                cont_alto <= 3'd0;
            end
        end         
    end
    // Lógica combinacional: generación de señales de persistencia
    //La señal solo estará activa cuando AMBAS condiciones sean verdaderas.
    assign per_bajo= (cont_bajo >= N-1) && es_bajo;
    assign per_alto= (cont_alto >= N-1) && es_alto;

endmodule