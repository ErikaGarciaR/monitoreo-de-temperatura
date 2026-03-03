src      = top_wishbone
tb       = monitoreo_wishbone_tb
testname = test
logs     = ./logs
verbosity=UVM_MEDIUM
.DEFAULT_GOAL := help

list: # target
	echo # rtl > list.f
	IF EXIST ../rtl/${src}.sv echo ..\rtl\${src}.sv >> list.f
	echo # verification >> list.f
	echo ../verif/${tb}.sv >> list.f
	
ana:
	xvlog -i ../../fv -sv -f list.f -L uvm
elab: ana
	xelab -timescale 1ns/1ps -debug typical --relax ${tb}
sim: elab
	xsim work.${tb} -runall

waves:
	xsim work.${tb}.wdb -autoloadwcfg -gui &

sim_gui: elab
	xsim work.${tb} -gui
cov: 
	xcrg -report_format html -dir xsim.covdb
sim_uvm: elab
	xsim work.${tb} "UVM_TESTNAME=${testname}"

sim_uvm_gui: elab
	xsim work.${tb} -gui "UVM_TESTNAME=${testname}"
help:
	@echo ""
	@echo "==== Basic Vivado Compile/Simulator makefile ======"
	@echo " Targets:"
	@echo " ana    --> Analyzes the HDL file with xvlog command"
	@echo " elab   --> Elaborates de design with xelab command"
	@echo " sim    --> Simulates the design with xsim command"
	@echo " clean  --> Clean support files"
	@echo " help   --> this help menu =)"
	@echo ""
clean:
	rm -rf xvlog* xelab* ana elab sim

	rm -f xsim.log xsim.jou xsim_*.backup.log xsim_*.backup.jou

	rm -rf xsim.covdb tr_db* webtalk*

	rm -rf xsim.dir .Xil vivado*

	rm -f work.*.wdb

	[ ! -d work ] || rm -rf work