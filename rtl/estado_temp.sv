`timescale 1ns / 1ps

module estado_temp(
    input logic clk,                           // reloj del sistema
    input logic arst_n,                        // reset asincrono
    input logic signed [10:0] temp_registrado, // temperatura 
    input logic per_bajo,                      // Persistencia de frío (del contador)
    input logic per_alto,                      // Persistencia de calor (del contador)
    output logic alerta,                       // señalización de  alerta
    output logic calefactor,                   // Señal para calefactor
    output logic ventilador,                   // Señal para ventilador
    output logic [1:0] estado_actual           // estado FSM: NORMAL,FRIO, ALTO, ALERTA
);

    // Parámetros de temperatura escalada
    parameter TEMP_BAJO = 180; //la temperatura como limite maximo para frio
    parameter TEMP_ALTO = 259; //la temperatura como limite maximo para alto

    // Codificación binaria de 2 bits para 4 estados
    // NORMAL: 00 - Temperatura en rango óptimo
    // BAJO:   01 - Temperatura inferior a TEMP_BAJO (pre-alerta)
    // ALTO:   10 - Temperatura superior a TEMP_ALTO (pre-alerta)
    // ALERTA: 11 - Condición persistente alcanzada
    typedef enum logic [1:0] {NORMAL=2'b00, BAJO=2'b01, ALTO=2'b10, ALERTA=2'b11} estado_t;
    estado_t estado; // Estado actual de la FSM
    // La FSM se actualiza en cada flanco positivo de reloj
    // Reset asíncrono: fuerza el estado a NORMAL inmediatamente
    always_ff @(posedge clk, negedge arst_n) begin
        if (!arst_n) begin
            estado      <= NORMAL;    // Reset: sistema comienza en estado NORMAL
        end else begin
            // Transiciones según estado actual
            case (estado)
                NORMAL: begin
                    if (temp_registrado < TEMP_BAJO) estado <= BAJO;   // Detección de frío
                    else if (temp_registrado > TEMP_ALTO) estado <= ALTO;// Detección de calor
                    // Si temperatura normal, permanece en NORMAL
                end
                BAJO: begin // Estado BAJO: pre-alerta de frío
                    if (per_bajo) begin   // Persistencia alcanzada: transición a ALERTA
                        estado <= ALERTA;
                    end else if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin
                        // Recuperación: temperatura vuelve a normal
                        estado <= NORMAL;                         
                    end else if (temp_registrado > TEMP_ALTO) begin
                        // Cambio directo de frío a calor
                        estado <= ALTO;
                    end 
                    // Si sigue en frío sin persistencia, permanece en BAJO
                end
                ALTO: begin   // Estado ALTO: pre-alerta de calor
                    if (per_alto)begin
                        // Persistencia alcanzada: transición a ALERTA
                        estado <= ALERTA;

                    end else if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin
                         // Recuperación: temperatura vuelve a normal
                        estado <= NORMAL;
                    end else if (temp_registrado < TEMP_BAJO) begin
                        // Cambio directo de calor a frío
                        estado <= BAJO;
                    end 
                    // Si sigue en calor sin persistencia, permanece en ALTO
                end
                ALERTA: begin // Estado ALERTA: condición crítica
                    if (temp_registrado >= TEMP_BAJO && temp_registrado <= TEMP_ALTO) begin 
                        // Recuperación: temperatura vuelve a normal
                        estado <= NORMAL;
                    end else if (temp_registrado < TEMP_BAJO && !per_bajo) begin
                        // La temperatura sigue baja pero perdió persistencia
                        estado <= BAJO;  
                    end else if (temp_registrado > TEMP_ALTO && !per_alto) begin
                        // La temperatura sigue alta pero perdió persistencia
                        estado <= ALTO;   
                    end 
                    // Si sigue con persistencia, permanece en ALERTA                  
                end
                default: begin      // estado por defecto
                    estado <= NORMAL;
                end
            endcase
            
        end
    end
   
    // Lógica de salida (combinacional)
    // Las salidas se generan combinacionalmente para respuesta inmediata
    // Los actuadores SOLO se activan en estado ALERTA
    always_comb begin
        // Valores por defecto (actuadores apagados)
        calefactor = 1'b0;
        ventilador = 1'b0;
        // En estado ALERTA, activa actuador según temperatura
        case (estado)
            ALERTA: begin
                if (temp_registrado < TEMP_BAJO)
                    calefactor = 1'b1;    // Persistencia de frío

                else if (temp_registrado > TEMP_ALTO)
                    ventilador = 1'b1;    // Persistencia de calor
            end
            default: begin // En cualquier otro estado, actuadores apagados
            calefactor = 1'b0;
            ventilador = 1'b0;
            end
        endcase
    end
    assign alerta = (estado == ALERTA); // alerta activa solo en estado ALERTA
    assign estado_actual = estado;      // verificacion del estado actual

endmodule