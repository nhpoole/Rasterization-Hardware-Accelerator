################################################################################
################ Makefile Definitions
################################################################################
# This little trick finds where the makefile exists
DESIGN_HOME := $(realpath $(dir $(word $(words $(MAKEFILE_LIST)), $(MAKEFILE_LIST))))
$(warning WARNING: RAST home set to $(DESIGN_HOME)) 

# RUNDIR is where we are actually running
RUNDIR := $(realpath ./)
$(warning WARNING: RUNDIR set to $(RUNDIR)) 

# this line enables a local Makefile to override values of the main makefile
-include Makefile.local

########### Generic Env Defs ############
#########################################


ifndef DESIGN_NAME
  DESIGN_NAME:=rast
  $(warning WARNING: Running with default design.  DESIGN_NAME=$(DESIGN_NAME))
endif

ifeq ($(DESIGN_NAME), rast)
  SRC_DIR := $(DESIGN_HOME)
  INST_NAME ?= rast
  MOD_NAME ?=  rast
  TOP_NAME ?= top_rast
  GENESIS_SYNTH_TOP_PATH = $(TOP_NAME).$(INST_NAME)
endif

TOP_MODULE ?= $(TOP_NAME)

############# For Genesis2 ##############
#########################################

# list src folders and include folders
GENESIS_SRC := 	-srcpath ./			\
		-srcpath $(DESIGN_HOME)/rtl	\
		-srcpath $(DESIGN_HOME)/verif			

GENESIS_INC := 	-incpath ./			\
		-incpath $(DESIGN_HOME)/rtl	\
		-incpath $(DESIGN_HOME)/verif



# vpath directive tells where to search for *.vp and *.vph files
vpath 	%.vp  $(GENESIS_SRC)
vpath 	%.svp  $(GENESIS_SRC)
vpath 	%.vph $(GENESIS_INC)
vpath 	%.svph $(GENESIS_INC)
vpath	%.c	$(C_SRC)


GENESIS_ENV :=		$(wildcard $(DESIGN_HOME)/verif/*.vp) $(wildcard $(DESIGN_HOME)/verif/*.svp)
#GENESIS_ENV :=		$(DESIGN_HOME)/verif/top_rast.vp
GENESIS_ENV :=		$(notdir $(GENESIS_ENV)) 

GENESIS_DESIGN := 	$(wildcard $(DESIGN_HOME)/rtl/*.vp) $(wildcard $(DESIGN_HOME)/rtl/*.svp)
GENESIS_DESIGN := 	$(notdir $(GENESIS_DESIGN))

GENESIS_INPUTS :=	$(GENESIS_PRIMITIVES) $(GENESIS_ENV) $(GENESIS_DESIGN) 


# debug level
GENESIS_DBG_LEVEL := 0

# List of generated verilog files
GENESIS_VLOG_LIST := genesis_vlog.vf
GENESIS_SYNTH_LIST := $(GENESIS_VLOG_LIST:%.vf=%.synth.vf)
GENESIS_VERIF_LIST := $(GENESIS_VLOG_LIST:%.vf=%.verif.vf)

# xml hierarchy file
ifndef GENESIS_HIERARCHY
GENESIS_HIERARCHY := $(MOD_NAME).xml
else
  $(warning WARNING: GENESIS_HIERARCHY set to $(GENESIS_HIERARCHY))
endif
GENESIS_TMP_HIERARCHY := $(MOD_NAME)_target.xml
# For more Genesis parsing options, type 'Genesis2.pl -help'
#        [-parse]                    ---   should we parse input file to generate perl modules?
#        [-sources|srcpath dir]      ---   Where to find source files
#        [-includes|incpath dir]     ---   Where to find included files
#        [-input file1 .. filen]     ---   List of top level files
#                                    ---   The default is STDIN, but some functions
#                                    ---   (such as "for" or "while")
#                                    ---   may not work properly.
#        [-perl_modules modulename]  ---   Additional perl modules to load
GENESIS_PARSE_FLAGS := 	-parse $(GENESIS_SRC) $(GENESIS_INC)	-input $(GENESIS_INPUTS)		

# For more Genesis parsing options, type 'Genesis2.pl -help'
#        [-generate]                 ---   should we generate a verilog hierarchy?
#        [-top topmodule]            ---   Name of top module to start generation from
#        [-depend filename]          ---   Should Genesis2 generate a dependency file list? (list of input files)
#        [-product filename]         ---   Should Genesis2 generate a product file list? (list of output files)
#        [-hierarchy filename]       ---   Should Genesis2 generate a hierarchy representation tree?
#        [-xml filename]             ---   Input XML representation of definitions
GENESIS_GEN_FLAGS :=	-gen -top $(TOP_MODULE)					\
                        -synthtop $(GENESIS_SYNTH_TOP_PATH)                     \
			-depend depend.list					\
			-product $(GENESIS_VLOG_LIST)				\
			-hierarchy $(GENESIS_HIERARCHY)                		


# Input xml/cfg files, input parameters
GENESIS_CFG_XML	:= empty.xml
GENESIS_CFG_SCRIPT	:=
GENESIS_PARAMS	:=
ifneq ($(strip $(GENESIS_CFG_SCRIPT)),)
  GENESIS_GEN_FLAGS	:= $(GENESIS_GEN_FLAGS) -cfg $(GENESIS_CFG_SCRIPT)
  $(warning WARNING: GENESIS_CFG_SCRIPT set to $(GENESIS_CFG_SCRIPT))
endif
ifneq ($(strip $(GENESIS_CFG_XML)),)
  GENESIS_GEN_FLAGS	:= $(GENESIS_GEN_FLAGS) -xml $(GENESIS_CFG_XML)
  $(warning WARNING: GENESIS_CFG_XML set to $(GENESIS_CFG_XML))
endif
ifneq ($(strip $(GENESIS_PARAMS)),)
  GENESIS_GEN_FLAGS	:= $(GENESIS_GEN_FLAGS) -parameter $(GENESIS_PARAMS)
  $(warning WARNING: GENESIS_PARAMS set to $(GENESIS_PARAMS))
endif



############### For Verilog ################
############################################

##### FLAGS FOR SYNOPSYS COMPILATION ####
COMPILER := vcs

EXECUTABLE := $(RUNDIR)/simv

VERILOG_ENV :=		 

VERILOG_DESIGN :=	params/rast_params.sv \
rtl/bbox.sv \
rtl/dff2.sv \
rtl/dff3.sv \
rtl/dff.sv \
rtl/dff_retime.sv \
rtl/hash_jtree.sv \
rtl/rast.sv \
rtl/sampletest.sv \
rtl/test_iterator.sv \
rtl/tree_hash.sv \
rtl/DW_pl_reg.v \
verif/bbx_sb.sv \
verif/clocker.sv \
verif/perf_monitor.sv \
verif/rast_driver.sv \
verif/smpl_cnt_sb.sv \
verif/smpl_sb.sv \
verif/testbench.sv \
verif/top_rast.sv \
verif/zbuff.sv

VERILOG_FILES :=  	$(VERILOG_ENV) $(VERILOG_DESIGN)


VERILOG_LIBS := 	-y $(RUNDIR) +incdir+$(RUNDIR)			\
					-y /afs/ir.stanford.edu/class/ee/synopsys/syn/M-2016.12-SP2/dw/sim_ver/		\
					+incdir+/afs/ir.stanford.edu/class/ee/synopsys/syn/M-2016.12-SP2/dw/sim_ver/	 \
					-y $(SYNOPSYS)/packages/gtech/src_ver/	\
					+incdir+$(SYNOPSYS)/packages/gtech/src_ver/ \



# "-sverilog" enables system verilog
# "+lint=PCWM" enables linting error messages
# "+libext+.v" specifies that library files (imported by the "-y" directive) ends with ".v"
# "-notice" used to get details when ports are coerced to inout
# "-full64" for 64 bit compilation and simulation
# "+v2k" for verilog 2001 constructs such as generate
# "-timescale=1ns/1ns" sets the time unit and time precision for the entire design
# "+noportcoerce" compile-time option to shut off the port coercion for the entire design
# "-top topModuleName" specifies the top module
# "-f verilogFiles.list" specifies a file that contains list of verilog files to compile

# for C DPI function
$(DESIGN_HOME)/gold/zbuff.o: $(DESIGN_HOME)/gold/zbuff.c $(DESIGN_HOME)/gold/zbuff.h
	gcc $(C_INC_FLAG) $(C_COMP_FLAG) $(DESIGN_HOME)/gold/zbuff.c -o $(DESIGN_HOME)/gold/zbuff.o

$(DESIGN_HOME)/gold/rasterizer.o: $(DESIGN_HOME)/gold/rasterizer.c $(DESIGN_HOME)/gold/rasterizer.h
	gcc $(C_INC_FLAG) $(C_COMP_FLAG) $(DESIGN_HOME)/gold/rasterizer.c -o $(DESIGN_HOME)/gold/rasterizer.o

$(DESIGN_HOME)/gold/rasterizer_sv_interface.o: $(DESIGN_HOME)/gold/rasterizer_sv_interface.c $(DESIGN_HOME)/gold/rasterizer_sv_interface.h $(DESIGN_HOME)/gold/rasterizer.h
	gcc $(C_INC_FLAG) $(C_COMP_FLAG) $(DESIGN_HOME)/gold/rasterizer_sv_interface.c -o $(DESIGN_HOME)/gold/rasterizer_sv_interface.o

$(DESIGN_HOME)/gold/sv_gold.o: $(DESIGN_HOME)/gold/rasterizer_sv_interface.o $(DESIGN_HOME)/gold/rasterizer.o $(DESIGN_HOME)/gold/zbuff.o
	ld -relocatable $(DESIGN_HOME)/gold/rasterizer_sv_interface.o $(DESIGN_HOME)/gold/rasterizer.o $(DESIGN_HOME)/gold/zbuff.o -o $(DESIGN_HOME)/gold/sv_gold.o

C_OBJ := $(DESIGN_HOME)/gold/sv_gold.o

C_INC :=        $(DESIGN_HOME)/gold/rasterizer_sv_interface.h \
				$(DESIGN_HOME)/gold/rasterizer.h

C_INC_FLAG := 		-I$(DESIGN_HOME)/gold -I$(VCS_HOME)/include
C_COMP_FLAG :=		-c -lm -m64 -std=c99


VERILOG_COMPILE_FLAGS :=	-sverilog 					\
				+cli 						\
				-debug_access+all			\
				+lint=PCWM					\
				+libext+.v					\
				-notice						\
				-full64						\
				+v2k						\
				-debug_pp					\
				-timescale=1ns/1ns				\
				+noportcoerce         				\
				-ld $(VCS_CC) -debug_pp				\
				-top $(TOP_MODULE)				\
				-f rtl/vlog.vf					\
				-f verif/verif_vlog.vf               		\
				$(VERILOG_LIBS) $(C_OBJ)

#-f $(GENESIS_VLOG_LIST) 

# "+vpdbufsize+100" limit the internal buffer to 100MB (forces flushing to disk)
# "+vpdports" Record information about ports (signal/in/out)
# "+vpdfileswitchsize+1000" limits the wave file to 1G (then switch to next file)
VERILOG_SIMULATION_FLAGS := 	$(VERILOG_SIMULATION_FLAGS) 			\
				-l $(EXECUTABLE).log				\
		
##### END OF FLAGS FOR SYNOPSYS COMPILATION ####

############ For Verdi #####################
############################################
DEBUG_LIBRARY := work.lib++

$(DEBUG_LIBRARY): $(VERILOG_FILES)
	/cad/synopsys/verdi/L-2016.06-SP1-1/bin/vericom -sv -assert svaext -f rtl/vlog.vf -f verif/verif_vlog.vf $(VERILOG_LIBS)

############ For Design Compiler ###########
############################################
DESIGN_TARGET = rast

# The target clock period and area in library units (nS) (um^2). 45 
CLK_PERIOD=1.316;
TARGET_AREA=42000;


# flags for dc/icc
SYNTH_HOME	= $(DESIGN_HOME)/synth
SYNTH_RUNDIR	= $(RUNDIR)/synth
SYNTH_LOGS	= $(SYNTH_RUNDIR)
DC_LOG	= $(SYNTH_LOGS)/dc.log


SET_SYNTH_PARAMS = 	set DESIGN_HOME $(DESIGN_HOME); 	\
			set RUNDIR $(RUNDIR); 			\
			set DESIGN_TARGET $(DESIGN_TARGET); 	\
			set CLK_PERIOD  $(CLK_PERIOD); 				\
			set TARGET_AREA $(TARGET_AREA);	


DC_COMMAND_STRING = "$(SET_SYNTH_PARAMS) source -echo -verbose $(SYNTH_HOME)/rast_dc.tcl"


############ For CPP Gold Model ############
############################################



CPP_FLAGS = -Wall -g -lm -I$(DESIGN_HOME)/gold

GOLD_PROG = rasterizer_gold

CPP_SRC = $(DESIGN_HOME)/gold/rastTest.cpp \
	$(DESIGN_HOME)/gold/helper.cpp

CPP_INC = $(DESIGN_HOME)/gold/zbuff.h \
	$(DESIGN_HOME)/gold/helper.h \
	$(DESIGN_HOME)/gold/rast_types.h \
	$(DESIGN_HOME)/gold/rasterizer.h

CPP_OBJ = $(CPP_SRC:.cpp=.o)

################################################################################
################ Makefile Rules
################################################################################
#default rule: 
all: $(EXECUTABLE)

# Gold Model rules:
#####################
.PHONY: comp_gold clean_gold

comp_gold: $(GOLD_PROG)

$(GOLD_PROG): $(C_OBJ) $(CPP_OBJ)
	g++ $(CPP_FLAGS) $(CPP_OBJ) $(C_OBJ) -o $(GOLD_PROG)

clean_gold :
	@echo ""
	@echo Cleanning previous gold model compile
	@echo ========================================
	rm -f $(GOLD_PROG) $(CPP_OBJ)

# Genesis2 rules:
#####################
# This is the rule to activate Genesis2 generator to generate verilog 
# files (_unqN.v) from the genesis (.vp) program.
# Use "make GEN=<genesis2_gen_flags>" to add elaboration time flags
.PHONY: gen genesis_clean
gen: $(GENESIS_VLOG_LIST) $(GENESIS_SYNTH_LIST) $(GENESIS_VERIF_LIST)

$(GENESIS_VLOG_LIST) $(GENESIS_SYNTH_LIST) $(GENESIS_VERIF_LIST) : $(GENESIS_INPUTS) $(GENESIS_CFG_XML)
	@echo ""
	@echo Making $@ because of $?
	@echo ==================================================
	Genesis2.pl $(GENESIS_GEN_FLAGS) $(GEN) $(GENESIS_PARSE_FLAGS) -input $(GENESIS_INPUTS) -debug $(GENESIS_DBG_LEVEL)


genesis_clean:
	@echo ""
	@echo Cleanning previous runs of Genesis
	@echo ===================================
	if test -f "genesis_clean.cmd"; then	\
		./genesis_clean.cmd;	\
	fi
	\rm -rf $(GENESIS_VLOG_LIST) $(GENESIS_SYNTH_LIST) $(GENESIS_VERIF_LIST)



# VCS rules:
#####################
# compile rules:
# use "make COMP=+define+<compile_time_flag[=value]>" to add compile time flags
.PHONY: comp
comp: $(EXECUTABLE)

# $(C_OBJ): $(C_SRC) $(C_INC) 
# 	gcc $(C_INC_FLAG) $(C_COMP_FLAG) $(C_SRC) -o $(C_OBJ)

$(EXECUTABLE):	$(VERILOG_FILES) $(C_OBJ)
	@echo ""
	@echo Making $@ because of $?
	@echo ==================================================
	$(COMPILER)  $(VERILOG_COMPILE_FLAGS) $(COMP) 2>&1 | tee comp_bb.log 


# Simulation rules:
#####################
# use "make run RUN=+<runtime_flag[=value]>" to add runtime flags
.PHONY: run  run_wave 
run_wave: $(EXECUTABLE)
	@echo ""
	@echo Now Running $(EXECUTABLE) with wave
	@echo ==================================================
	mkdir -p sb_log mon_log
	$(EXECUTABLE) +wave $(VERILOG_SIMULATION_FLAGS) $(RUN) 2>&1 | tee run_bb.log 

run: $(EXECUTABLE)
	@echo ""
	@echo Now Running $(EXECUTABLE)
	@echo ==================================================
	mkdir -p sb_log mon_log
	$(EXECUTABLE) $(VERILOG_SIMULATION_FLAGS) $(RUN) 3>&1 | tee run_bb.log

debug:  $(EXECUTABLE)
	@echo ""
	@echo Opening debug view
	@echo ==================================================
	mkdir -p sb_log mon_log
	$(EXECUTABLE) $(VERILOG_SIMULATION_FLAGS) -gui &

debug_wave: $(EXECUTABLE)
	@echo ""
	@echo Opening waveform 
	@echo ==================================================
	dve -full64 -vpd wave.vpd &
	

# DC & ICC Run rules:
############################
# DC Run
#######################
.PHONY: run_dc clean_dc clean_reports

run_dc: $(DC_LOG)

$(DC_LOG): $(SYNTH_HOME)/rast_dc.tcl
#$(DC_LOG): $(GENESIS_SYNTH_LIST) $(SYNTH_HOME)/rast_dc.tcl
	@echo ""
	@echo Now Running DC SHELL: Making $@ because of $?
	@echo =============================================
	@sleep 1;
	@if test ! -d "$(SYNTH_LOGS)"; then 					\
		mkdir -p $(SYNTH_LOGS);						\
	fi
	cd $(SYNTH_RUNDIR); dc_shell-t -64bit -x $(DC_COMMAND_STRING) 2>&1 | tee -i $(DC_LOG)

clean_dc:
	@echo ""
	@echo Removing previous DC run log
	@echo =============================================
	\rm -f $(DC_LOG)

clean_reports:
	@echo ""
	@echo Removing previous DC reports
	@echo =============================================
	rm -fr $(SYNTH_RUNDIR)/reports
	rm -fr $(SYNTH_RUNDIR)/results.txt	
	cd $(SYNTH_RUNDIR); rm -fr alib-52 command.log default.svf netlist/
	cd $(SYNTH_RUNDIR); rm -fr cache/ db/ netlist/ RAST/ rast.mapped.ddc



# Cleanup rules:
#####################
.PHONY: clean cleanall 
clean: clean_dc clean_gold
	@echo ""
	@echo Cleanning old files, bineries and garbage
	@echo ==================================================
	\rm -f $(EXECUTABLE) 
	\rm -rf csrc
	\rm -rf *.daidir
	\rm -rf work.lib++
	\rm -rf ucli.key
	\rm -rf gold/*.o
	\rm -f *.tmp
	\rm -f *.h
	\rm -rf formal/*.btor2
	\rm -rf formal/rast.sv
	\rm -rf $(EXECUTABLE).*


cleanall: clean clean_reports
	@echo ""
	@echo Cleanning old logs, images and waveforms
	@echo ==================================================
	\rm -rf DVE*
	\rm -rf *.vpd
	\rm -rf wave.fsdb
	\rm -rf sb_log mon_log
	\rm -f *.log
	\rm -f *.ppm
