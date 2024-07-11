rm -rf clz_lib
vlib clz_lib
vlog -sv fpu_defs.sv fpu_ff.sv -work clz_lib
vcom  clz_tb.vhd -work clz_lib
vcom -2008 clz_for.vhd   -work clz_lib
vcom -2008 clz.vhd   	 -work clz_lib
vsim -voptargs=+acc clz_lib.clz_tb
add wave -r sim:/clz_tb/*
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