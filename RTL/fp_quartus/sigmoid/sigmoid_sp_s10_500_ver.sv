// ------------------------------------------------------------------------- 
// High Level Design Compiler for Intel(R) FPGAs Version 19.1 (Release Build #25)
// Quartus Prime development tool and MATLAB/Simulink Interface
// 
// Legal Notice: Copyright 2018 Intel Corporation.  All rights reserved.
// Your use of  Intel Corporation's design tools,  logic functions and other
// software and  tools, and its AMPP partner logic functions, and any output
// files any  of the foregoing (including  device programming  or simulation
// files), and  any associated  documentation  or information  are expressly
// subject  to the terms and  conditions of the  Intel FPGA Software License
// Agreement, Intel MegaCore Function License Agreement, or other applicable
// license agreement,  including,  without limitation,  that your use is for
// the  sole  purpose of  programming  logic devices  manufactured by  Intel
// and  sold by Intel  or its authorized  distributors. Please refer  to the
// applicable agreement for further details.
// ---------------------------------------------------------------------------

// SystemVerilog created from sigmoid_sp_s10_500_ver
// SystemVerilog created on Thu Nov 22 16:19:51 2018


(* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007; -name MESSAGE_DISABLE 10958" *)
module sigmoid_sp_s10_500_ver (
    input wire [31:0] a,
    output wire [31:0] q,
    input wire clk,
    input wire areset
    );

    wire [0:0] GND_q;
    wire [0:0] VCC_q;
    wire [7:0] expX_uid6_fpSigmoid_b;
    wire [22:0] fracX_uid7_fpSigmoid_b;
    wire [0:0] signX_uid8_fpSigmoid_b;
    wire [7:0] cst130_uid9_fpSigmoid_q;
    wire [7:0] topFracBitsX_uid10_fpSigmoid_b;
    wire [8:0] shifterInput_uid12_fpSigmoid_q;
    wire [8:0] shiftValue_uid13_fpSigmoid_a;
    wire [8:0] shiftValue_uid13_fpSigmoid_b;
    logic [8:0] shiftValue_uid13_fpSigmoid_o;
    wire [8:0] shiftValue_uid13_fpSigmoid_q;
    wire [7:0] cst131_uid19_fpSigmoid_q;
    wire [9:0] gte16Abs_uid20_fpSigmoid_a;
    wire [9:0] gte16Abs_uid20_fpSigmoid_b;
    logic [9:0] gte16Abs_uid20_fpSigmoid_o;
    wire [0:0] gte16Abs_uid20_fpSigmoid_n;
    wire [31:0] negX_uid26_fpSigmoid_q;
    wire [0:0] ySign_uid27_fpSigmoid_b;
    wire [22:0] fraction_uid28_fpSigmoid_b;
    wire [7:0] exp_uid29_fpSigmoid_b;
    wire [0:0] invYSign_uid30_fpSigmoid_q;
    wire [31:0] minusY_uid31_fpSigmoid_q;
    wire [31:0] oneFP_uid35_fpSigmoid_q;
    wire [31:0] zeroFP_uid37_fpSigmoid_q;
    wire [0:0] ySign_uid39_fpSigmoid_b;
    wire [22:0] fraction_uid40_fpSigmoid_b;
    wire [7:0] exp_uid41_fpSigmoid_b;
    wire [0:0] invYSign_uid42_fpSigmoid_q;
    wire [31:0] minusY_uid43_fpSigmoid_q;
    wire [1:0] finalResSel_uid45_fpSigmoid_q;
    wire [1:0] finalRes_uid46_fpSigmoid_s;
    reg [31:0] finalRes_uid46_fpSigmoid_q;
    wire [3:0] wIntCst_uid50_a_uid14_fpSigmoid_q;
    wire [10:0] shiftedOut_uid51_a_uid14_fpSigmoid_a;
    wire [10:0] shiftedOut_uid51_a_uid14_fpSigmoid_b;
    logic [10:0] shiftedOut_uid51_a_uid14_fpSigmoid_o;
    wire [0:0] shiftedOut_uid51_a_uid14_fpSigmoid_n;
    wire [7:0] rightShiftStage0Idx1Rng1_uid52_a_uid14_fpSigmoid_b;
    wire [8:0] rightShiftStage0Idx1_uid54_a_uid14_fpSigmoid_q;
    wire [6:0] rightShiftStage0Idx2Rng2_uid55_a_uid14_fpSigmoid_b;
    wire [1:0] rightShiftStage0Idx2Pad2_uid56_a_uid14_fpSigmoid_q;
    wire [8:0] rightShiftStage0Idx2_uid57_a_uid14_fpSigmoid_q;
    wire [5:0] rightShiftStage0Idx3Rng3_uid58_a_uid14_fpSigmoid_b;
    wire [2:0] rightShiftStage0Idx3Pad3_uid59_a_uid14_fpSigmoid_q;
    wire [8:0] rightShiftStage0Idx3_uid60_a_uid14_fpSigmoid_q;
    wire [1:0] rightShiftStage0_uid62_a_uid14_fpSigmoid_s;
    reg [8:0] rightShiftStage0_uid62_a_uid14_fpSigmoid_q;
    wire [4:0] rightShiftStage1Idx1Rng4_uid63_a_uid14_fpSigmoid_b;
    wire [3:0] rightShiftStage1Idx1Pad4_uid64_a_uid14_fpSigmoid_q;
    wire [8:0] rightShiftStage1Idx1_uid65_a_uid14_fpSigmoid_q;
    wire [0:0] rightShiftStage1Idx2Rng8_uid66_a_uid14_fpSigmoid_b;
    wire [7:0] rightShiftStage1Idx2Pad8_uid67_a_uid14_fpSigmoid_q;
    wire [8:0] rightShiftStage1Idx2_uid68_a_uid14_fpSigmoid_q;
    wire [8:0] rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid_q;
    wire [1:0] rightShiftStage1_uid71_a_uid14_fpSigmoid_s;
    reg [8:0] rightShiftStage1_uid71_a_uid14_fpSigmoid_q;
    wire [0:0] r_uid73_a_uid14_fpSigmoid_s;
    reg [8:0] r_uid73_a_uid14_fpSigmoid_q;
    wire c0u_uid15_fpSigmoid_lutmem_reset0;
    wire [31:0] c0u_uid15_fpSigmoid_lutmem_ia;
    wire [8:0] c0u_uid15_fpSigmoid_lutmem_aa;
    wire [8:0] c0u_uid15_fpSigmoid_lutmem_ab;
    wire [31:0] c0u_uid15_fpSigmoid_lutmem_ir;
    wire [31:0] c0u_uid15_fpSigmoid_lutmem_r;
    wire c1u_uid16_fpSigmoid_lutmem_reset0;
    wire [31:0] c1u_uid16_fpSigmoid_lutmem_ia;
    wire [8:0] c1u_uid16_fpSigmoid_lutmem_aa;
    wire [8:0] c1u_uid16_fpSigmoid_lutmem_ab;
    wire [31:0] c1u_uid16_fpSigmoid_lutmem_ir;
    wire [31:0] c1u_uid16_fpSigmoid_lutmem_r;
    wire c2u_uid17_fpSigmoid_lutmem_reset0;
    wire [31:0] c2u_uid17_fpSigmoid_lutmem_ia;
    wire [8:0] c2u_uid17_fpSigmoid_lutmem_aa;
    wire [8:0] c2u_uid17_fpSigmoid_lutmem_ab;
    wire [31:0] c2u_uid17_fpSigmoid_lutmem_ir;
    wire [31:0] c2u_uid17_fpSigmoid_lutmem_r;
    wire lu_uid18_fpSigmoid_lutmem_reset0;
    wire [31:0] lu_uid18_fpSigmoid_lutmem_ia;
    wire [8:0] lu_uid18_fpSigmoid_lutmem_aa;
    wire [8:0] lu_uid18_fpSigmoid_lutmem_ab;
    wire [31:0] lu_uid18_fpSigmoid_lutmem_ir;
    wire [31:0] lu_uid18_fpSigmoid_lutmem_r;
    wire polyX_uid32_fpSigmoid_impl_reset0;
    wire polyX_uid32_fpSigmoid_impl_ena0;
    wire [31:0] polyX_uid32_fpSigmoid_impl_ax0;
    wire [31:0] polyX_uid32_fpSigmoid_impl_ay0;
    wire [31:0] polyX_uid32_fpSigmoid_impl_q0;
    wire ma0_uid33_fpSigmoid_impl_reset0;
    wire ma0_uid33_fpSigmoid_impl_ena0;
    wire [31:0] ma0_uid33_fpSigmoid_impl_ax0;
    wire [31:0] ma0_uid33_fpSigmoid_impl_ay0;
    wire [31:0] ma0_uid33_fpSigmoid_impl_az0;
    wire [31:0] ma0_uid33_fpSigmoid_impl_q0;
    wire fpPEOut_uid34_fpSigmoid_impl_reset0;
    wire fpPEOut_uid34_fpSigmoid_impl_ena0;
    wire [31:0] fpPEOut_uid34_fpSigmoid_impl_ax0;
    wire [31:0] fpPEOut_uid34_fpSigmoid_impl_ay0;
    wire [31:0] fpPEOut_uid34_fpSigmoid_impl_az0;
    wire [31:0] fpPEOut_uid34_fpSigmoid_impl_q0;
    wire omCompRes_uid44_fpSigmoid_impl_reset0;
    wire omCompRes_uid44_fpSigmoid_impl_ena0;
    wire [31:0] omCompRes_uid44_fpSigmoid_impl_ax0;
    wire [31:0] omCompRes_uid44_fpSigmoid_impl_ay0;
    wire [31:0] omCompRes_uid44_fpSigmoid_impl_q0;
    wire [3:0] rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_in;
    wire [1:0] rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_b;
    wire [1:0] rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_c;
    reg [31:0] redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_q;
    reg [31:0] redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_0;
    reg [31:0] redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_1;
    reg [31:0] redist1_ma0_uid33_fpSigmoid_impl_q0_1_q;
    reg [31:0] redist2_polyX_uid32_fpSigmoid_impl_q0_1_q;
    reg [31:0] redist4_c2u_uid17_fpSigmoid_lutmem_r_1_q;
    reg [31:0] redist5_c1u_uid16_fpSigmoid_lutmem_r_1_q;
    reg [31:0] redist6_c0u_uid15_fpSigmoid_lutmem_r_1_q;
    reg [8:0] redist7_r_uid73_a_uid14_fpSigmoid_q_4_q;
    reg [8:0] redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_0;
    reg [8:0] redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_1;
    reg [8:0] redist8_r_uid73_a_uid14_fpSigmoid_q_9_q;
    reg [8:0] redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_0;
    reg [8:0] redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_1;
    reg [8:0] redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_2;
    reg [8:0] redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_3;
    reg [0:0] redist9_gte16Abs_uid20_fpSigmoid_n_16_q;
    reg [0:0] redist10_signX_uid8_fpSigmoid_b_20_q;
    reg [22:0] redist11_fracX_uid7_fpSigmoid_b_1_q;
    reg [22:0] redist12_fracX_uid7_fpSigmoid_b_4_q;
    reg [22:0] redist12_fracX_uid7_fpSigmoid_b_4_delay_0;
    reg [22:0] redist12_fracX_uid7_fpSigmoid_b_4_delay_1;
    reg [7:0] redist13_expX_uid6_fpSigmoid_b_4_q;
    reg [7:0] redist13_expX_uid6_fpSigmoid_b_4_delay_0;
    reg [7:0] redist13_expX_uid6_fpSigmoid_b_4_delay_1;
    reg [7:0] redist13_expX_uid6_fpSigmoid_b_4_delay_2;
    reg [31:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_outputreg0_q;
    wire redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_reset0;
    wire [31:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ia;
    wire [1:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_aa;
    wire [1:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ab;
    wire [31:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_iq;
    wire [31:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_q;
    wire [1:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_q;
    (* preserve_syn_only *) reg [1:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i;
    (* preserve_syn_only *) reg redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_eq;
    reg [1:0] redist3_polyX_uid32_fpSigmoid_impl_q0_6_wraddr_q;

    import sigmoid_sp_s10_500_ver_safe_path_ver::safe_path_ver;

    // zeroFP_uid37_fpSigmoid(CONSTANT,36)
    assign zeroFP_uid37_fpSigmoid_q = 32'b00000000000000000000000000000000;

    // redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt(COUNTER,105)
    // low=0, high=2, step=1, init=0
    always @ (posedge clk)
    begin
        if (areset)
        begin
            redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i <= 2'd0;
            redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_eq <= 1'b0;
        end
        else
        begin
            if (redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i == 2'd1)
            begin
                redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_eq <= 1'b1;
            end
            else
            begin
                redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_eq <= 1'b0;
            end
            if (redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_eq == 1'b1)
            begin
                redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i <= $unsigned(redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i) + $unsigned(2'd2);
            end
            else
            begin
                redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i <= $unsigned(redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i) + $unsigned(2'd1);
            end
        end
    end
    assign redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_q = redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_i[1:0];

    // expX_uid6_fpSigmoid(BITSELECT,5)@0
    assign expX_uid6_fpSigmoid_b = a[30:23];

    // redist13_expX_uid6_fpSigmoid_b_4(DELAY,102)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist13_expX_uid6_fpSigmoid_b_4_delay_0 <= expX_uid6_fpSigmoid_b;
            redist13_expX_uid6_fpSigmoid_b_4_delay_1 <= redist13_expX_uid6_fpSigmoid_b_4_delay_0;
            redist13_expX_uid6_fpSigmoid_b_4_delay_2 <= redist13_expX_uid6_fpSigmoid_b_4_delay_1;
            redist13_expX_uid6_fpSigmoid_b_4_q <= redist13_expX_uid6_fpSigmoid_b_4_delay_2;
        end
    end

    // fracX_uid7_fpSigmoid(BITSELECT,6)@0
    assign fracX_uid7_fpSigmoid_b = a[22:0];

    // redist11_fracX_uid7_fpSigmoid_b_1(DELAY,100)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist11_fracX_uid7_fpSigmoid_b_1_q <= fracX_uid7_fpSigmoid_b;
        end
    end

    // redist12_fracX_uid7_fpSigmoid_b_4(DELAY,101)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist12_fracX_uid7_fpSigmoid_b_4_delay_0 <= redist11_fracX_uid7_fpSigmoid_b_1_q;
            redist12_fracX_uid7_fpSigmoid_b_4_delay_1 <= redist12_fracX_uid7_fpSigmoid_b_4_delay_0;
            redist12_fracX_uid7_fpSigmoid_b_4_q <= redist12_fracX_uid7_fpSigmoid_b_4_delay_1;
        end
    end

    // negX_uid26_fpSigmoid(BITJOIN,25)@4
    assign negX_uid26_fpSigmoid_q = {VCC_q, redist13_expX_uid6_fpSigmoid_b_4_q, redist12_fracX_uid7_fpSigmoid_b_4_q};

    // rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid(CONSTANT,68)
    assign rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid_q = 9'b000000000;

    // rightShiftStage1Idx2Pad8_uid67_a_uid14_fpSigmoid(CONSTANT,66)
    assign rightShiftStage1Idx2Pad8_uid67_a_uid14_fpSigmoid_q = 8'b00000000;

    // rightShiftStage1Idx2Rng8_uid66_a_uid14_fpSigmoid(BITSELECT,65)@1
    assign rightShiftStage1Idx2Rng8_uid66_a_uid14_fpSigmoid_b = rightShiftStage0_uid62_a_uid14_fpSigmoid_q[8:8];

    // rightShiftStage1Idx2_uid68_a_uid14_fpSigmoid(BITJOIN,67)@1
    assign rightShiftStage1Idx2_uid68_a_uid14_fpSigmoid_q = {rightShiftStage1Idx2Pad8_uid67_a_uid14_fpSigmoid_q, rightShiftStage1Idx2Rng8_uid66_a_uid14_fpSigmoid_b};

    // rightShiftStage1Idx1Pad4_uid64_a_uid14_fpSigmoid(CONSTANT,63)
    assign rightShiftStage1Idx1Pad4_uid64_a_uid14_fpSigmoid_q = 4'b0000;

    // rightShiftStage1Idx1Rng4_uid63_a_uid14_fpSigmoid(BITSELECT,62)@1
    assign rightShiftStage1Idx1Rng4_uid63_a_uid14_fpSigmoid_b = rightShiftStage0_uid62_a_uid14_fpSigmoid_q[8:4];

    // rightShiftStage1Idx1_uid65_a_uid14_fpSigmoid(BITJOIN,64)@1
    assign rightShiftStage1Idx1_uid65_a_uid14_fpSigmoid_q = {rightShiftStage1Idx1Pad4_uid64_a_uid14_fpSigmoid_q, rightShiftStage1Idx1Rng4_uid63_a_uid14_fpSigmoid_b};

    // rightShiftStage0Idx3Pad3_uid59_a_uid14_fpSigmoid(CONSTANT,58)
    assign rightShiftStage0Idx3Pad3_uid59_a_uid14_fpSigmoid_q = 3'b000;

    // rightShiftStage0Idx3Rng3_uid58_a_uid14_fpSigmoid(BITSELECT,57)@1
    assign rightShiftStage0Idx3Rng3_uid58_a_uid14_fpSigmoid_b = shifterInput_uid12_fpSigmoid_q[8:3];

    // rightShiftStage0Idx3_uid60_a_uid14_fpSigmoid(BITJOIN,59)@1
    assign rightShiftStage0Idx3_uid60_a_uid14_fpSigmoid_q = {rightShiftStage0Idx3Pad3_uid59_a_uid14_fpSigmoid_q, rightShiftStage0Idx3Rng3_uid58_a_uid14_fpSigmoid_b};

    // rightShiftStage0Idx2Pad2_uid56_a_uid14_fpSigmoid(CONSTANT,55)
    assign rightShiftStage0Idx2Pad2_uid56_a_uid14_fpSigmoid_q = 2'b00;

    // rightShiftStage0Idx2Rng2_uid55_a_uid14_fpSigmoid(BITSELECT,54)@1
    assign rightShiftStage0Idx2Rng2_uid55_a_uid14_fpSigmoid_b = shifterInput_uid12_fpSigmoid_q[8:2];

    // rightShiftStage0Idx2_uid57_a_uid14_fpSigmoid(BITJOIN,56)@1
    assign rightShiftStage0Idx2_uid57_a_uid14_fpSigmoid_q = {rightShiftStage0Idx2Pad2_uid56_a_uid14_fpSigmoid_q, rightShiftStage0Idx2Rng2_uid55_a_uid14_fpSigmoid_b};

    // GND(CONSTANT,0)
    assign GND_q = 1'b0;

    // rightShiftStage0Idx1Rng1_uid52_a_uid14_fpSigmoid(BITSELECT,51)@1
    assign rightShiftStage0Idx1Rng1_uid52_a_uid14_fpSigmoid_b = shifterInput_uid12_fpSigmoid_q[8:1];

    // rightShiftStage0Idx1_uid54_a_uid14_fpSigmoid(BITJOIN,53)@1
    assign rightShiftStage0Idx1_uid54_a_uid14_fpSigmoid_q = {GND_q, rightShiftStage0Idx1Rng1_uid52_a_uid14_fpSigmoid_b};

    // topFracBitsX_uid10_fpSigmoid(BITSELECT,9)@1
    assign topFracBitsX_uid10_fpSigmoid_b = redist11_fracX_uid7_fpSigmoid_b_1_q[22:15];

    // shifterInput_uid12_fpSigmoid(BITJOIN,11)@1
    assign shifterInput_uid12_fpSigmoid_q = {VCC_q, topFracBitsX_uid10_fpSigmoid_b};

    // rightShiftStage0_uid62_a_uid14_fpSigmoid(MUX,61)@1
    assign rightShiftStage0_uid62_a_uid14_fpSigmoid_s = rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_b;
    always @(rightShiftStage0_uid62_a_uid14_fpSigmoid_s or shifterInput_uid12_fpSigmoid_q or rightShiftStage0Idx1_uid54_a_uid14_fpSigmoid_q or rightShiftStage0Idx2_uid57_a_uid14_fpSigmoid_q or rightShiftStage0Idx3_uid60_a_uid14_fpSigmoid_q)
    begin
        unique case (rightShiftStage0_uid62_a_uid14_fpSigmoid_s)
            2'b00 : rightShiftStage0_uid62_a_uid14_fpSigmoid_q = shifterInput_uid12_fpSigmoid_q;
            2'b01 : rightShiftStage0_uid62_a_uid14_fpSigmoid_q = rightShiftStage0Idx1_uid54_a_uid14_fpSigmoid_q;
            2'b10 : rightShiftStage0_uid62_a_uid14_fpSigmoid_q = rightShiftStage0Idx2_uid57_a_uid14_fpSigmoid_q;
            2'b11 : rightShiftStage0_uid62_a_uid14_fpSigmoid_q = rightShiftStage0Idx3_uid60_a_uid14_fpSigmoid_q;
            default : rightShiftStage0_uid62_a_uid14_fpSigmoid_q = 9'b0;
        endcase
    end

    // cst130_uid9_fpSigmoid(CONSTANT,8)
    assign cst130_uid9_fpSigmoid_q = 8'b10000010;

    // shiftValue_uid13_fpSigmoid(SUB,12)@0 + 1
    assign shiftValue_uid13_fpSigmoid_a = {1'b0, cst130_uid9_fpSigmoid_q};
    assign shiftValue_uid13_fpSigmoid_b = {1'b0, expX_uid6_fpSigmoid_b};
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            shiftValue_uid13_fpSigmoid_o <= $unsigned(shiftValue_uid13_fpSigmoid_a) - $unsigned(shiftValue_uid13_fpSigmoid_b);
        end
    end
    assign shiftValue_uid13_fpSigmoid_q = shiftValue_uid13_fpSigmoid_o[8:0];

    // rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select(BITSELECT,88)@1
    assign rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_in = shiftValue_uid13_fpSigmoid_q[3:0];
    assign rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_b = rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_in[1:0];
    assign rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_c = rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_in[3:2];

    // rightShiftStage1_uid71_a_uid14_fpSigmoid(MUX,70)@1
    assign rightShiftStage1_uid71_a_uid14_fpSigmoid_s = rightShiftStageSel0Dto0_uid61_a_uid14_fpSigmoid_merged_bit_select_c;
    always @(rightShiftStage1_uid71_a_uid14_fpSigmoid_s or rightShiftStage0_uid62_a_uid14_fpSigmoid_q or rightShiftStage1Idx1_uid65_a_uid14_fpSigmoid_q or rightShiftStage1Idx2_uid68_a_uid14_fpSigmoid_q or rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid_q)
    begin
        unique case (rightShiftStage1_uid71_a_uid14_fpSigmoid_s)
            2'b00 : rightShiftStage1_uid71_a_uid14_fpSigmoid_q = rightShiftStage0_uid62_a_uid14_fpSigmoid_q;
            2'b01 : rightShiftStage1_uid71_a_uid14_fpSigmoid_q = rightShiftStage1Idx1_uid65_a_uid14_fpSigmoid_q;
            2'b10 : rightShiftStage1_uid71_a_uid14_fpSigmoid_q = rightShiftStage1Idx2_uid68_a_uid14_fpSigmoid_q;
            2'b11 : rightShiftStage1_uid71_a_uid14_fpSigmoid_q = rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid_q;
            default : rightShiftStage1_uid71_a_uid14_fpSigmoid_q = 9'b0;
        endcase
    end

    // wIntCst_uid50_a_uid14_fpSigmoid(CONSTANT,49)
    assign wIntCst_uid50_a_uid14_fpSigmoid_q = 4'b1001;

    // shiftedOut_uid51_a_uid14_fpSigmoid(COMPARE,50)@1
    assign shiftedOut_uid51_a_uid14_fpSigmoid_a = {2'b00, shiftValue_uid13_fpSigmoid_q};
    assign shiftedOut_uid51_a_uid14_fpSigmoid_b = {7'b0000000, wIntCst_uid50_a_uid14_fpSigmoid_q};
    assign shiftedOut_uid51_a_uid14_fpSigmoid_o = $unsigned(shiftedOut_uid51_a_uid14_fpSigmoid_a) - $unsigned(shiftedOut_uid51_a_uid14_fpSigmoid_b);
    assign shiftedOut_uid51_a_uid14_fpSigmoid_n[0] = ~ (shiftedOut_uid51_a_uid14_fpSigmoid_o[10]);

    // r_uid73_a_uid14_fpSigmoid(MUX,72)@1 + 1
    assign r_uid73_a_uid14_fpSigmoid_s = shiftedOut_uid51_a_uid14_fpSigmoid_n;
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            unique case (r_uid73_a_uid14_fpSigmoid_s)
                1'b0 : r_uid73_a_uid14_fpSigmoid_q <= rightShiftStage1_uid71_a_uid14_fpSigmoid_q;
                1'b1 : r_uid73_a_uid14_fpSigmoid_q <= rightShiftStage1Idx3_uid69_a_uid14_fpSigmoid_q;
                default : r_uid73_a_uid14_fpSigmoid_q <= 9'b0;
            endcase
        end
    end

    // lu_uid18_fpSigmoid_lutmem(DUALMEM,77)@2 + 2
    // in j@20000000
    assign lu_uid18_fpSigmoid_lutmem_aa = r_uid73_a_uid14_fpSigmoid_q;
    altera_syncram #(
        .ram_block_type("M20K"),
        .operation_mode("ROM"),
        .width_a(32),
        .widthad_a(9),
        .numwords_a(512),
        .lpm_type("altera_syncram"),
        .width_byteena_a(1),
        .outdata_reg_a("CLOCK0"),
        .outdata_sclr_a("NONE"),
        .clock_enable_input_a("NORMAL"),
        .power_up_uninitialized("FALSE"),
        .init_file(safe_path_ver("sigmoid_sp_s10_500_ver/sigmoid_sp_s10_500_ver_lu_uid18_fpSigmoid_lutmem.hex")),
        .init_file_layout("PORT_A"),
        .intended_device_family("Stratix 10")
    ) lu_uid18_fpSigmoid_lutmem_dmem (
        .clocken0(1'b1),
        .clock0(clk),
        .address_a(lu_uid18_fpSigmoid_lutmem_aa),
        .q_a(lu_uid18_fpSigmoid_lutmem_ir),
        .wren_a(),
        .wren_b(),
        .rden_a(),
        .rden_b(),
        .data_a(),
        .data_b(),
        .address_b(),
        .clock1(),
        .clocken1(),
        .clocken2(),
        .clocken3(),
        .aclr0(),
        .aclr1(),
        .addressstall_a(),
        .addressstall_b(),
        .byteena_a(),
        .byteena_b(),
        .eccencbypass(),
        .eccencparity(),
        .sclr(),
        .address2_a(),
        .address2_b(),
        .q_b(),
        .eccstatus()
    );
    assign lu_uid18_fpSigmoid_lutmem_r = lu_uid18_fpSigmoid_lutmem_ir[31:0];

    // ySign_uid27_fpSigmoid(BITSELECT,26)@4
    assign ySign_uid27_fpSigmoid_b = lu_uid18_fpSigmoid_lutmem_r[31:31];

    // invYSign_uid30_fpSigmoid(LOGICAL,29)@4
    assign invYSign_uid30_fpSigmoid_q = ~ (ySign_uid27_fpSigmoid_b);

    // exp_uid29_fpSigmoid(BITSELECT,28)@4
    assign exp_uid29_fpSigmoid_b = lu_uid18_fpSigmoid_lutmem_r[30:23];

    // fraction_uid28_fpSigmoid(BITSELECT,27)@4
    assign fraction_uid28_fpSigmoid_b = lu_uid18_fpSigmoid_lutmem_r[22:0];

    // minusY_uid31_fpSigmoid(BITJOIN,30)@4
    assign minusY_uid31_fpSigmoid_q = {invYSign_uid30_fpSigmoid_q, exp_uid29_fpSigmoid_b, fraction_uid28_fpSigmoid_b};

    // polyX_uid32_fpSigmoid_impl(FPCOLUMN,78)@4
    // out q0@7
    assign polyX_uid32_fpSigmoid_impl_ax0 = minusY_uid31_fpSigmoid_q;
    assign polyX_uid32_fpSigmoid_impl_ay0 = negX_uid26_fpSigmoid_q;
    assign polyX_uid32_fpSigmoid_impl_reset0 = 1'b0;
    assign polyX_uid32_fpSigmoid_impl_ena0 = 1'b1;
    fourteennm_fp_mac #(
        .operation_mode("sp_add"),
        .ax_clock("0"),
        .ay_clock("0"),
        .adder_input_clock("0"),
        .output_clock("0"),
        .clear_type("none")
    ) polyX_uid32_fpSigmoid_impl_DSP0 (
        .clk({1'b0,1'b0,clk}),
        .ena({ 1'b0, 1'b0, polyX_uid32_fpSigmoid_impl_ena0 }),
        .clr({ polyX_uid32_fpSigmoid_impl_reset0, polyX_uid32_fpSigmoid_impl_reset0 }),
        .ax(polyX_uid32_fpSigmoid_impl_ax0),
        .ay(polyX_uid32_fpSigmoid_impl_ay0),
        .resulta(polyX_uid32_fpSigmoid_impl_q0),
        .accumulate(),
        .az(),
        .chainin(),
        .chainout()
    );

    // redist2_polyX_uid32_fpSigmoid_impl_q0_1(DELAY,91)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist2_polyX_uid32_fpSigmoid_impl_q0_1_q <= polyX_uid32_fpSigmoid_impl_q0;
        end
    end

    // redist3_polyX_uid32_fpSigmoid_impl_q0_6_wraddr(REG,106)
    always @ (posedge clk)
    begin
        if (areset)
        begin
            redist3_polyX_uid32_fpSigmoid_impl_q0_6_wraddr_q <= 2'b10;
        end
        else
        begin
            redist3_polyX_uid32_fpSigmoid_impl_q0_6_wraddr_q <= redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_q;
        end
    end

    // redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem(DUALMEM,104)
    assign redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ia = redist2_polyX_uid32_fpSigmoid_impl_q0_1_q;
    assign redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_aa = redist3_polyX_uid32_fpSigmoid_impl_q0_6_wraddr_q;
    assign redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ab = redist3_polyX_uid32_fpSigmoid_impl_q0_6_rdcnt_q;
    altera_syncram #(
        .ram_block_type("MLAB"),
        .operation_mode("DUAL_PORT"),
        .width_a(32),
        .widthad_a(2),
        .numwords_a(3),
        .width_b(32),
        .widthad_b(2),
        .numwords_b(3),
        .lpm_type("altera_syncram"),
        .width_byteena_a(1),
        .address_reg_b("CLOCK0"),
        .indata_reg_b("CLOCK0"),
        .rdcontrol_reg_b("CLOCK0"),
        .byteena_reg_b("CLOCK0"),
        .outdata_reg_b("CLOCK1"),
        .outdata_sclr_b("NONE"),
        .clock_enable_input_a("NORMAL"),
        .clock_enable_input_b("NORMAL"),
        .clock_enable_output_b("NORMAL"),
        .read_during_write_mode_mixed_ports("DONT_CARE"),
        .power_up_uninitialized("TRUE"),
        .intended_device_family("Stratix 10")
    ) redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_dmem (
        .clocken1(1'b1),
        .clocken0(1'b1),
        .clock0(clk),
        .clock1(clk),
        .address_a(redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_aa),
        .data_a(redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ia),
        .wren_a(VCC_q[0]),
        .address_b(redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_ab),
        .q_b(redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_iq),
        .wren_b(),
        .rden_a(),
        .rden_b(),
        .data_b(),
        .clocken2(),
        .clocken3(),
        .aclr0(),
        .aclr1(),
        .addressstall_a(),
        .addressstall_b(),
        .byteena_a(),
        .byteena_b(),
        .eccencbypass(),
        .eccencparity(),
        .sclr(),
        .address2_a(),
        .address2_b(),
        .q_a(),
        .eccstatus()
    );
    assign redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_q = redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_iq[31:0];

    // redist3_polyX_uid32_fpSigmoid_impl_q0_6_outputreg0(DELAY,103)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist3_polyX_uid32_fpSigmoid_impl_q0_6_outputreg0_q <= redist3_polyX_uid32_fpSigmoid_impl_q0_6_mem_q;
        end
    end

    // redist7_r_uid73_a_uid14_fpSigmoid_q_4(DELAY,96)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_0 <= r_uid73_a_uid14_fpSigmoid_q;
            redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_1 <= redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_0;
            redist7_r_uid73_a_uid14_fpSigmoid_q_4_q <= redist7_r_uid73_a_uid14_fpSigmoid_q_4_delay_1;
        end
    end

    // c2u_uid17_fpSigmoid_lutmem(DUALMEM,76)@5 + 2
    // in j@20000000
    assign c2u_uid17_fpSigmoid_lutmem_aa = redist7_r_uid73_a_uid14_fpSigmoid_q_4_q;
    altera_syncram #(
        .ram_block_type("M20K"),
        .operation_mode("ROM"),
        .width_a(32),
        .widthad_a(9),
        .numwords_a(512),
        .lpm_type("altera_syncram"),
        .width_byteena_a(1),
        .outdata_reg_a("CLOCK0"),
        .outdata_sclr_a("NONE"),
        .clock_enable_input_a("NORMAL"),
        .power_up_uninitialized("FALSE"),
        .init_file(safe_path_ver("sigmoid_sp_s10_500_ver/sigmoid_sp_s10_500_ver_c2u_uid17_fpSigmoid_lutmem.hex")),
        .init_file_layout("PORT_A"),
        .intended_device_family("Stratix 10")
    ) c2u_uid17_fpSigmoid_lutmem_dmem (
        .clocken0(1'b1),
        .clock0(clk),
        .address_a(c2u_uid17_fpSigmoid_lutmem_aa),
        .q_a(c2u_uid17_fpSigmoid_lutmem_ir),
        .wren_a(),
        .wren_b(),
        .rden_a(),
        .rden_b(),
        .data_a(),
        .data_b(),
        .address_b(),
        .clock1(),
        .clocken1(),
        .clocken2(),
        .clocken3(),
        .aclr0(),
        .aclr1(),
        .addressstall_a(),
        .addressstall_b(),
        .byteena_a(),
        .byteena_b(),
        .eccencbypass(),
        .eccencparity(),
        .sclr(),
        .address2_a(),
        .address2_b(),
        .q_b(),
        .eccstatus()
    );
    assign c2u_uid17_fpSigmoid_lutmem_r = c2u_uid17_fpSigmoid_lutmem_ir[31:0];

    // redist4_c2u_uid17_fpSigmoid_lutmem_r_1(DELAY,93)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist4_c2u_uid17_fpSigmoid_lutmem_r_1_q <= c2u_uid17_fpSigmoid_lutmem_r;
        end
    end

    // c1u_uid16_fpSigmoid_lutmem(DUALMEM,75)@5 + 2
    // in j@20000000
    assign c1u_uid16_fpSigmoid_lutmem_aa = redist7_r_uid73_a_uid14_fpSigmoid_q_4_q;
    altera_syncram #(
        .ram_block_type("M20K"),
        .operation_mode("ROM"),
        .width_a(32),
        .widthad_a(9),
        .numwords_a(512),
        .lpm_type("altera_syncram"),
        .width_byteena_a(1),
        .outdata_reg_a("CLOCK0"),
        .outdata_sclr_a("NONE"),
        .clock_enable_input_a("NORMAL"),
        .power_up_uninitialized("FALSE"),
        .init_file(safe_path_ver("sigmoid_sp_s10_500_ver/sigmoid_sp_s10_500_ver_c1u_uid16_fpSigmoid_lutmem.hex")),
        .init_file_layout("PORT_A"),
        .intended_device_family("Stratix 10")
    ) c1u_uid16_fpSigmoid_lutmem_dmem (
        .clocken0(1'b1),
        .clock0(clk),
        .address_a(c1u_uid16_fpSigmoid_lutmem_aa),
        .q_a(c1u_uid16_fpSigmoid_lutmem_ir),
        .wren_a(),
        .wren_b(),
        .rden_a(),
        .rden_b(),
        .data_a(),
        .data_b(),
        .address_b(),
        .clock1(),
        .clocken1(),
        .clocken2(),
        .clocken3(),
        .aclr0(),
        .aclr1(),
        .addressstall_a(),
        .addressstall_b(),
        .byteena_a(),
        .byteena_b(),
        .eccencbypass(),
        .eccencparity(),
        .sclr(),
        .address2_a(),
        .address2_b(),
        .q_b(),
        .eccstatus()
    );
    assign c1u_uid16_fpSigmoid_lutmem_r = c1u_uid16_fpSigmoid_lutmem_ir[31:0];

    // redist5_c1u_uid16_fpSigmoid_lutmem_r_1(DELAY,94)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist5_c1u_uid16_fpSigmoid_lutmem_r_1_q <= c1u_uid16_fpSigmoid_lutmem_r;
        end
    end

    // ma0_uid33_fpSigmoid_impl(FPCOLUMN,80)@8
    // out q0@12
    assign ma0_uid33_fpSigmoid_impl_ax0 = redist5_c1u_uid16_fpSigmoid_lutmem_r_1_q;
    assign ma0_uid33_fpSigmoid_impl_ay0 = redist4_c2u_uid17_fpSigmoid_lutmem_r_1_q;
    assign ma0_uid33_fpSigmoid_impl_az0 = redist2_polyX_uid32_fpSigmoid_impl_q0_1_q;
    assign ma0_uid33_fpSigmoid_impl_reset0 = 1'b0;
    assign ma0_uid33_fpSigmoid_impl_ena0 = 1'b1;
    fourteennm_fp_mac #(
        .operation_mode("sp_mult_add"),
        .ax_clock("0"),
        .ay_clock("0"),
        .az_clock("0"),
        .mult_2nd_pipeline_clock("0"),
        .adder_input_clock("0"),
        .ax_chainin_pl_clock("0"),
        .output_clock("0"),
        .clear_type("none")
    ) ma0_uid33_fpSigmoid_impl_DSP0 (
        .clk({1'b0,1'b0,clk}),
        .ena({ 1'b0, 1'b0, ma0_uid33_fpSigmoid_impl_ena0 }),
        .clr({ ma0_uid33_fpSigmoid_impl_reset0, ma0_uid33_fpSigmoid_impl_reset0 }),
        .ax(ma0_uid33_fpSigmoid_impl_ax0),
        .ay(ma0_uid33_fpSigmoid_impl_ay0),
        .az(ma0_uid33_fpSigmoid_impl_az0),
        .resulta(ma0_uid33_fpSigmoid_impl_q0),
        .accumulate(),
        .chainin(),
        .chainout()
    );

    // redist1_ma0_uid33_fpSigmoid_impl_q0_1(DELAY,90)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist1_ma0_uid33_fpSigmoid_impl_q0_1_q <= ma0_uid33_fpSigmoid_impl_q0;
        end
    end

    // redist8_r_uid73_a_uid14_fpSigmoid_q_9(DELAY,97)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_0 <= redist7_r_uid73_a_uid14_fpSigmoid_q_4_q;
            redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_1 <= redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_0;
            redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_2 <= redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_1;
            redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_3 <= redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_2;
            redist8_r_uid73_a_uid14_fpSigmoid_q_9_q <= redist8_r_uid73_a_uid14_fpSigmoid_q_9_delay_3;
        end
    end

    // c0u_uid15_fpSigmoid_lutmem(DUALMEM,74)@10 + 2
    // in j@20000000
    assign c0u_uid15_fpSigmoid_lutmem_aa = redist8_r_uid73_a_uid14_fpSigmoid_q_9_q;
    altera_syncram #(
        .ram_block_type("M20K"),
        .operation_mode("ROM"),
        .width_a(32),
        .widthad_a(9),
        .numwords_a(512),
        .lpm_type("altera_syncram"),
        .width_byteena_a(1),
        .outdata_reg_a("CLOCK0"),
        .outdata_sclr_a("NONE"),
        .clock_enable_input_a("NORMAL"),
        .power_up_uninitialized("FALSE"),
        .init_file(safe_path_ver("sigmoid_sp_s10_500_ver/sigmoid_sp_s10_500_ver_c0u_uid15_fpSigmoid_lutmem.hex")),
        .init_file_layout("PORT_A"),
        .intended_device_family("Stratix 10")
    ) c0u_uid15_fpSigmoid_lutmem_dmem (
        .clocken0(1'b1),
        .clock0(clk),
        .address_a(c0u_uid15_fpSigmoid_lutmem_aa),
        .q_a(c0u_uid15_fpSigmoid_lutmem_ir),
        .wren_a(),
        .wren_b(),
        .rden_a(),
        .rden_b(),
        .data_a(),
        .data_b(),
        .address_b(),
        .clock1(),
        .clocken1(),
        .clocken2(),
        .clocken3(),
        .aclr0(),
        .aclr1(),
        .addressstall_a(),
        .addressstall_b(),
        .byteena_a(),
        .byteena_b(),
        .eccencbypass(),
        .eccencparity(),
        .sclr(),
        .address2_a(),
        .address2_b(),
        .q_b(),
        .eccstatus()
    );
    assign c0u_uid15_fpSigmoid_lutmem_r = c0u_uid15_fpSigmoid_lutmem_ir[31:0];

    // redist6_c0u_uid15_fpSigmoid_lutmem_r_1(DELAY,95)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist6_c0u_uid15_fpSigmoid_lutmem_r_1_q <= c0u_uid15_fpSigmoid_lutmem_r;
        end
    end

    // fpPEOut_uid34_fpSigmoid_impl(FPCOLUMN,83)@13
    // out q0@17
    assign fpPEOut_uid34_fpSigmoid_impl_ax0 = redist6_c0u_uid15_fpSigmoid_lutmem_r_1_q;
    assign fpPEOut_uid34_fpSigmoid_impl_ay0 = redist1_ma0_uid33_fpSigmoid_impl_q0_1_q;
    assign fpPEOut_uid34_fpSigmoid_impl_az0 = redist3_polyX_uid32_fpSigmoid_impl_q0_6_outputreg0_q;
    assign fpPEOut_uid34_fpSigmoid_impl_reset0 = 1'b0;
    assign fpPEOut_uid34_fpSigmoid_impl_ena0 = 1'b1;
    fourteennm_fp_mac #(
        .operation_mode("sp_mult_add"),
        .ax_clock("0"),
        .ay_clock("0"),
        .az_clock("0"),
        .mult_2nd_pipeline_clock("0"),
        .adder_input_clock("0"),
        .ax_chainin_pl_clock("0"),
        .output_clock("0"),
        .clear_type("none")
    ) fpPEOut_uid34_fpSigmoid_impl_DSP0 (
        .clk({1'b0,1'b0,clk}),
        .ena({ 1'b0, 1'b0, fpPEOut_uid34_fpSigmoid_impl_ena0 }),
        .clr({ fpPEOut_uid34_fpSigmoid_impl_reset0, fpPEOut_uid34_fpSigmoid_impl_reset0 }),
        .ax(fpPEOut_uid34_fpSigmoid_impl_ax0),
        .ay(fpPEOut_uid34_fpSigmoid_impl_ay0),
        .az(fpPEOut_uid34_fpSigmoid_impl_az0),
        .resulta(fpPEOut_uid34_fpSigmoid_impl_q0),
        .accumulate(),
        .chainin(),
        .chainout()
    );

    // redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3(DELAY,89)
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_0 <= fpPEOut_uid34_fpSigmoid_impl_q0;
            redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_1 <= redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_0;
            redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_q <= redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_delay_1;
        end
    end

    // oneFP_uid35_fpSigmoid(CONSTANT,34)
    assign oneFP_uid35_fpSigmoid_q = 32'b00111111100000000000000000000000;

    // ySign_uid39_fpSigmoid(BITSELECT,38)@17
    assign ySign_uid39_fpSigmoid_b = fpPEOut_uid34_fpSigmoid_impl_q0[31:31];

    // invYSign_uid42_fpSigmoid(LOGICAL,41)@17
    assign invYSign_uid42_fpSigmoid_q = ~ (ySign_uid39_fpSigmoid_b);

    // exp_uid41_fpSigmoid(BITSELECT,40)@17
    assign exp_uid41_fpSigmoid_b = fpPEOut_uid34_fpSigmoid_impl_q0[30:23];

    // fraction_uid40_fpSigmoid(BITSELECT,39)@17
    assign fraction_uid40_fpSigmoid_b = fpPEOut_uid34_fpSigmoid_impl_q0[22:0];

    // minusY_uid43_fpSigmoid(BITJOIN,42)@17
    assign minusY_uid43_fpSigmoid_q = {invYSign_uid42_fpSigmoid_q, exp_uid41_fpSigmoid_b, fraction_uid40_fpSigmoid_b};

    // omCompRes_uid44_fpSigmoid_impl(FPCOLUMN,86)@17
    // out q0@20
    assign omCompRes_uid44_fpSigmoid_impl_ax0 = minusY_uid43_fpSigmoid_q;
    assign omCompRes_uid44_fpSigmoid_impl_ay0 = oneFP_uid35_fpSigmoid_q;
    assign omCompRes_uid44_fpSigmoid_impl_reset0 = 1'b0;
    assign omCompRes_uid44_fpSigmoid_impl_ena0 = 1'b1;
    fourteennm_fp_mac #(
        .operation_mode("sp_add"),
        .ax_clock("0"),
        .ay_clock("0"),
        .adder_input_clock("0"),
        .output_clock("0"),
        .clear_type("none")
    ) omCompRes_uid44_fpSigmoid_impl_DSP0 (
        .clk({1'b0,1'b0,clk}),
        .ena({ 1'b0, 1'b0, omCompRes_uid44_fpSigmoid_impl_ena0 }),
        .clr({ omCompRes_uid44_fpSigmoid_impl_reset0, omCompRes_uid44_fpSigmoid_impl_reset0 }),
        .ax(omCompRes_uid44_fpSigmoid_impl_ax0),
        .ay(omCompRes_uid44_fpSigmoid_impl_ay0),
        .resulta(omCompRes_uid44_fpSigmoid_impl_q0),
        .accumulate(),
        .az(),
        .chainin(),
        .chainout()
    );

    // signX_uid8_fpSigmoid(BITSELECT,7)@0
    assign signX_uid8_fpSigmoid_b = a[31:31];

    // redist10_signX_uid8_fpSigmoid_b_20(DELAY,99)
    dspba_delay_ver #( .width(1), .depth(20), .reset_kind("NONE"), .phase(0), .modulus(1) )
    redist10_signX_uid8_fpSigmoid_b_20 ( .xin(signX_uid8_fpSigmoid_b), .xout(redist10_signX_uid8_fpSigmoid_b_20_q), .clk(clk), .aclr(areset), .ena(1'b1) );

    // cst131_uid19_fpSigmoid(CONSTANT,18)
    assign cst131_uid19_fpSigmoid_q = 8'b10000011;

    // gte16Abs_uid20_fpSigmoid(COMPARE,19)@4 + 1
    assign gte16Abs_uid20_fpSigmoid_a = {2'b00, redist13_expX_uid6_fpSigmoid_b_4_q};
    assign gte16Abs_uid20_fpSigmoid_b = {2'b00, cst131_uid19_fpSigmoid_q};
    always @ (posedge clk)
    begin
        if (0)
        begin
        end
        else
        begin
            gte16Abs_uid20_fpSigmoid_o <= $unsigned(gte16Abs_uid20_fpSigmoid_a) - $unsigned(gte16Abs_uid20_fpSigmoid_b);
        end
    end
    assign gte16Abs_uid20_fpSigmoid_n[0] = ~ (gte16Abs_uid20_fpSigmoid_o[9]);

    // redist9_gte16Abs_uid20_fpSigmoid_n_16(DELAY,98)
    dspba_delay_ver #( .width(1), .depth(15), .reset_kind("NONE"), .phase(0), .modulus(1) )
    redist9_gte16Abs_uid20_fpSigmoid_n_16 ( .xin(gte16Abs_uid20_fpSigmoid_n), .xout(redist9_gte16Abs_uid20_fpSigmoid_n_16_q), .clk(clk), .aclr(areset), .ena(1'b1) );

    // finalResSel_uid45_fpSigmoid(BITJOIN,44)@20
    assign finalResSel_uid45_fpSigmoid_q = {redist10_signX_uid8_fpSigmoid_b_20_q, redist9_gte16Abs_uid20_fpSigmoid_n_16_q};

    // VCC(CONSTANT,1)
    assign VCC_q = 1'b1;

    // finalRes_uid46_fpSigmoid(MUX,45)@20
    assign finalRes_uid46_fpSigmoid_s = finalResSel_uid45_fpSigmoid_q;
    always @(finalRes_uid46_fpSigmoid_s or omCompRes_uid44_fpSigmoid_impl_q0 or oneFP_uid35_fpSigmoid_q or redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_q or zeroFP_uid37_fpSigmoid_q)
    begin
        unique case (finalRes_uid46_fpSigmoid_s)
            2'b00 : finalRes_uid46_fpSigmoid_q = omCompRes_uid44_fpSigmoid_impl_q0;
            2'b01 : finalRes_uid46_fpSigmoid_q = oneFP_uid35_fpSigmoid_q;
            2'b10 : finalRes_uid46_fpSigmoid_q = redist0_fpPEOut_uid34_fpSigmoid_impl_q0_3_q;
            2'b11 : finalRes_uid46_fpSigmoid_q = zeroFP_uid37_fpSigmoid_q;
            default : finalRes_uid46_fpSigmoid_q = 32'b0;
        endcase
    end

    // xOut(GPOUT,4)@20
    assign q = finalRes_uid46_fpSigmoid_q;

endmodule
