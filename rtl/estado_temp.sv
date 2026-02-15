`timescale 1ns / 1ps

module estado_temp(
    input logic clk,                           // reloj del sistema
    input logic arst_n,                        // reset asincrono
    input logic signed [10:0] temp_registrado, // temperatura 
    input logic persistencia,
    output logic alerta,                       // señalización de  alerta
    output logic calefactor,                   // Señal para calefactor
    output logic ventilador,                   // Señal para ventilador
    output logic [1:0] estado_actual           // estado FSM: NORMAL,FRIO, ALTO, ALERTA
);

    // Parámetros de temperatura escalada
    parameter TEMP_BAJO = 180; //la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 259; //la temperatura como limite maximo para alto
    // estado para FSM
    typedef enum logic [1:0] {NORMAL=2'b00, BAJO=2'b01, ALTO=2'b10, ALERTA=2'b11} estado_t;
    estado_t estado;

    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            estado      <= NORMAL;    // Para iniciar en la maquina de estado
        end else begin
            case (estado)
                NORMAL: begin
                    if (temp_registrado < TEMP_BAJO) estado <= BAJO;
                    else if (temp_registrado > TEMP_ALTO) estado <= ALTO;
                end
                BAJO: begin
                    if (persistencia) begin
                        estado <= ALERTA;
                    end else if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin
                        estado <= NORMAL;                         
                    end else if (temp_registrado > TEMP_ALTO) begin
                        estado <= ALTO;
                    end 
                end
                ALTO: begin
                    if (persistencia)begin
                        estado <= ALERTA;

                    end else if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin
                        estado <= NORMAL;
                    end else if (temp_registrado < TEMP_BAJO) begin
                        estado <= BAJO;
                    end 
                end
                ALERTA: begin
                    if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin // retorno a estado normal
                        estado <= NORMAL;
                    end                   
                end
                default: begin      // estado por defecto
                    estado <= NORMAL;
                end
            endcase
            
        end
    end
   

    always_comb begin
        calefactor = 1'b0;
        ventilador = 1'b0;
        
        case (estado)
            ALERTA: begin
                if (temp_registrado < TEMP_BAJO)
                    calefactor = 1'b1;
                else if (temp_registrado > TEMP_ALTO)
                    ventilador = 1'b1;
            end
            default: begin
            calefactor = 1'b0;
            ventilador = 1'b0;
            end
        endcase
    end
    assign alerta = (estado == ALERTA); // verificacion del alarma
    assign estado_actual = estado;      // verificacion del estado actual

endmodule