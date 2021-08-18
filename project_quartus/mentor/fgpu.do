# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator.
# #
 set QSYS_SIMDIR $env(QSYS_SIMDIR)
# #
# # Source the generated IP simulation script.
 source $QSYS_SIMDIR/mentor/msim_setup.tcl
# #
# # Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
# #
# # Call command to compile the Quartus EDA simulation library.
 dev_com
# #
# # Call command to compile the Quartus-generated IP simulation files.
 com
# #
# # Add commands to compile all design files and testbench files, including
# # the top level. (These are all the files required for simulation other
# # than the files compiled by the Quartus-generated IP simulation script)
# #
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/DSP48E1.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/FGPU_definitions.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/FGPU_simulation_pkg.vhd
 vlog -work work -stats=none $QSYS_SIMDIR/../RTL/reorder_validQ.v
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/dot_fir.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fifo.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/global_mem.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/init_alu_en_ram.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/lmem.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/smem.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/loc_indcs_generator.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/mult_add_sub.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/regFile_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/regFile_dp_bhv.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/RTM.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/WG_dispatcher.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/fadd_fsub.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/fdiv.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/fmul.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/frsqrt.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/fsqrt.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/fslt.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/uitofp.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/fp_quartus/ffma.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/float_units.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/ALU_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/CU_instruction_dispatcher_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/CU_mem_cntrl.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/CU_scheduler_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/mcr_wrap.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/CV_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/CU_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/gmem_cntrl_hbm.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/FGPU_vliw.vhd
 vcom -work work -2008 -explicit -stats=none $QSYS_SIMDIR/../RTL/FGPU_hbm_tb.vhd
# #
# # Set the top-level simulation or testbench module/entity name, which is
# # used by the elab command to elaborate the top level.
# #
 set TOP_LEVEL_NAME FGPU_tb
# #
# # Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
# #
# # Call command to elaborate your design and testbench.
 elab
# #
# # Run the simulation.
## add wave *
 #view structure
 #view signals
 #add wave -position insertpoint sim:/fgpu_tb/gmem_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_insts(0)/gmem_controller_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_insts(1)/gmem_controller_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_insts(2)/gmem_controller_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_insts(3)/gmem_controller_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_inst/tags_controller/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_inst/axi_cntrl/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/gmem_controller_inst/cache_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/csr
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/vrs_out 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/vrt_out 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/vres_out 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/macro_gen/mcr_inst/MCRs(0)/mcr_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/shared_mem_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CU_mem_cntrl_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CUS_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/mem_regFile_wrData
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/smem_regFile_wrData_d2
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/vrx_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/vres_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/mem_regFile_wrData
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CU_mem_cntrl_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CV_inst/ALUs(1)/alu_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/vvv_gen/vvv_inst/* 
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/reg_blocks(0)/reg_file/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/freg_blocks(0)/freg_file/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/shared_mem_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/shared_mem_inst/output_bufs(0)/output_buf/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(0)/compute_unit_inst/CUS_inst/st_wf
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CV_inst/* 
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CUS_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CUS_inst/wf_reach_gsync
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CU_mem_cntrl_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(1)/compute_unit_inst/CUS_inst/st_wf
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(2)/compute_unit_inst/CV_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(2)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(2)/compute_unit_inst/CUS_inst/st_wf
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/reg_blocks(0)/reg_file/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/freg_blocks(0)/freg_file/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/shared_mem_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/shared_mem_inst/output_bufs(0)/output_buf/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_inst/compute_units_i_low(3)/compute_unit_inst/CUS_inst/st_wf
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(1)/compute_unit_inst/CV_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/vvv_gen/vvv_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/ALUs(1)/alu_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/ALUs(1)/alu_inst/vvv_gen/vvv_inst/* 
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/mem_regFile_wrData
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/smem_regFile_wrData_d2
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/vrx_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/vres_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CV_inst/mem_regFile_wrData
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CU_mem_cntrl_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/shared_mem_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/shared_mem_inst/output_bufs(0)/output_buf/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(2)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(1)/compute_unit_inst/CUS_inst/st_wf
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(4)/compute_unit_inst/CUS_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CV_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CV_inst/ALUs(3)/alu_inst/vvv_gen/vvv_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CUS_inst/st_wf
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CUS_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(5)/compute_unit_inst/CU_mem_cntrl_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(6)/compute_unit_inst/CV_inst/* 
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(6)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(6)/compute_unit_inst/CUS_inst/st_wf
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/* 
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/csr
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/vrs_out 
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/vrt_out 
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/vres_out 
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/macro_gen/mcr_inst/MCRs(0)/mcr_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/shared_mem_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CU_mem_cntrl_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/*
 add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CUS_inst/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/vvv_gen/vvv_inst/* 
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/mem_regFile_wrData
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/smem_regFile_wrData_d2
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/vrx_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/vres_out
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/mem_regFile_wrData
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CU_mem_cntrl_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CV_inst/ALUs(0)/alu_inst/reg_blocks(0)/reg_file/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/shared_mem_inst/*
 ##add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/shared_mem_inst/output_bufs(0)/output_buf/*
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CUS_inst/wf_reach_gsync
 #add wave -position insertpoint sim:/fgpu_tb/uut/compute_units_i_high(7)/compute_unit_inst/CUS_inst/st_wf
 run -a
# #
# # Report success to the shell.
 exit -code 0
