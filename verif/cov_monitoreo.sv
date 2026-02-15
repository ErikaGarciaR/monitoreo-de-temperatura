// cov_monitoreo.sv

//`include "property_defines.svh"
import monitoreo_pkg::*;
module cov_monitoreo (
    input logic clk,
    input logic arst_n,
    input logic signed [10:0] temp_entrada,
    input logic [1:0]  estado_actual,
    input logic [2:0]  contador_salida, 
    input logic alerta,
    input logic ventilador,
    input logic calefactor
);

    	// ==========================================================
    	// 1. COVERGROUP PRINCIPAL
    	// ==========================================================
    covergroup cg_monitoreo @(posedge clk);
        option.per_instance = 1;
        option.name = "Cobertura_Funcional_Monitoreo";
        option.comment = "Cobertura completa del sistema de temperatura";

        // ------------------------------------------------
        // Cobertura de Rangos de Temperatura
        // ------------------------------------------------
        cp_temp: coverpoint temp_entrada {
            bins min_sensor     	= { MIN_SENSOR };  					//-400  Valor mínimo
            bins rango_bajo			= { [MIN_SENSOR+1 : TEMP_BAJO-2] }; //-399:178 Frío (no crítico)
            bins limite_bajo    	= { TEMP_BAJO - 1 }; 				// 179 Frontera frío/normal
            bins limite_normal_inf 	= { TEMP_BAJO };     				// 180 Frontera normal
            bins rango_normal   	= { [TEMP_BAJO+1  : TEMP_ALTO-1] }; // 181:259 Normal (estable)
            bins limite_normal_sup 	= { TEMP_ALTO };     				// 259 Frontera normal
            bins limite_alto    	= { TEMP_ALTO + 1 }; 				// 260 Frontera normal/calor
            bins rango_alto     	= { [TEMP_ALTO+2  : MAX_SENSOR-1] };//261:849 Calor (no crítico)
            bins max_sensor    		= { MAX_SENSOR }; 					// 800 Valor máximo
        }

        // ------------------------------------------------
        // Cobertura de Estados de la FSM
        // ------------------------------------------------
        cp_estado: coverpoint estado_actual {
            bins NORMAL = {2'b00};
            bins BAJO   = {2'b01};
            bins ALTO   = {2'b10};
            bins ALERTA = {2'b11};
            illegal_bins otros = default;  
        }

        // ------------------------------------------------
        // Cobertura del Contador de Persistencia
        // ------------------------------------------------
        cp_contador: coverpoint contador_salida {
            bins cero    = {0};
            bins uno     = {1};
            bins dos     = {2};
            bins tres    = {3};
            bins cuatro  = {4};
            bins cinco   = {5};              
            bins otros   = {[6:7]};           
        }

        // ------------------------------------------------
        // Cobertura de Actuadores 
        // ------------------------------------------------
        cp_actuadores: coverpoint {calefactor, ventilador} {
            bins ambos_off = {2'b00};
            bins solo_calefactor = {2'b10};
            bins solo_ventilador = {2'b01};
            illegal_bins ambos_on = {2'b11};  // Error
        }

        // ------------------------------------------------
        // Cobertura de transiciones de la FSM
        // ------------------------------------------------
        cp_fsm_trans: coverpoint estado_actual {
            // Transiciones normales
            bins normal_a_bajo   = (2'b00 => 2'b01);  // NORMAL a BAJO
            bins normal_a_alto   = (2'b00 => 2'b10);  // NORMAL a ALTO
            bins bajo_a_normal   = (2'b01 => 2'b00);  // BAJO a NORMAL
            bins alto_a_normal   = (2'b10 => 2'b00);  // ALTO a NORMAL
            
            // Transiciones a ALERTA (casos críticos)
            bins bajo_a_alerta   = (2'b01 => 2'b11);  // BAJO a ALERTA (persistencia frío)
            bins alto_a_alerta   = (2'b10 => 2'b11);  // ALTO a ALERTA (persistencia calor)
            
            // Recuperación automática 
            bins recu_auto        = (2'b11 => 2'b00);  // ALERTA a NORMAL
            
            // Transitorios 
            bins transitorio_bajo = (2'b00 => 2'b01 => 2'b00);  // Ruido de frío
            bins transitorio_alto = (2'b00 => 2'b10 => 2'b00);  // Ruido de calor
        }

        // ------------------------------------------------
        // COMBINACIONES  
        // ------------------------------------------------
        
        // 1. Estado vs Temperatura 
        estado_x_temp: cross cp_estado, cp_temp {
            // Ignoramos combinaciones imposibles
            ignore_bins estado_alerta_con_normal = 
                binsof(cp_estado.ALERTA) && binsof(cp_temp.rango_normal);
        }
        
        // 2. Estado vs Contador 
        estado_x_cont: cross cp_estado, cp_contador {
    
            bins alerta_con_cinco = 
                binsof(cp_estado.ALERTA) && binsof(cp_contador.cinco);
            bins bajo_con_cinco = 
                binsof(cp_estado.BAJO) && binsof(cp_contador.cinco);  
        }
        
        // 3. Contador vs Temperatura 
        cont_x_temp: cross cp_contador, cp_temp;

    endgroup

    // ==========================================================
    // 2. INSTANCIACIÓN
    // ==========================================================
    cg_monitoreo cg_inst = new();

    // ==========================================================
    // 3. COVER PROPERTIES 
    // ==========================================================
    // Exclusión mutua - 
    `COV(mon, exclusion_mutua_visto, 1'b1 |->, (!(ventilador && calefactor)))

    // Alerta activada 
    `COV(mon, alerta_activada, 1'b1 |->, (alerta == 1))

    // Contador llegó a 5 
    `COV(mon, contador_cinco_alcanzado, 1'b1 |->, (contador_salida == 5))

    // Estado ALERTA alcanzado
    `COV(mon, estado_alerta_alcanzado, 1'b1 |->, (estado_actual == 2'b11))

    // ==========================================================
    // 4. REPORTE FINAL
    // ==========================================================
    final begin
        $display("\n=== REPORTE DE COBERTURA FUNCIONAL ===");
        $display("Cobertura de estados: %.1f%%", cg_inst.cp_estado.get_coverage());
        $display("Cobertura de temperatura: %.1f%%", cg_inst.cp_temp.get_coverage());
        $display("Cobertura de contador: %.1f%%", cg_inst.cp_contador.get_coverage());
        $display("Cobertura de actuadores: %.1f%%", cg_inst.cp_actuadores.get_coverage());
        $display("Cobertura de transiciones: %.1f%%", cg_inst.cp_fsm_trans.get_coverage());
        $display("Cobertura total: %.1f%%", cg_inst.get_coverage());
        $display("====================================\n");
    end

endmodule


bind monitoreo_top cov_monitoreo cov_mon_inst (.*);