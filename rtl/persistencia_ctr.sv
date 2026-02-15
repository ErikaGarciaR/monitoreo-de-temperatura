`timescale 1ns / 1ps

module persistencia_ctr #(parameter N = 5)(
    input  logic clk,
    input  logic arst_n,
    input  logic fuera_rango,
    output logic [2:0] contador,
    output logic persistencia
);
    
    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            contador <= 3'd0;
        end else if (fuera_rango) begin
            
            if (contador < N) 
                contador <= contador + 1;
        end else begin
            contador <= 3'd0;
        end
    end

    assign persistencia= (contador >= N-1) && fuera_rango;

endmodule