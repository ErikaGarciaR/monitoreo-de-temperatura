`timescale 1ns / 1ps

module estado_temp(
    input logic clk,                           // reloj del sistema
    input logic arst_n,                        // reset asincrono
    input logic signed [10:0] temp_registrado, // temperatura 
    input logic [2:0] contador_fuera_rango,    // persistencia de la temperatura
    output logic alerta,                       // señalización de  alerta
    output logic calefactor,                   // Señal para calefactor
    output logic ventilador,                   // Señal para ventilador
    output logic [1:0] estado_actual           // estado FSM: NORMAL,FRIO, ALTO, ALERTA
);

    // Parámetros de temperatura escalada
    parameter TEMP_BAJO = 180; //la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 250; //la temperatura como limite maximo para alto
    parameter N = 5;           //ciclos de persistencia para activar alerta

    // estado para FSM
    typedef enum logic [1:0] {NORMAL=2'b00, BAJO=2'b01, ALTO=2'b10, ALERTA=2'b11} estado_temp;
    estado_temp estado;

    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            estado <= NORMAL;    // Para iniciar en la maquina de estado
            alerta <= 0;         // se inicia alerta en bajo
            calefactor <= 0;     // calefactor en bajo
            ventilador <= 0;     // ventilador en bajo
        end else begin
            case (estado)
                NORMAL: begin
                    alerta <= 0;
                    calefactor <= 0;     // calefactor en bajo
                    ventilador <= 0;     // ventilador en bajo
                    if (temp_registrado < TEMP_BAJO) estado <= BAJO;
                    else if (temp_registrado > TEMP_ALTO) estado <= ALTO;
                end
                BAJO: begin
                    if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) estado <= NORMAL;
                    else if (contador_fuera_rango >= N) estado <= ALERTA;
                end
                ALTO: begin
                    if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) estado <= NORMAL;
                    else if (contador_fuera_rango >= N) estado <= ALERTA;
                end
                ALERTA: begin
                    alerta <= 1; // persiste hasta que se normalice 
                    if (temp_registrado < TEMP_BAJO) begin           // temperatura registrada en bajo
                        calefactor <= 1;                             // calefactor se enciende 
                        ventilador <= 0;                             // ventilador apagao
                    end else if (temp_registrado > TEMP_ALTO) begin  // temperatura registrada en alto
                        ventilador <= 1;                             // ventilador en alto
                        calefactor <= 0;                             // calefactor en bajo
                    end
                    if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO)  // retorno a estado normal
                        estado <= NORMAL;
                end
                default: begin      // estado por defecto
                    estado<=NORMAL;
                    alerta<=0;
                end
            endcase
        end
    end

    assign estado_actual = estado; // verificacion del estado actual

endmodule