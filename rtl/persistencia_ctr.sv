`timescale 1ns / 1ps

module persistencia_ctr #(parameter N = 5)(
    input  logic clk,
    input  logic arst_n,
    input  logic es_bajo,       // temp < 180
    input  logic es_alto,       // temp > 259
    output logic [2:0] cont_bajo,
    output logic [2:0] cont_alto,
    output logic per_bajo,      // Persistencia de frío
    output logic per_alto       // Persistencia de calor
);
    
    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            cont_bajo <= 3'd0;
            cont_alto <= 3'd0;
        end else begin
            if (es_bajo) begin
                if (cont_bajo < N) 
                    cont_bajo <= cont_bajo + 1;
            end else begin
                cont_bajo <= 3'd0;
            end

            if (es_alto) begin
                if (cont_alto< N) 
                    cont_alto <= cont_alto + 1;
            end else begin
                cont_alto <= 3'd0;
            end
        end         
    end

    assign per_bajo= (cont_bajo >= N-1) && es_bajo;
    assign per_alto= (cont_alto >= N-1) && es_alto;

endmodule