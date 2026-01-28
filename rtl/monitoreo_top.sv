`timescale 1ns / 1ps

module monitoreo_top(
    input  logic clk,                        // Reloj del sistema
    input  logic arst_n,                     // Reset asíncrono (activo en bajo)
    input  logic signed [10:0] temp_entrada, // Temperatura  del sensor
    output logic alerta,                     // Indica falla
    output logic calefactor,                 // Señal para activar el calefactor 
    output logic ventilador,                 // Señal para activar el ventilador
    output logic [1:0]estado_actual               // Estado del monitoreo
    
 );
    logic signed [10:0] temp_registrada_int;  // Variables internas
    logic [2:0]         contador_int;         // contador interno
    logic               fuera_rango_int;      // variable que almacena 1 o 0 si se da la condicion de fuera de rango

    // Se instancia los modulos 
   // Compara la temperatura registrada contra los límites
    comparador_temp compara1 (
        .temp_reg            (temp_registrada_int),
        .fuera_rango         (fuera_rango_int)
    );

    // Almacena la temperatura y el contador de persistencia
    registro_temp registro1(
        .clk                 (clk),
        .arst_n              (arst_n),
        .temp_entrada        (temp_entrada),
        .fuera_rango         (fuera_rango_int),
        .temp_registrado     (temp_registrada_int),
        .contador_fuera_rango(contador_int)
    );




    // Decide el estado y activa los actuadores si persiste mas 5 ciclos de reloj el rango de temperatura 
    estado_temp fsm1 (
        .clk                 (clk),
        .arst_n              (arst_n),
        .temp_registrado     (temp_registrada_int),
        .contador_fuera_rango(contador_int),
        .alerta              (alerta),
        .calefactor          (calefactor),
        .ventilador          (ventilador),
        .estado_actual       (estado_actual)
    );

  
    
endmodule
