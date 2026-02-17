`timescale 1ns / 1ps

module monitoreo_top(
    input  logic clk,                        // Reloj del sistema
    input  logic arst_n,                     // Reset asíncrono (activo en bajo)
    input  logic signed [10:0] temp_entrada, // Temperatura  del sensor
    output logic alerta,                     // Indica falla
    output logic calefactor,                 // Señal para activar el calefactor 
    output logic ventilador,                 // Señal para activar el ventilador
    output logic [1:0]estado_actual,         // Estado del monitoreo
    output logic [2:0] cont_bajo,            // Contador para temperatura baja
    output logic [2:0] cont_alto             // Contador para temperatura alta

    
 );
    logic es_bajo_int, es_alto_int;           // 
    logic per_bajo_int, per_alto_int;         // 

    // Se instancia los modulos 
   // Compara la temperatura registrada contra los límites
    comparador_temp compara1 (
        .temp_entrada        (temp_entrada),
        .es_bajo             (es_bajo_int),
        .es_alto             (es_alto_int)
    );



    persistencia_ctr #(.N(5)) u_persistencia (
        .clk            (clk),
        .arst_n         (arst_n),
        .es_bajo        (es_bajo_int),
        .es_alto        (es_alto_int),
        .cont_bajo      (cont_bajo),
        .cont_alto      (cont_alto),
        .per_bajo       (per_bajo_int),
        .per_alto       (per_alto_int)
    );


    // Decide el estado y activa los actuadores si persiste mas 5 ciclos de reloj el rango de temperatura 
    estado_temp fsm1 (
        .clk                 (clk),
        .arst_n              (arst_n),
        .temp_registrado     (temp_entrada),
        .per_bajo            (per_bajo_int),                
        .per_alto            (per_alto_int),                 
        .alerta              (alerta),
        .calefactor          (calefactor),
        .ventilador          (ventilador),
        .estado_actual       (estado_actual)
    );

endmodule
