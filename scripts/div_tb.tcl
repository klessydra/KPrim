#rm -rf prim_libs
mkdir -p prim_libs
vlib prim_libs/div_lib
vlog -sv tb/div_tb.sv -work prim_libs/div_lib
vcom -2008 modules/Dynamic_Shifter.vhd			 		-work prim_libs/div_lib
vcom -2008 modules/Dividers/divider_HF.vhd				-work prim_libs/div_lib
vcom -2008 modules/Binary\ Counters/clz_decomposing.vhd	-work prim_libs/div_lib
vsim -voptargs=+acc prim_libs/div_lib.div_tb
add wave -r sim:/div_tb/*
