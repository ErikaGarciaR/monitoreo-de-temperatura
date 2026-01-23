testname = alfacen_noaxi_base_test
logs     = ./logs
defines  = XCELIUM
verb     = UVM_MEDIUM

compile_switches = -f list.f -l ${logs}/comp.log +define+${testname}+ -access +rwc -timescale 1ns/1ps -sv
compile_switches_uvm = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log +define+${testname}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} -access +rwc -timescale 1ns/1ps -sv
compile_switches_pa = -f list.f -uvmhome CDNS-1.2 -uvm -l ${logs}/comp.log +define+${defines}+ +UVM_TESTNAME=${testname} +UVM_VERBOSITY=${verb} -access +rwc -timescale 1ns/1ps -sv -define UPF -covoverwrite -lps_1801 ../power/chip_wrapper.upf -lps_dbc -lps_relax_1801 -lps_verbose 5 -lps_common_options

sim:
	xrun ${compile_switches}
	
sim_uvm:
	xrun ${compile_switches_uvm} -abvevalnochange 

sim_uvm_gui:
	xrun ${compile_switches_uvm} -gui

sim_cov:
	xrun $(compile_switches) -cov_cgsample -covoverwrite -coverage u -covtest $(testname)

cov_merge:
	imc -exec cov_merge.tcl

sim_uvm_cov:
	xrun ${compile_switches_uvm} -cov_cgsample
cov_gui:
	imc -load test

simvision:
	simvision shm_db

formal:
	jaspergold ../formal/static_fv_jg.tcl -acquire_proj -no_gui

formal_gui:
	jaspergold ../formal/static_fv_jg.tcl -acquire_proj

clean:
	rm -rf xrun* waves* xcelium* logs shm_db .sim* .svm* *.diag uvm_test_name.svh

sim_pa:
	echo "\`include \"../../verif/test/${testname}.svh\""  > uvm_test_name.svh
	xrun ${compile_switches_pa}
