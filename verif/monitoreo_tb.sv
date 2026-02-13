//`define T_NORMAL_B
//`define T_BAJO_INM
//`define T_ALTO_INM
`define T_BAJO_PERS
//`define T_ALTO_PERS
//`define T_RECU_AUTO
`timescale 1ns / 1ps
import monitoreo_pkg::*;

module monitoreo_tb();
    bit clk;
    bit arst_n;
    always #5 clk = ~clk;

    // Instancia de la interfaz
    interface_monitoreo intf(clk, arst_n);

    // Instancia del dut
    monitoreo_top dut (
        .clk(intf.clk),
        .arst_n(intf.arst_n),
        .temp_entrada(intf.temp_entrada),
        .alerta(intf.alerta),
        .calefactor(intf.calefactor),
        .ventilador(intf.ventilador),
        .estado_actual(intf.estado_actual)
    );

    // instanciar objetos de la clase
    temp_bajo           t_frio;
    temp_alto           t_calor;
    temp_normal         t_normal;
    temp_persistente    t_pers;

    initial begin
        // inicializacion
        t_frio = new();
        t_calor =new();
        t_normal = new();
        t_pers = new(150);

        $display("--- Iniciando simulacion ---");
        ejecutar_reset();
//.............................Casos operacion basica.............................
        `ifdef T_NORMAL_B
            test_normal();
        `endif
        `ifdef T_BAJO_INM
            test_bajo ();
        `endif
        `ifdef T_ALTO_INM
            test_alto ();
        `endif
//.............................Casos operacion persistente.............................
        `ifdef T_BAJO_PERS
            test_persistencia_bajo();
        `endif

        `ifdef T_ALTO_PERS
            test_persistencia_alto();
        `endif

//.............................Casos recuperacion.....................................
        `ifdef T_RECU_AUTO
            test_recuperacion ();
        `endif



        repeat(5) @(posedge clk);
        
        $display("--- Simulación terminada ---");
        $finish;
    end


// casos de prueba 
//================================================================================
    task ejecutar_reset();
        arst_n = 0;
        intf.aplicar_reset();          
        #20 arst_n = 1;
        $display("[TB] Reset completado exitosamente");

    endtask

//.............................Casos operacion basica.............................
    task test_normal ();
        $display("[TEST CASE] T_NORMAL_B");
        repeat(4) begin
            if(!t_normal.randomize()) $fatal("Randomize failed");
            t_normal.reportar();
            intf.enviar_temperatura(t_normal.valor); // Usa Task de Interfaz
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask

    task test_bajo ();
        $display("[TEST CASE] T_BAJO_INM");
        repeat(4) begin
            if(!t_frio.randomize()) $fatal("Randomize failed");
            t_frio.reportar();
            intf.enviar_temperatura(t_frio.valor); // Usa Task de Interfaz
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask

    task test_alto ();
        $display("[TEST CASE] T_ALTO_INM");
        repeat(4) begin
            if(!t_calor.randomize()) $fatal("Randomize failed");
            t_calor.reportar();
            intf.enviar_temperatura(t_calor.valor); // Usa Task de Interfaz
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask
//.............................Casos operacion persistente.............................
    task test_persistencia_bajo();
        $display("\n[TEST CASE] T_BAJO_PERS - Verificando alerta tras 5 ciclos...");
        if(!t_frio.randomize()) $fatal("No se pudo generar valor de frio inicial");
        t_pers = new(t_frio.valor); // Forzamos inicio en zona de frío
        repeat(6) begin
            if(!t_pers.randomize()with { valor < 180; }) $fatal("Randomize failed");
            t_pers.reportar();
            intf.enviar_temperatura(t_pers.valor);
            intf.reporte_estado();
        end
    endtask

    task test_persistencia_alto();
        $display("\n[TEST CASE] T_ALTO_PERS - Verificando alerta tras 5 ciclos...");
        if(!t_calor.randomize()) $fatal("No se pudo generar valor de calor inicial");

        t_pers = new(t_calor.valor); // Forzamos inicio en zona de calor
        repeat(6) begin
            if(!t_pers.randomize() with { valor > 259; }) $fatal("Randomize failed");
            t_pers.reportar();
            intf.enviar_temperatura(t_pers.valor);
            intf.reporte_estado();
        end
    endtask
//.............................Casos recuperacion.....................................
    task test_recuperacion ();
            $display("\n[TEST CASE] T_RECU_AUTO - Forzando Alerta y luego Recuperación");
            
            // 1. Forzando persistencia 
            t_pers = new(100); 
            repeat(6) begin
                void'(t_pers.randomize());
                intf.enviar_temperatura(t_pers.valor);
            end
            $display("[TB] Sistema debería estar en ALERTA ahora. Estado: %b", intf.estado_actual);

            // 2. probando la recuperacion
            $display("[TB] Enviando temperatura normal (22.0 C) para recuperar...");
            intf.enviar_temperatura(220);
            
            // procesando el cambio
            @(posedge clk); 
            #1; // Delta para el assign de la alerta
            
            if (intf.alerta == 0 && intf.estado_actual == 2'b00) begin
                $display("[PASSED] El sistema se normalizó correctamente.");
                $display("[STATUS] Alerta: %b | Cal: %b | Estado: %b", 
                         intf.alerta, intf.calefactor, intf.estado_actual);
            end else begin
                $display("[FAILED] El sistema NO se recuperó. Estado: %b, Alerta: %b", 
                         intf.estado_actual, intf.alerta);
            end
    endtask



//================================================================================



initial begin
    $shm_open("shm_db");
    $shm_probe("ASMTR");
end
endmodule


