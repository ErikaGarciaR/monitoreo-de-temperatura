interface interface_monitoreo(input logic clk, input logic arst_n);
    logic signed [10:0] temp_entrada;  // Temperatura de entrada al DUT (11 bits con signo)
    logic alerta;                      // Indicador de alerta (del DUT)
    logic calefactor;                  // Señal de control de calefacción (del DUT)
    logic ventilador;                  // Señal de control de ventilación (del DUT)
    logic [1:0] estado_actual;         // Estado actual de la FSM (del DUT) para debug
    logic [2:0]  cont_alto;            // Contador de persistencia de frío (del DUT)  para debug
    logic [2:0]  cont_bajo;            // Contador de persistencia de calor (del DUT)  para debug
    //

    //
    task automatic enviar_temperatura(input logic signed [10:0] valor);
        @(negedge clk);                                // Sincronizar con flanco de bajada
        temp_entrada = valor;                          // Asigna valor a la señal
        $display("[INTERFACE] Enviando T = %0d", valor);
        @(posedge clk);                                // Esperar al siguiente flanco de subida
    endtask
    //
    task automatic reporte_estado();          //Muestra en consola el estado completo del sistema,
        $display("[INTERFACE]  %t | cont_bajo:%0d | cont_alto:%0d | Alerta: %b | Vent: %b | Cal: %b | Estado: %b", 
                 $time, cont_bajo,cont_alto, alerta,ventilador, calefactor, estado_actual);
    endtask

endinterface
