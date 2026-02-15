package monitoreo_pkg;
    // Parámetros de límites de alerta
    parameter TEMP_BAJO = 180; 
    parameter TEMP_ALTO = 259; 

    // Límites  de operación del sensor
    parameter MIN_SENSOR = -400;
    parameter MAX_SENSOR = 850;

    // --- Clase padre
    class temp_base;
        rand logic signed [10:0] valor;

        // Rango del sensor
        constraint c_fisico { valor inside {[MIN_SENSOR: MAX_SENSOR ]}; }

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
        constraint c_rango { valor < TEMP_BAJO; }

        virtual function void reportar();
            $display("[ESTADO: FRIO] registrando temperatura baja: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass

    class temp_normal extends temp_base;
        constraint c_rango { valor inside {[TEMP_BAJO : TEMP_ALTO]}; }

        virtual function void reportar();
            $display("[ESTADO: NORMAL] registrando temperatura estable: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass

    class temp_alto extends temp_base;
        constraint c_rango { valor > TEMP_ALTO; }

        virtual function void reportar();
            $display("[ESTADO: ALTO] registrando temperatura alta: %0d.%0d C", valor/10, (valor < 0) ? -(valor%10) : (valor%10));
        endfunction

    endclass

    class temp_persistente extends temp_base;
        // Guarda el valor anterior 
        logic signed [10:0] ultimo_valor;
        //margen de transicion 
        int delta = 2;

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

endpackage : monitoreo_pkg