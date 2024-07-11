rm -rf div_lib
vlib div_lib
vlog -sv div_tb.sv -work div_lib
vcom -2008 dynamic_shifter.vhd -work div_lib
vcom -2008 divider.vhd -work div_lib
vcom -2008 clz.vhd    -work div_lib
vsim -voptargs=+acc div_lib.div_tb
add wave -r sim:/div_tb/*
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/v_0
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/z_0
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/z_1
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/v_1
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/z_2
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/v_2
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/z_3
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/v_3
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/z_4
#add wave -position insertpoint /clz_tb/uut/clz_gen(0)/clz_i/CLZ_32_GEN/CLZ_32_Bit/v_flag