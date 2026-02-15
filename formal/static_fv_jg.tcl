# 1. Limpiar el entorno
clear -all

# 2. Configuración  (Local)
set_proofgrid_bridge off

# 3. Analizar los archivos del proyecto

analyze -sv12 ../verif/monitoreo_pkg.sv
analyze -sv12 ../fv/property_defines.svh
analyze -sv12 ../rtl/comparador_temp.sv
analyze -sv12 ../rtl/persistencia_ctr.sv
analyze -sv12 ../rtl/estado_temp.sv
analyze -sv12 ../rtl/monitoreo_top.sv
analyze -sv12 ../fv/fv_monitoreo.sv

# 4. Elaborar el diseño
elaborate -top monitoreo_top

# 5. Configurar Reloj y Reset

clock clk
reset -expression !arst_n

# 6. Configuración del motor de prueba
set_engineJ_max_trace_length 2000
