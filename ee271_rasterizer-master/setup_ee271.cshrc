
################################################################################
## Setup file for the ee271 class of Fall 2012
## Created by Ofer Shacham, shacham@alumni.stanford.edu
################################################################################

# Load all modules related to ee271
#-------------------------------------------------
# Modules list:
# 	VCS: 2009.12
# 	DC: 2010.03
# 	Primetime: 2009.12.-SP2
# 	HSPICE: 2010.03
# 	IC compiler: 2010.03
# 
# optional:
# 	liberty-ncx - 2009.12-SP2
# 	hercules: 2008.09-SP1
# 
# Working with the module loader tool:
# 	Initialize:
# 		setenv MODULESHOME /usr/class/ee/modules/tcl
# 		source $MODULESHOME/init/csh.in
# 
# 	Help:
# 		module help
# 
# 	List of available modules:
# 		module avail
# 
# 	Load: 
# 		module load <name of tool>
# 
# 	Unload
# 		module unload <name of tool>
#
# * NOTE: the following lines would do all that for you.

echo "#################################################################"
echo "##                      Welcome to EE271                       ##"
echo "#################################################################"
echo " "
echo "Loading environment variables..."


mkdir -p ~/.modules   # this is just to fix a warning

#source /etc/csh/login.d/lmod.csh
source /afs/ir/class/ee/modules/init_modules.csh
module load base
module load genesis2
module load syn
module load vcs
# Loading Tool Env.
module load synopsys_edk #
module load cdesigner # Custom Designer
#module load cni # Pycell for layout Pcell ##### FIX ME! I crashes gcc
module load hercules # Hercules for DRC/LVS/LPE
module load starrc # Star-RCX for LPE
module load cx # Custom Explorer Waveform Viewer
module load synopsys_pdk # load env for synopsys 90nm PDK
module load matlab/caddy
module load incisive

### Queue If Licenses Are Unavailable
setenv SNPSLMD_QUEUE true
setenv SNPS_MAX_WAITTIME 7200
setenv SNPS_MAX_QUEUETIME 7200

### env for ee271 project
setenv EE271_PROJ /afs/ir/class/ee271/project
setenv EE271_VECT ${EE271_PROJ}/vect

### env for AHA tools
setenv PATH /usr/bin:/cad/aha/brew/bin:/cad/aha/bin:/cad/aha/verific/yosys:$PATH
source /cad/aha/venv/bin/activate.csh
setenv LD_LIBRARY_PATH /cad/aha/venv/lib:/cad/aha/venv/coreir/lib:$LD_LIBRARY_PATH

setenv VERIFIC_LICENSE_FILE /cad/aha/verific_200817.license

setenv VERDI_HOME /cad/synopsys/verdi/L-2016.06-SP1-1/

setenv MGLS_LICENSE_FILE 1717@cadlic0.stanford.edu
setenv PATH /cad/mentor/2019.11/Catapult_Synthesis_10.4b-841621/Mgc_home/bin/:$PATH

### some helpful alias to make your life better
alias dve 'dve -full64'

if ( -f /usr/bin/gcc-4.4 ) then
setenv J_CC gcc-4.4
else
setenv J_CC gcc
endif

if ( -f /hd/cad/modules/tcl/init/csh ) then
source /hd/cad/modules/tcl/init/csh
endif

echo "EE271 environment setup finished."

