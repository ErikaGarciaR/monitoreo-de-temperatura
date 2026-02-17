interface interface_monitoreo(input logic clk, input logic arst_n);
    logic signed [10:0] temp_entrada;
    logic alerta;
    logic calefactor; 
    logic ventilador;
    logic [1:0] estado_actual;
    logic [2:0]  cont_alto;
    logic [2:0]  cont_bajo;
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
        $display("[INTERFACE]  %t | cont_bajo:%0d | cont_alto:%0d | Alerta: %b | Vent: %b | Cal: %b | Estado: %b", 
                 $time, cont_bajo,cont_alto, alerta,ventilador, calefactor, estado_actual);
    endtask

endinterface
