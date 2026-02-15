`timescale 1ns / 1ps

module monitoreo_top(
    input  logic clk,                        // Reloj del sistema
    input  logic arst_n,                     // Reset asíncrono (activo en bajo)
    input  logic signed [10:0] temp_entrada, // Temperatura  del sensor
    output logic alerta,                     // Indica falla
    output logic calefactor,                 // Señal para activar el calefactor 
    output logic ventilador,                 // Señal para activar el ventilador
    output logic [1:0]estado_actual,          // Estado del monitoreo
    output logic [2:0]contador_salida

    
 );
    logic signed [10:0] temp_registrada_int;  // Variables internas
    logic               fuera_rango_int;      // variable que almacena 1 o 0 si se da la condicion de fuera de rango
    logic               persistencia_int;

    // Se instancia los modulos 
   // Compara la temperatura registrada contra los límites
    comparador_temp compara1 (
        .temp_entrada        (temp_entrada),
        .fuera_rango         (fuera_rango_int)
    );

    // Almacena la temperatura y el contador de persistencia
    /*registro_temp registro1(
        .clk                 (clk),
        .arst_n              (arst_n),
        .temp_entrada        (temp_entrada),
        .temp_registrado     (temp_registrada_int)
    );*/

    persistencia_ctr #(.N(5)) u_persistencia (
        .clk                (clk),
        .arst_n             (arst_n),
        .fuera_rango        (fuera_rango_int),
        .contador           (contador_salida),     // 
        .persistencia       (persistencia_int)  // 
    );


    // Decide el estado y activa los actuadores si persiste mas 5 ciclos de reloj el rango de temperatura 
    estado_temp fsm1 (
        .clk                 (clk),
        .arst_n              (arst_n),
        .temp_registrado     (temp_entrada),
        .persistencia        (persistencia_int),
        .alerta              (alerta),
        .calefactor          (calefactor),
        .ventilador          (ventilador),
        .estado_actual       (estado_actual)
    );

endmodule
