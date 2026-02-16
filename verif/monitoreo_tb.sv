//`define T_NORMAL_B
//`define T_BAJO_INM
//`define T_ALTO_INM
//`define T_NORMAL_PERS
`define T_BAJO_PERS
//`define T_ALTO_PERS
//`define T_TRANS_ALTO
//`define T_TRANS_BAJO
//`define T_LIM_BAJO
//`define T_LIM_ALTO
//`define T_RECU_AUTO
`timescale 1ns / 1ps
import monitoreo_pkg::*;

module monitoreo_tb();
    bit clk;
    bit arst_n;
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
        .estado_actual(intf.estado_actual),
        .contador_salida(intf.contador_salida)
    );
    // Inicializacion de reloj
    initial clk = 0;
    always #5ns clk = ~clk;  // Periodo 10ns (100 MHz)

    initial begin
        arst_n = 0;           // Reset activo desde tiempo 0
        intf.temp_entrada = 220;
        #20ns;                // Espera 2 ciclos completos
        arst_n = 1;           // Libera reset
        $display("================================================================================================");
        $display("[TB] Reset liberado en tiempo %0t", $time);
    end

    // instanciar objetos de la clase
    temp_bajo           t_frio;
    temp_alto           t_calor;
    temp_normal         t_normal;
    temp_persistente    t_pers;

    initial begin

        wait(arst_n == 1'b1);
        @(posedge clk);

        // inicializacion
        t_frio = new();
        t_calor =new();
        t_normal = new();
        t_pers = new(150);

        $display("--- Iniciando simulacion ---");
        //ejecutar_reset();
//.............................Casos operacion basica.............................
        `ifdef T_NORMAL_B
            repeat(10000)begin
            test_normal();
            end
        `endif
        `ifdef T_BAJO_INM
            repeat(10000)begin
            test_bajo ();
            end
        `endif
        `ifdef T_ALTO_INM
            test_alto ();
        `endif
//.............................Casos operacion persistente.............................
       `ifdef T_NORMAL_PERS
            repeat(10000)begin
                test_persistencia_normal();
            end
        `endif

        `ifdef T_BAJO_PERS
            repeat(10000) begin
            test_persistencia_bajo();
            end
        `endif

        `ifdef T_ALTO_PERS
            repeat(10000) begin
            test_persistencia_alto();
            end
        `endif

//.............................Casos recuperacion.....................................
        `ifdef T_RECU_AUTO
            repeat(10000)begin
            test_recuperacion_bajo ();
            end
        `endif

//.............................Casos transitorios.....................................
        `ifdef T_TRANS_ALTO
            repeat(10000)begin
            test_transitorio_alto();
            end
        `endif

        `ifdef T_TRANS_BAJO
            repeat(10000)begin
            test_transitorio_bajo();
            end
        `endif
//.............................Casos de limites.....................................
        `ifdef T_LIM_BAJO
            repeat(10000)begin
            test_limite_bajo();
            end
        `endif

        `ifdef T_LIM_ALTO
            repeat(10000)begin
            test_limite_alto();
            end
        `endif
        
        repeat(5) @(posedge clk);
        
        $display("--- Simulación terminada ---");
        $finish;
    end


// casos de prueba 
//================================================================================
    /*task ejecutar_reset();
        $display("[TB] Aplicando reset...");
        
        // 1. Activar reset (inmediato)
        arst_n = 0;
        intf.temp_entrada = 220;  // Valor por defecto
        @(posedge clk);
        // 2. Verificar que el reset fue inmediato
        if (intf.estado_actual !== 2'b00)
            $error("[TB] Reset no fue inmediato");
        
        // 3. Mantener reset
        repeat(1) @(posedge clk);
        
        // 4. Liberar reset en flanco de bajada
        @(negedge clk);
        arst_n = 1;
        
        // 5. Esperar 1 ciclo y reportar
        @(posedge clk);
        intf.reporte_estado();
        $display("[TB] Reset completado");

    endtask*/

//.............................Casos operacion basica.............................
    task test_normal ();
        $display("[TEST CASE] T_NORMAL_B");
        repeat(4) begin
            if(!t_normal.randomize()) $fatal("Randomize failed");
            t_normal.reportar();
            intf.enviar_temperatura(t_normal.valor); // Usa Task de Interfaz
            intf.reporte_estado();
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask

    task test_bajo ();
        $display("[TEST CASE] T_BAJO_INM");
        repeat(4) begin
            if(!t_frio.randomize()) $fatal("Randomize failed");
            t_frio.reportar();
            intf.enviar_temperatura(t_frio.valor); // Usa Task de Interfaz
            intf.reporte_estado();
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask

    task test_alto ();
        $display("[TEST CASE] T_ALTO_INM");
        repeat(4) begin
            if(!t_calor.randomize()) $fatal("Randomize failed");
            t_calor.reportar();
            intf.enviar_temperatura(t_calor.valor); // Usa Task de Interfaz
            intf.reporte_estado();
            $display("--- Dato ingresado al DUT exitosamente ---");
            end
    endtask
//.............................Casos operacion persistente.............................
    task test_persistencia_normal();
        $display("\n[TEST CASE] T_NORMAL_PERS - Verificando alerta tras 6 ciclos...");
        if(!t_normal.randomize()) $fatal("No se pudo generar valor de frio inicial");
        t_pers = new(t_normal.valor); // Forzamos inicio en zona rango normal
        repeat(6) begin
            if(!t_pers.randomize()with { valor inside {[180 : 259]}; }) $fatal("Randomize failed");
            t_pers.reportar();
            intf.enviar_temperatura(t_pers.valor);
            intf.reporte_estado();
        end
    endtask

    task test_persistencia_bajo();
        $display("\n[TEST CASE] T_BAJO_PERS - Verificando alerta tras 6 ciclos...");
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
        $display("\n[TEST CASE] T_ALTO_PERS - Verificando alerta tras 6 ciclos...");
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
    task test_recuperacion_bajo ();
            $display("\n[TEST CASE] T_RECU_AUTO - Forzando Alerta y luego Recuperación");
            // 1. Forzando persistencia 
            if(!t_frio.randomize()) $fatal("No se pudo generar valor de frio inicial");
            t_pers = new(t_frio.valor); // Forzamos inicio en zona de frío
            repeat(5) begin
                void'(t_pers.randomize());
                intf.enviar_temperatura(t_pers.valor);
                intf.reporte_estado();
            end
            @(posedge clk);

            intf.reporte_estado();
            if (intf.estado_actual !== 2'b11) begin
                $error("[FAIL] No se alcanzó ALERTA");
                intf.reporte_estado();
                return;
            end

            // 2. probando la recuperacion a normal
            $display("[TB] Enviando temperatura normal  para recuperar...");
            if(!t_normal.randomize()) $fatal("No se pudo generar valor de frio inicial");
            intf.enviar_temperatura(t_normal.valor);
             @(posedge clk); 
            // procesando el cambio
            intf.reporte_estado();
            if (intf.alerta == 0 && intf.estado_actual == 2'b00) begin
                $display("[TB] El sistema se normalizó correctamente.");
                intf.reporte_estado();
            end else begin
                $display("[TB] El sistema NO se recuperó. Estado: %b, Alerta: %b", 
                         intf.estado_actual, intf.alerta);
            end
    endtask
//.............................Casos transitorio.....................................
    task test_transitorio_alto();
        $display("\n[TEST CASE] T_TRANS_ALTO - Calor transitorio (< N ciclos)");
        // 1. Forzando persistencia 
        if(!t_calor.randomize()) $fatal("No se pudo generar valor de frio inicial");
            t_pers = new(t_calor.valor); // Forzamos inicio en zona de frío
            repeat(3) begin
            void'(t_pers.randomize());
            intf.enviar_temperatura(t_pers.valor);
            intf.reporte_estado();
        end
        @(posedge clk);
        // 2. Volvemos a temperatura NORMAL antes de que se cumpla la persistencia
        $display("[TB] Enviando temperatura normal  para recuperar...");
        if(!t_normal.randomize()) $fatal("No se pudo generar valor de frio inicial");
        intf.enviar_temperatura(t_normal.valor);
        @(posedge clk);
        
        // 3. Verificación final
        intf.reporte_estado();
        if (intf.alerta == 0 && intf.estado_actual == 2'b00) begin
            $display("[TB] El transitorio fue ignorado correctamente. Alerta: 0");
        end else begin
            $error("[TB] ¡La alerta se disparó o el estado no volvió a NORMAL!");
        end
    endtask

    task test_transitorio_bajo();
        $display("\n[TEST CASE] T_TRANS_BAJO - Frío transitorio (< N ciclos)");
        if(!t_frio.randomize()) $fatal("Randomize failed");
        t_pers = new(t_frio.valor);
        repeat(3) begin
            void'(t_pers.randomize());
            intf.enviar_temperatura(t_pers.valor);
            intf.reporte_estado();
        end
        @(posedge clk);
        
        $display("[TB] Volviendo a temperatura normal...");
        if(!t_normal.randomize()) $fatal("Randomize failed");
        intf.enviar_temperatura(t_normal.valor);
        @(posedge clk);
        
        intf.reporte_estado();
        if (intf.alerta == 0 && intf.estado_actual == 2'b00)
            $display("[TB] Transitorio ignorado correctamente");
        else
            $error("[TB] Transitorio activó alerta");
    endtask
//.............................Casos limite.....................................
    task test_limite_bajo();
        $display("\n Temperatura de un ciclo anterior: %0d",intf.temp_entrada);
        $display("\n[TEST CASE] T_LIM_BAJO - Límite exacto (179 a 180)");
        intf.enviar_temperatura(179);
        repeat(1) @(posedge clk);
        intf.reporte_estado();
        intf.enviar_temperatura(180);
        repeat(1) @(posedge clk);
        intf.reporte_estado();

        if (intf.estado_actual == 2'b00)
            $display("[TB] Transición 179→180 correcta");
        else
            $error("[TB] Estado después de 180 = %b", intf.estado_actual);
    endtask


    task test_limite_alto();
        $display("\n Temperatura de un ciclo anterior: %0d",intf.temp_entrada);
        $display("\n[TEST CASE] T_LIM_ALTO - Límite exacto (259 a 260)");
        intf.enviar_temperatura(259);
        repeat(1) @(posedge clk);
        intf.reporte_estado();
        intf.enviar_temperatura(260);
        repeat(1) @(posedge clk);
        intf.reporte_estado();

        if (intf.estado_actual == 2'b10)
            $display("[TB] Transición 259→260 correcta");
        else
            $error("[TB] Estado después de 260 = %b", intf.estado_actual);
    endtask
//================================================================================



    initial begin
        $shm_open("shm_db");
        $shm_probe("ASMTR");
    end


    /*bind monitoreo_top fv_monitoreo fv_mon_inst (.*);
    bind monitoreo_top cov_monitoreo cov_mon_inst (.*);*/
endmodule


