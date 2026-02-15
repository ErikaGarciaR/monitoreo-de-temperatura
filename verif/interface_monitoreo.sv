interface interface_monitoreo(input logic clk, input logic arst_n);
    logic signed [10:0] temp_entrada;
    logic alerta;
    logic calefactor; 
    logic ventilador;
    logic [1:0] estado_actual;
    logic [2:0] contador_salida;
    //

    //
    task automatic enviar_temperatura(input logic signed [10:0] valor);
        @(negedge clk);
        temp_entrada = valor;
        $display("[INTERFACE] Enviando T = %0d", valor);
        @(posedge clk);
    endtask
    //
    task automatic reporte_estado();
        $display("[INTERFACE]  %t | contador:%0d | Alerta: %b | Vent: %b | Cal: %b | Estado: %b", 
                 $time, contador_salida, alerta,ventilador, calefactor, estado_actual);
    endtask

endinterface
