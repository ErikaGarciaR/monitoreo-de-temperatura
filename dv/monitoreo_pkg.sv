package monitoreo_pkg;
    // Parámetros de límites de alerta
    parameter TEMP_BAJO = 180;  // 18.0°C - Umbral para condición de frío
    parameter TEMP_ALTO = 259;  // 25.9°C - Umbral para condición de calor

    // Límites  de operación del sensor
    parameter MIN_SENSOR = -400;   // -40.0°C - Mínimo del sensor
    parameter MAX_SENSOR = 850;    // 85.0°C  - Máximo del sensor

    // --- Clase padre
    class temp_base;
        rand logic signed [10:0] valor;

        // Restricción: valores dentro del rango físico del sensor
        constraint c_fisico { valor inside {[MIN_SENSOR: MAX_SENSOR ]}; }
        // Constructor: inicializa valor a 0
        function new();
            this.valor = 0;
        endfunction

        // Visualizacion de dato en consola
        virtual function void reportar();
            $display("[monitoreo_pkg] Temperatura Generada: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction
    endclass

    // --- Clases Hijas

    class temp_bajo extends temp_base;
        // Restricción: valores estrictamente menores a TEMP_BAJO
        constraint c_rango { valor < TEMP_BAJO; }

        virtual function void reportar();
            $display("[ESTADO: FRIO] registrando temperatura baja: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass

    class temp_normal extends temp_base;
        // Restricción: valores dentro del rango normal
        constraint c_rango { valor inside {[TEMP_BAJO : TEMP_ALTO]}; }

        virtual function void reportar();
            $display("[ESTADO: NORMAL] registrando temperatura estable: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass

    class temp_alto extends temp_base;
        // Restricción: valores estrictamente mayores a TEMP_ALTO
        constraint c_rango { valor > TEMP_ALTO; }

        virtual function void reportar();
            $display("[ESTADO: ALTO] registrando temperatura alta: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass
//Simula oscilaciones de temperatura alrededor de un valor inicial
    class temp_persistente extends temp_base;
        // Guarda el valor anterior 
        logic signed [10:0] ultimo_valor;
        // Margen de oscilación (por defecto ±2)
        int delta = 2;
         // Restricción: el nuevo valor debe estar cerca del anterior
        constraint c_cercania { valor inside {[ultimo_valor - delta : ultimo_valor + delta]}; }

        function new(logic signed [10:0] inicio = 250);
            super.new();
            this.ultimo_valor = inicio;
            this.valor = inicio;
        endfunction

        function void post_randomize();
            this.ultimo_valor = this.valor;
        endfunction

        virtual function void reportar();
            $display("[ESTADO: PERSISTENTE] registrando temperatura persistente: %0d.%0d C", valor/10, valor%10);
        endfunction
    endclass
// Restricción: valores fuera del rango del sensor
    class temp_fuera_rango extends temp_base;
        constraint c_fisico { valor inside {[-1024 : -401], [851   : 1023]};}

        function new();
            super.new();
        endfunction


        virtual function void reportar();
            $display("[SENSADO EXTREMO] Valor fuera de rango detectado: %0d", valor);
        endfunction
    endclass

endpackage : monitoreo_pkg