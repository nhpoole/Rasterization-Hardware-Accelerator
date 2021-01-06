#!/bin/bash

# preserve order
cat rast_wrapper.sv ../params/rast_params.sv ../rtl/*.sv ./DW_pl_reg.v > rast.sv

# Modifications for VERIFIC
# Add //synopsys full_case directives at the end of unique case
sed -i '/unique case/ s/$/ \/\/ synopsys full_case/' rast.sv

# Convert enum to wire to resolve type error
echo "If enum to wire error, cast the state_t variable into a logic signal"
yosys -s gen-rast-btor.ys
./run_pono.sh rast.btor2 | tee pono_output.txt

