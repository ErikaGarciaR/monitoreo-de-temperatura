`timescale 1ns / 1ps


module monitoreo_tb();
    bit                 clk;            // Reloj del sistema
    bit                arst_n;          // Reset asíncrono (activo en bajo)
    logic signed [10:0] temp_entrada;   // Temperatura del sensor
    logic               alerta;         // Indica falla
    logic               calefactor;     // Señal para activar el calefactor 
    logic               ventilador;     // Señal para activar el ventilador
    logic [1:0]         estado_actual;  //Estado del monitoreo

    monitoreo_top prueba1 (
        .clk           (clk),
        .arst_n        (arst_n),
        .temp_entrada  (temp_entrada),
        .alerta        (alerta),
        .calefactor    (calefactor),
        .ventilador    (ventilador),
        .estado_actual (estado_actual)
    );

    always #5ns clk = !clk;    // duracion de cada ciclo de reloj
    assign #10ns arst_n= 1'b1; // el reset se libera a los 10 ns despues del inicio

 
    initial begin
        // Inicialización
        temp_entrada = 220;                   // 22.0°C (Normal)
        
        $display("--- Inicio de Simulación ---");

        // Temperatura Normal
        #50;
        $display("Tiempo %0t: Temp=%0d (Normal). Alerta=%b", $time, temp_entrada, alerta);

        // Frío Persistente 
        temp_entrada = 150; // 15.0°C
        $display("Tiempo %0t: Temp=%0d (Frio detectado). Esperando persistencia...", $time, temp_entrada);
        #100; // Esperamos más de 5 ciclos de reloj
        $display("Tiempo %0t: Alerta=%b, Calefactor=%b", $time, alerta, calefactor);

        // NORMAL
        temp_entrada = 200; // 20.0°C (Normal)
        #20;
        $display("Tiempo %0t: Temp=%0d (Normalizado). Alerta=%b, Calefactor=%b", $time, temp_entrada, alerta, calefactor);

        // (Transitorio)
        temp_entrada = 300; // 30.0°C
        #20;                // Solo 2 ciclos
        temp_entrada = 220; // Vuelve a normal antes de que el contador llegue a 5
        #20;
        $display("Tiempo %0t: Transitorio detectado. Alerta=%b (Debe ser 0)", $time, alerta);

        // Calor Persistente  Ventilador encendido
        temp_entrada = 350; // 35.0°C
        #100;
        $display("Tiempo %0t: Temp=%0d (Calor). Alerta=%b, Ventilador=%b", $time,temp_entrada, alerta, ventilador);

        #100;
        $display("--- Fin de Simulación ---");
        $finish;
    end


endmodule



