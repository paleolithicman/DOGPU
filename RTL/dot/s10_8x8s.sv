// Copyright 2019 Intel Corporation. 
//
// This reference design file is subject licensed to you by the terms and 
// conditions of the applicable License Terms and Conditions for Hardware 
// Reference Designs and/or Design Examples (either as signed by you or 
// found at https://www.altera.com/common/legal/leg-license_agreement.html ).  
//
// As stated in the license, you agree to only use this reference design 
// solely in conjunction with Intel FPGAs or Intel CPLDs.  
//
// THE REFERENCE DESIGN IS PROVIDED "AS IS" WITHOUT ANY EXPRESS OR IMPLIED
// WARRANTY OF ANY KIND INCLUDING WARRANTIES OF MERCHANTABILITY, 
// NONINFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. Intel does not 
// warrant or assume responsibility for the accuracy or completeness of any
// information, links or other items within the Reference Design and any 
// accompanying materials.
//
// In the event that you do not agree with such terms and conditions, do not
// use the reference design file.
/////////////////////////////////////////////////////////////////////////////

module s10_8x8s (
	dout,
	clk,
	din_a,
	din_b);
output 	[15:0] dout;
input 	clk;
input 	[7:0] din_a;
input 	[7:0] din_b;

wire gnd;
wire vcc;
wire unknown;

assign gnd = 1'b0;
assign vcc = 1'b1;
assign unknown = 1'bx;

tri1 devclrn;
tri1 devpor;
tri1 devoe;
wire _mult_0_126 ;
wire _mult_0_127 ;
wire _mult_0_131 ;
wire _mult_0_132 ;
wire _mult_0_135 ;
wire _mult_0_136 ;
wire _mult_0_140 ;
wire _mult_0_141 ;
wire _mult_0_145 ;
wire _mult_0_146 ;
wire _mult_0_150 ;
wire _mult_0_151 ;
wire _mult_0_155 ;
wire _mult_0_156 ;
wire _mult_0_160 ;
wire _mult_0_161 ;
wire _mult_0_165 ;
wire _mult_0_166 ;
wire _mult_0_170 ;
wire _mult_0_171 ;
wire _mult_0_175 ;
wire _mult_0_176 ;
wire _mult_0_180 ;
wire _mult_0_185 ;
wire _mult_0_186 ;
wire _mult_0_190 ;
wire _mult_0_191 ;
wire _mult_0_195 ;
wire _mult_0_196 ;
wire _mult_0_200 ;
wire _mult_0_201 ;
wire _mult_0_205 ;
wire _mult_0_206 ;
wire _mult_0_210 ;
wire _mult_0_211 ;
wire _mult_0_215 ;
wire _mult_0_216 ;
wire _mult_0_220 ;
wire _mult_0_221 ;
wire _mult_0_225 ;
wire _mult_0_226 ;
wire _mult_0_230 ;
wire _mult_0_231 ;
wire _mult_0_235 ;
wire _mult_0_236 ;
wire _mult_0_240 ;
wire _mult_0_241 ;
wire _mult_0_245 ;
wire _mult_0_250 ;
wire _mult_0_251 ;
wire _mult_0_255 ;
wire _mult_0_256 ;
wire _mult_0_260 ;
wire _mult_0_261 ;
wire _mult_0_265 ;
wire _mult_0_266 ;
wire _mult_0_270 ;
wire _mult_0_271 ;
wire _mult_0_275 ;
wire _mult_0_276 ;
wire _mult_0_280 ;
wire _mult_0_281 ;
wire _mult_0_285 ;
wire _mult_0_286 ;
wire _mult_0_290 ;
wire _mult_0_291 ;
wire _mult_0_295 ;
wire _mult_0_296 ;
wire _mult_0_300 ;
wire _mult_0_301 ;
wire _mult_0_305 ;
wire _mult_0_306 ;
wire _mult_0_310 ;
wire _mult_0_311 ;
wire _mult_0_315 ;
wire _mult_0_316 ;
wire _mult_0_320 ;
wire _mult_0_321 ;
wire _mult_0_325 ;
wire _mult_0_326 ;
wire _mult_0_330 ;
wire _mult_0_331 ;
wire _mult_0_335 ;
wire _mult_0_340 ;
wire _mult_0_341 ;
wire _mult_0_345 ;
wire _mult_0_346 ;
wire _mult_0_350 ;
wire _mult_0_351 ;
wire _mult_0_355 ;
wire _mult_0_356 ;
wire _mult_0_360 ;
wire _mult_0_361 ;
wire _mult_0_365 ;
wire _mult_0_366 ;
wire _mult_0_370 ;
wire _mult_0_371 ;
wire _mult_0_375 ;
wire _mult_0_376 ;
wire _mult_0_380 ;
wire _mult_0_381 ;
wire _mult_0_385 ;
wire _mult_0_386 ;
wire _mult_0_390 ;
wire _mult_0_391 ;
wire _mult_0_395 ;
wire _mult_0_396 ;
wire _mult_0_400 ;
wire _mult_0_401 ;
wire _mult_0_405 ;
wire _mult_0_406 ;
wire _mult_0_410 ;
wire _mult_0_411 ;
wire _mult_0_415 ;
wire _mult_0_416 ;
wire _mult_0_420 ;
wire _mult_0_421 ;
wire _dout_0_reg0_q ;
wire _dout_1_reg0_q ;
wire _dout_2_reg0_q ;
wire _dout_3_reg0_q ;
wire _dout_4_reg0_q ;
wire _dout_5_reg0_q ;
wire _dout_6_reg0_q ;
wire _dout_7_reg0_q ;
wire _dout_8_reg0_q ;
wire _dout_9_reg0_q ;
wire _dout_10_reg0_q ;
wire _dout_11_reg0_q ;
wire _dout_12_reg0_q ;
wire _dout_13_reg0_q ;
wire _dout_14_reg0_q ;
wire _dout_15_reg0_q ;
wire _mult_0_0_q ;
wire _mult_0_2_q ;
wire _mult_0_4_q ;
wire _mult_0_6_q ;
wire _mult_0_1_q ;
wire _mult_0_3_q ;
wire _mult_0_5_q ;
wire _mult_0_60_q ;
wire _mult_0_61_q ;
wire _mult_0_63_q ;
wire _mult_0_64_q ;
wire _mult_0_57_q ;
wire _mult_0_58_q ;
wire _mult_0_54_q ;
wire _mult_0_55_q ;
wire _mult_0_38_q ;
wire _mult_0_40_q ;
wire _mult_0_42_q ;
wire _mult_0_43_q ;
wire _mult_0_44_q ;
wire _mult_0_46_q ;
wire _mult_0_48_q ;
wire _mult_0_50_q ;
wire _mult_0_51_q ;
wire _mult_0_52_q ;
wire _mult_0_31_q ;
wire _mult_0_33_q ;
wire _mult_0_36_q ;
wire _mult_0_27_q ;
wire _mult_0_29_q ;
wire _mult_0_35_q ;
wire _mult_0_8_q ;
wire _mult_0_11_q ;
wire _mult_0_12_q ;
wire _mult_0_59_q ;
wire _mult_0_62_q ;
wire _mult_0_56_q ;
wire _mult_0_53_q ;
wire _mult_0_37_q ;
wire _mult_0_39_q ;
wire _mult_0_41_q ;
wire _mult_0_45_q ;
wire _mult_0_47_q ;
wire _mult_0_49_q ;
wire _mult_0_30_q ;
wire _mult_0_32_q ;
wire _mult_0_26_q ;
wire _mult_0_28_q ;
wire _mult_0_34_q ;
wire _mult_0_7_q ;
wire _mult_0_9_q ;
wire _mult_0_10_q ;
wire _mult_0_24_q ;
wire _mult_0_25_q ;
wire _mult_0_18_q ;
wire _mult_0_19_q ;
wire _mult_0_20_q ;
wire _mult_0_21_q ;
wire _mult_0_22_q ;
wire _mult_0_23_q ;
wire _mult_0_13_q ;
wire _mult_0_14_q ;
wire _mult_0_15_q ;
wire _mult_0_17_q ;
wire _mult_0_16_q ;
wire _mult_0_65_q ;
wire _mult_0_66_q ;


fourteennm_lcell_comb _mult_0_125 (
// Equation(s):

	.dataa(!_mult_0_60_q ),
	.datab(!_mult_0_61_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_326 ),
	.combout(),
	.sumout(_mult_0_126 ),
	.cout(_mult_0_127 ));
defparam _mult_0_125 .extended_lut = "off";
defparam _mult_0_125 .lut_mask = 64'h0000000011116666;
defparam _mult_0_125 .shared_arith = "off";

fourteennm_lcell_comb mult_0(
// Equation(s):

	.dataa(!_mult_0_63_q ),
	.datab(!_mult_0_64_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_127 ),
	.combout(),
	.sumout(_mult_0_131 ),
	.cout(_mult_0_132 ));
defparam mult_0.extended_lut = "off";
defparam mult_0.lut_mask = 64'h0000000011116666;
defparam mult_0.shared_arith = "off";

fourteennm_lcell_comb _mult_0_67 (
// Equation(s):

	.dataa(!_mult_0_57_q ),
	.datab(!_mult_0_58_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_132 ),
	.combout(),
	.sumout(_mult_0_135 ),
	.cout(_mult_0_136 ));
defparam _mult_0_67 .extended_lut = "off";
defparam _mult_0_67 .lut_mask = 64'h0000000011116666;
defparam _mult_0_67 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_68 (
// Equation(s):

	.dataa(!_mult_0_54_q ),
	.datab(!_mult_0_55_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_136 ),
	.combout(),
	.sumout(_mult_0_140 ),
	.cout(_mult_0_141 ));
defparam _mult_0_68 .extended_lut = "off";
defparam _mult_0_68 .lut_mask = 64'h0000000011116666;
defparam _mult_0_68 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_69 (
// Equation(s):

	.dataa(!_mult_0_38_q ),
	.datab(!_mult_0_40_q ),
	.datac(!_mult_0_42_q ),
	.datad(!_mult_0_43_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_141 ),
	.combout(),
	.sumout(_mult_0_145 ),
	.cout(_mult_0_146 ));
defparam _mult_0_69 .extended_lut = "off";
defparam _mult_0_69 .lut_mask = 64'h0000000000696996;
defparam _mult_0_69 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_70 (
// Equation(s):

	.dataa(!_mult_0_38_q ),
	.datab(!_mult_0_40_q ),
	.datac(!_mult_0_42_q ),
	.datad(!_mult_0_44_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_146 ),
	.combout(),
	.sumout(_mult_0_150 ),
	.cout(_mult_0_151 ));
defparam _mult_0_70 .extended_lut = "off";
defparam _mult_0_70 .lut_mask = 64'h00000000001717E8;
defparam _mult_0_70 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_71 (
// Equation(s):

	.dataa(!_mult_0_46_q ),
	.datab(!_mult_0_48_q ),
	.datac(!_mult_0_50_q ),
	.datad(!_mult_0_51_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_151 ),
	.combout(),
	.sumout(_mult_0_155 ),
	.cout(_mult_0_156 ));
defparam _mult_0_71 .extended_lut = "off";
defparam _mult_0_71 .lut_mask = 64'h0000000000696996;
defparam _mult_0_71 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_72 (
// Equation(s):

	.dataa(!_mult_0_46_q ),
	.datab(!_mult_0_48_q ),
	.datac(!_mult_0_50_q ),
	.datad(!_mult_0_52_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_156 ),
	.combout(),
	.sumout(_mult_0_160 ),
	.cout(_mult_0_161 ));
defparam _mult_0_72 .extended_lut = "off";
defparam _mult_0_72 .lut_mask = 64'h00000000001717E8;
defparam _mult_0_72 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_73 (
// Equation(s):

	.dataa(!_mult_0_31_q ),
	.datab(!_mult_0_33_q ),
	.datac(!_mult_0_36_q ),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_161 ),
	.combout(),
	.sumout(_mult_0_165 ),
	.cout(_mult_0_166 ));
defparam _mult_0_73 .extended_lut = "off";
defparam _mult_0_73 .lut_mask = 64'h0000000006066969;
defparam _mult_0_73 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_74 (
// Equation(s):

	.dataa(!_mult_0_27_q ),
	.datab(!_mult_0_29_q ),
	.datac(!_mult_0_31_q ),
	.datad(!_mult_0_33_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_166 ),
	.combout(),
	.sumout(_mult_0_170 ),
	.cout(_mult_0_171 ));
defparam _mult_0_74 .extended_lut = "off";
defparam _mult_0_74 .lut_mask = 64'h0000000000066669;
defparam _mult_0_74 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_75 (
// Equation(s):

	.dataa(!_mult_0_27_q ),
	.datab(!_mult_0_29_q ),
	.datac(!_mult_0_35_q ),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_171 ),
	.combout(),
	.sumout(_mult_0_175 ),
	.cout(_mult_0_176 ));
defparam _mult_0_75 .extended_lut = "off";
defparam _mult_0_75 .lut_mask = 64'h0000000001011E1E;
defparam _mult_0_75 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_76 (
// Equation(s):

	.dataa(!_mult_0_8_q ),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_176 ),
	.combout(),
	.sumout(_mult_0_180 ),
	.cout());
defparam _mult_0_76 .extended_lut = "off";
defparam _mult_0_76 .lut_mask = 64'h000000005555AAAA;
defparam _mult_0_76 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_77 (
// Equation(s):

	.dataa(!_mult_0_11_q ),
	.datab(!_mult_0_12_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_301 ),
	.combout(),
	.sumout(_mult_0_185 ),
	.cout(_mult_0_186 ));
defparam _mult_0_77 .extended_lut = "off";
defparam _mult_0_77 .lut_mask = 64'h0000000011116666;
defparam _mult_0_77 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_78 (
// Equation(s):

	.dataa(!din_a[0]),
	.datab(!din_b[0]),
	.datac(!din_a[1]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_396 ),
	.combout(),
	.sumout(_mult_0_190 ),
	.cout(_mult_0_191 ));
defparam _mult_0_78 .extended_lut = "off";
defparam _mult_0_78 .lut_mask = 64'h00000000000E1111;
defparam _mult_0_78 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_79 (
// Equation(s):

	.dataa(!din_a[1]),
	.datab(!din_b[0]),
	.datac(!din_a[0]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_251 ),
	.combout(),
	.sumout(_mult_0_195 ),
	.cout(_mult_0_196 ));
defparam _mult_0_79 .extended_lut = "off";
defparam _mult_0_79 .lut_mask = 64'h000000000001111E;
defparam _mult_0_79 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_80 (
// Equation(s):

	.dataa(!din_a[2]),
	.datab(!din_b[0]),
	.datac(!din_a[0]),
	.datad(!din_b[2]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_191 ),
	.combout(),
	.sumout(_mult_0_200 ),
	.cout(_mult_0_201 ));
defparam _mult_0_80 .extended_lut = "off";
defparam _mult_0_80 .lut_mask = 64'h000000000001111E;
defparam _mult_0_80 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_81 (
// Equation(s):

	.dataa(!_mult_0_9_q ),
	.datab(!_mult_0_10_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_186 ),
	.combout(),
	.sumout(_mult_0_205 ),
	.cout(_mult_0_206 ));
defparam _mult_0_81 .extended_lut = "off";
defparam _mult_0_81 .lut_mask = 64'h0000000011116666;
defparam _mult_0_81 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_82 (
// Equation(s):

	.dataa(!_mult_0_24_q ),
	.datab(!_mult_0_25_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_206 ),
	.combout(),
	.sumout(_mult_0_210 ),
	.cout(_mult_0_211 ));
defparam _mult_0_82 .extended_lut = "off";
defparam _mult_0_82 .lut_mask = 64'h0000000011116666;
defparam _mult_0_82 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_83 (
// Equation(s):

	.dataa(!_mult_0_18_q ),
	.datab(!_mult_0_19_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_211 ),
	.combout(),
	.sumout(_mult_0_215 ),
	.cout(_mult_0_216 ));
defparam _mult_0_83 .extended_lut = "off";
defparam _mult_0_83 .lut_mask = 64'h0000000011116666;
defparam _mult_0_83 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_84 (
// Equation(s):

	.dataa(!_mult_0_20_q ),
	.datab(!_mult_0_21_q ),
	.datac(!_mult_0_22_q ),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_216 ),
	.combout(),
	.sumout(_mult_0_220 ),
	.cout(_mult_0_221 ));
defparam _mult_0_84 .extended_lut = "off";
defparam _mult_0_84 .lut_mask = 64'h0000000006066969;
defparam _mult_0_84 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_85 (
// Equation(s):

	.dataa(!_mult_0_20_q ),
	.datab(!_mult_0_21_q ),
	.datac(!_mult_0_23_q ),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_221 ),
	.combout(),
	.sumout(_mult_0_225 ),
	.cout(_mult_0_226 ));
defparam _mult_0_85 .extended_lut = "off";
defparam _mult_0_85 .lut_mask = 64'h0000000001011E1E;
defparam _mult_0_85 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_86 (
// Equation(s):

	.dataa(!_mult_0_13_q ),
	.datab(!_mult_0_14_q ),
	.datac(!_mult_0_15_q ),
	.datad(!_mult_0_17_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_226 ),
	.combout(),
	.sumout(_mult_0_230 ),
	.cout(_mult_0_231 ));
defparam _mult_0_86 .extended_lut = "off";
defparam _mult_0_86 .lut_mask = 64'h0000000000696996;
defparam _mult_0_86 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_87 (
// Equation(s):

	.dataa(!_mult_0_13_q ),
	.datab(!_mult_0_14_q ),
	.datac(!_mult_0_15_q ),
	.datad(!_mult_0_16_q ),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_231 ),
	.combout(),
	.sumout(_mult_0_235 ),
	.cout(_mult_0_236 ));
defparam _mult_0_87 .extended_lut = "off";
defparam _mult_0_87 .lut_mask = 64'h00000000001717E8;
defparam _mult_0_87 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_88 (
// Equation(s):

	.dataa(!_mult_0_65_q ),
	.datab(!_mult_0_66_q ),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_236 ),
	.combout(),
	.sumout(_mult_0_240 ),
	.cout(_mult_0_241 ));
defparam _mult_0_88 .extended_lut = "off";
defparam _mult_0_88 .lut_mask = 64'h0000000011116666;
defparam _mult_0_88 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_89 (
// Equation(s):

	.dataa(gnd),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_241 ),
	.combout(),
	.sumout(_mult_0_245 ),
	.cout());
defparam _mult_0_89 .extended_lut = "off";
defparam _mult_0_89 .lut_mask = 64'h0000000000000000;
defparam _mult_0_89 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_90 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[5]),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(gnd),
	.combout(),
	.sumout(_mult_0_250 ),
	.cout(_mult_0_251 ));
defparam _mult_0_90 .extended_lut = "off";
defparam _mult_0_90 .lut_mask = 64'h0000000000001111;
defparam _mult_0_90 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_91 (
// Equation(s):

	.dataa(!din_a[3]),
	.datab(!din_b[0]),
	.datac(!din_a[2]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_201 ),
	.combout(),
	.sumout(_mult_0_255 ),
	.cout(_mult_0_256 ));
defparam _mult_0_91 .extended_lut = "off";
defparam _mult_0_91 .lut_mask = 64'h000000000001111E;
defparam _mult_0_91 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_92 (
// Equation(s):

	.dataa(!din_a[1]),
	.datab(!din_b[2]),
	.datac(!din_a[0]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_196 ),
	.combout(),
	.sumout(_mult_0_260 ),
	.cout(_mult_0_261 ));
defparam _mult_0_92 .extended_lut = "off";
defparam _mult_0_92 .lut_mask = 64'h000000000001111E;
defparam _mult_0_92 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_93 (
// Equation(s):

	.dataa(!din_a[0]),
	.datab(!din_b[4]),
	.datac(!din_a[1]),
	.datad(!din_b[5]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(gnd),
	.combout(),
	.sumout(_mult_0_265 ),
	.cout(_mult_0_266 ));
defparam _mult_0_93 .extended_lut = "off";
defparam _mult_0_93 .lut_mask = 64'h00000000000E1111;
defparam _mult_0_93 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_94 (
// Equation(s):

	.dataa(!din_a[1]),
	.datab(!din_b[4]),
	.datac(!din_a[0]),
	.datad(!din_b[5]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(gnd),
	.combout(),
	.sumout(_mult_0_270 ),
	.cout(_mult_0_271 ));
defparam _mult_0_94 .extended_lut = "off";
defparam _mult_0_94 .lut_mask = 64'h000000000001111E;
defparam _mult_0_94 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_95 (
// Equation(s):

	.dataa(!din_a[2]),
	.datab(!din_b[4]),
	.datac(!din_a[0]),
	.datad(!din_b[6]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_266 ),
	.combout(),
	.sumout(_mult_0_275 ),
	.cout(_mult_0_276 ));
defparam _mult_0_95 .extended_lut = "off";
defparam _mult_0_95 .lut_mask = 64'h000000000001111E;
defparam _mult_0_95 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_96 (
// Equation(s):

	.dataa(!din_a[1]),
	.datab(!din_b[6]),
	.datac(!din_a[0]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_271 ),
	.combout(),
	.sumout(_mult_0_280 ),
	.cout(_mult_0_281 ));
defparam _mult_0_96 .extended_lut = "off";
defparam _mult_0_96 .lut_mask = 64'h000000001110EEE1;
defparam _mult_0_96 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_97 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[3]),
	.datac(!din_a[4]),
	.datad(!din_b[4]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_371 ),
	.combout(),
	.sumout(_mult_0_285 ),
	.cout(_mult_0_286 ));
defparam _mult_0_97 .extended_lut = "off";
defparam _mult_0_97 .lut_mask = 64'h000000000001111E;
defparam _mult_0_97 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_98 (
// Equation(s):

	.dataa(!din_a[3]),
	.datab(!din_b[5]),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_376 ),
	.combout(),
	.sumout(_mult_0_290 ),
	.cout(_mult_0_291 ));
defparam _mult_0_98 .extended_lut = "off";
defparam _mult_0_98 .lut_mask = 64'h000000001111EEEE;
defparam _mult_0_98 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_99 (
// Equation(s):

	.dataa(!din_a[2]),
	.datab(!din_b[6]),
	.datac(!din_a[1]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_281 ),
	.combout(),
	.sumout(_mult_0_295 ),
	.cout(_mult_0_296 ));
defparam _mult_0_99 .extended_lut = "off";
defparam _mult_0_99 .lut_mask = 64'h000000001110EEE1;
defparam _mult_0_99 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_100 (
// Equation(s):

	.dataa(gnd),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_391 ),
	.combout(),
	.sumout(_mult_0_300 ),
	.cout(_mult_0_301 ));
defparam _mult_0_100 .extended_lut = "off";
defparam _mult_0_100 .lut_mask = 64'h0000000000000000;
defparam _mult_0_100 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_101 (
// Equation(s):

	.dataa(!din_a[4]),
	.datab(!din_b[6]),
	.datac(!din_a[3]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_401 ),
	.combout(),
	.sumout(_mult_0_305 ),
	.cout(_mult_0_306 ));
defparam _mult_0_101 .extended_lut = "off";
defparam _mult_0_101 .lut_mask = 64'h000000001110EEE1;
defparam _mult_0_101 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_102 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[5]),
	.datac(!din_a[6]),
	.datad(!din_b[6]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_416 ),
	.combout(),
	.sumout(_mult_0_310 ),
	.cout(_mult_0_311 ));
defparam _mult_0_102 .extended_lut = "off";
defparam _mult_0_102 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_102 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_103 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[7]),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_421 ),
	.combout(),
	.sumout(_mult_0_315 ),
	.cout(_mult_0_316 ));
defparam _mult_0_103 .extended_lut = "off";
defparam _mult_0_103 .lut_mask = 64'h000000000000EEEE;
defparam _mult_0_103 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_104 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[6]),
	.datac(!din_a[6]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_311 ),
	.combout(),
	.sumout(_mult_0_320 ),
	.cout(_mult_0_321 ));
defparam _mult_0_104 .extended_lut = "off";
defparam _mult_0_104 .lut_mask = 64'h00000000EEE0111E;
defparam _mult_0_104 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_105 (
// Equation(s):

	.dataa(gnd),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_316 ),
	.combout(),
	.sumout(_mult_0_325 ),
	.cout(_mult_0_326 ));
defparam _mult_0_105 .extended_lut = "off";
defparam _mult_0_105 .lut_mask = 64'h0000000000000000;
defparam _mult_0_105 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_106 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[7]),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_321 ),
	.combout(),
	.sumout(_mult_0_330 ),
	.cout(_mult_0_331 ));
defparam _mult_0_106 .extended_lut = "off";
defparam _mult_0_106 .lut_mask = 64'h0000000000001111;
defparam _mult_0_106 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_107 (
// Equation(s):

	.dataa(gnd),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_331 ),
	.combout(),
	.sumout(_mult_0_335 ),
	.cout());
defparam _mult_0_107 .extended_lut = "off";
defparam _mult_0_107 .lut_mask = 64'h0000000000000000;
defparam _mult_0_107 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_108 (
// Equation(s):

	.dataa(!din_a[4]),
	.datab(!din_b[0]),
	.datac(!din_a[3]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_256 ),
	.combout(),
	.sumout(_mult_0_340 ),
	.cout(_mult_0_341 ));
defparam _mult_0_108 .extended_lut = "off";
defparam _mult_0_108 .lut_mask = 64'h000000000001111E;
defparam _mult_0_108 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_109 (
// Equation(s):

	.dataa(!din_a[2]),
	.datab(!din_b[2]),
	.datac(!din_a[1]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_261 ),
	.combout(),
	.sumout(_mult_0_345 ),
	.cout(_mult_0_346 ));
defparam _mult_0_109 .extended_lut = "off";
defparam _mult_0_109 .lut_mask = 64'h000000000001111E;
defparam _mult_0_109 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_110 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[0]),
	.datac(!din_a[4]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_341 ),
	.combout(),
	.sumout(_mult_0_350 ),
	.cout(_mult_0_351 ));
defparam _mult_0_110 .extended_lut = "off";
defparam _mult_0_110 .lut_mask = 64'h000000000001111E;
defparam _mult_0_110 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_111 (
// Equation(s):

	.dataa(!din_a[3]),
	.datab(!din_b[2]),
	.datac(!din_a[2]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_346 ),
	.combout(),
	.sumout(_mult_0_355 ),
	.cout(_mult_0_356 ));
defparam _mult_0_111 .extended_lut = "off";
defparam _mult_0_111 .lut_mask = 64'h000000000001111E;
defparam _mult_0_111 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_112 (
// Equation(s):

	.dataa(!din_a[6]),
	.datab(!din_b[0]),
	.datac(!din_a[5]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_351 ),
	.combout(),
	.sumout(_mult_0_360 ),
	.cout(_mult_0_361 ));
defparam _mult_0_112 .extended_lut = "off";
defparam _mult_0_112 .lut_mask = 64'h000000000001111E;
defparam _mult_0_112 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_113 (
// Equation(s):

	.dataa(!din_a[4]),
	.datab(!din_b[2]),
	.datac(!din_a[3]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_356 ),
	.combout(),
	.sumout(_mult_0_365 ),
	.cout(_mult_0_366 ));
defparam _mult_0_113 .extended_lut = "off";
defparam _mult_0_113 .lut_mask = 64'h000000000001111E;
defparam _mult_0_113 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_114 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[2]),
	.datac(!din_a[4]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_366 ),
	.combout(),
	.sumout(_mult_0_370 ),
	.cout(_mult_0_371 ));
defparam _mult_0_114 .extended_lut = "off";
defparam _mult_0_114 .lut_mask = 64'h000000000001111E;
defparam _mult_0_114 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_115 (
// Equation(s):

	.dataa(!din_a[3]),
	.datab(!din_b[4]),
	.datac(!din_a[2]),
	.datad(!din_b[5]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_276 ),
	.combout(),
	.sumout(_mult_0_375 ),
	.cout(_mult_0_376 ));
defparam _mult_0_115 .extended_lut = "off";
defparam _mult_0_115 .lut_mask = 64'h000000000001111E;
defparam _mult_0_115 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_116 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[0]),
	.datac(!din_a[6]),
	.datad(!din_b[1]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_361 ),
	.combout(),
	.sumout(_mult_0_380 ),
	.cout(_mult_0_381 ));
defparam _mult_0_116 .extended_lut = "off";
defparam _mult_0_116 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_116 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_117 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[1]),
	.datac(!din_a[6]),
	.datad(!din_b[2]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_381 ),
	.combout(),
	.sumout(_mult_0_385 ),
	.cout(_mult_0_386 ));
defparam _mult_0_117 .extended_lut = "off";
defparam _mult_0_117 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_117 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_118 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[4]),
	.datac(!din_a[4]),
	.datad(!din_b[5]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_286 ),
	.combout(),
	.sumout(_mult_0_390 ),
	.cout(_mult_0_391 ));
defparam _mult_0_118 .extended_lut = "off";
defparam _mult_0_118 .lut_mask = 64'h000000000001111E;
defparam _mult_0_118 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_119 (
// Equation(s):

	.dataa(gnd),
	.datab(gnd),
	.datac(gnd),
	.datad(gnd),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_291 ),
	.combout(),
	.sumout(_mult_0_395 ),
	.cout(_mult_0_396 ));
defparam _mult_0_119 .extended_lut = "off";
defparam _mult_0_119 .lut_mask = 64'h0000000000000000;
defparam _mult_0_119 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_120 (
// Equation(s):

	.dataa(!din_a[3]),
	.datab(!din_b[6]),
	.datac(!din_a[2]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_296 ),
	.combout(),
	.sumout(_mult_0_400 ),
	.cout(_mult_0_401 ));
defparam _mult_0_120 .extended_lut = "off";
defparam _mult_0_120 .lut_mask = 64'h000000001110EEE1;
defparam _mult_0_120 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_121 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[2]),
	.datac(!din_a[6]),
	.datad(!din_b[3]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_386 ),
	.combout(),
	.sumout(_mult_0_405 ),
	.cout(_mult_0_406 ));
defparam _mult_0_121 .extended_lut = "off";
defparam _mult_0_121 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_121 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_122 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[3]),
	.datac(!din_a[6]),
	.datad(!din_b[4]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_406 ),
	.combout(),
	.sumout(_mult_0_410 ),
	.cout(_mult_0_411 ));
defparam _mult_0_122 .extended_lut = "off";
defparam _mult_0_122 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_122 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_123 (
// Equation(s):

	.dataa(!din_a[7]),
	.datab(!din_b[4]),
	.datac(!din_a[6]),
	.datad(!din_b[5]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_411 ),
	.combout(),
	.sumout(_mult_0_415 ),
	.cout(_mult_0_416 ));
defparam _mult_0_123 .extended_lut = "off";
defparam _mult_0_123 .lut_mask = 64'h00000000000EEEE1;
defparam _mult_0_123 .shared_arith = "off";

fourteennm_lcell_comb _mult_0_124 (
// Equation(s):

	.dataa(!din_a[5]),
	.datab(!din_b[6]),
	.datac(!din_a[4]),
	.datad(!din_b[7]),
	.datae(gnd),
	.dataf(gnd),
	.datag(gnd),
	.datah(gnd),
	.cin(_mult_0_306 ),
	.combout(),
	.sumout(_mult_0_420 ),
	.cout(_mult_0_421 ));
defparam _mult_0_124 .extended_lut = "off";
defparam _mult_0_124 .lut_mask = 64'h000000001110EEE1;
defparam _mult_0_124 .shared_arith = "off";

fourteennm_ff _dout_0_reg0 (
	.clk(clk),
	.d(_mult_0_0_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_0_reg0_q ));
defparam _dout_0_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_1_reg0 (
	.clk(clk),
	.d(_mult_0_2_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_1_reg0_q ));
defparam _dout_1_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_2_reg0 (
	.clk(clk),
	.d(_mult_0_4_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_2_reg0_q ));
defparam _dout_2_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_3_reg0 (
	.clk(clk),
	.d(_mult_0_6_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_3_reg0_q ));
defparam _dout_3_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_4_reg0 (
	.clk(clk),
	.d(_mult_0_126 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_4_reg0_q ));
defparam _dout_4_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_5_reg0 (
	.clk(clk),
	.d(_mult_0_131 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_5_reg0_q ));
defparam _dout_5_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_6_reg0 (
	.clk(clk),
	.d(_mult_0_135 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_6_reg0_q ));
defparam _dout_6_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_7_reg0 (
	.clk(clk),
	.d(_mult_0_140 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_7_reg0_q ));
defparam _dout_7_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_8_reg0 (
	.clk(clk),
	.d(_mult_0_145 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_8_reg0_q ));
defparam _dout_8_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_9_reg0 (
	.clk(clk),
	.d(_mult_0_150 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_9_reg0_q ));
defparam _dout_9_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_10_reg0 (
	.clk(clk),
	.d(_mult_0_155 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_10_reg0_q ));
defparam _dout_10_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_11_reg0 (
	.clk(clk),
	.d(_mult_0_160 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_11_reg0_q ));
defparam _dout_11_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_12_reg0 (
	.clk(clk),
	.d(_mult_0_165 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_12_reg0_q ));
defparam _dout_12_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_13_reg0 (
	.clk(clk),
	.d(_mult_0_170 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_13_reg0_q ));
defparam _dout_13_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_14_reg0 (
	.clk(clk),
	.d(_mult_0_175 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_14_reg0_q ));
defparam _dout_14_reg0 .is_wysiwyg = "true";

fourteennm_ff _dout_15_reg0 (
	.clk(clk),
	.d(_mult_0_180 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_dout_15_reg0_q ));
defparam _dout_15_reg0 .is_wysiwyg = "true";

fourteennm_ff _mult_0_0 (
	.clk(clk),
	.d(_mult_0_1_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_0_q ));
defparam _mult_0_0 .is_wysiwyg = "true";

fourteennm_ff _mult_0_2 (
	.clk(clk),
	.d(_mult_0_3_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_2_q ));
defparam _mult_0_2 .is_wysiwyg = "true";

fourteennm_ff _mult_0_4 (
	.clk(clk),
	.d(_mult_0_5_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_4_q ));
defparam _mult_0_4 .is_wysiwyg = "true";

fourteennm_ff _mult_0_6 (
	.clk(clk),
	.d(_mult_0_185 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_6_q ));
defparam _mult_0_6 .is_wysiwyg = "true";

fourteennm_ff _mult_0_1 (
	.clk(clk),
	.d(_mult_0_190 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_1_q ));
defparam _mult_0_1 .is_wysiwyg = "true";

fourteennm_ff _mult_0_3 (
	.clk(clk),
	.d(_mult_0_195 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_3_q ));
defparam _mult_0_3 .is_wysiwyg = "true";

fourteennm_ff _mult_0_5 (
	.clk(clk),
	.d(_mult_0_200 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_5_q ));
defparam _mult_0_5 .is_wysiwyg = "true";

fourteennm_ff _mult_0_60 (
	.clk(clk),
	.d(_mult_0_59_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_60_q ));
defparam _mult_0_60 .is_wysiwyg = "true";

fourteennm_ff _mult_0_61 (
	.clk(clk),
	.d(_mult_0_205 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_61_q ));
defparam _mult_0_61 .is_wysiwyg = "true";

fourteennm_ff _mult_0_63 (
	.clk(clk),
	.d(_mult_0_62_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_63_q ));
defparam _mult_0_63 .is_wysiwyg = "true";

fourteennm_ff _mult_0_64 (
	.clk(clk),
	.d(_mult_0_210 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_64_q ));
defparam _mult_0_64 .is_wysiwyg = "true";

fourteennm_ff _mult_0_57 (
	.clk(clk),
	.d(_mult_0_56_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_57_q ));
defparam _mult_0_57 .is_wysiwyg = "true";

fourteennm_ff _mult_0_58 (
	.clk(clk),
	.d(_mult_0_215 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_58_q ));
defparam _mult_0_58 .is_wysiwyg = "true";

fourteennm_ff _mult_0_54 (
	.clk(clk),
	.d(_mult_0_53_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_54_q ));
defparam _mult_0_54 .is_wysiwyg = "true";

fourteennm_ff _mult_0_55 (
	.clk(clk),
	.d(_mult_0_220 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_55_q ));
defparam _mult_0_55 .is_wysiwyg = "true";

fourteennm_ff _mult_0_38 (
	.clk(clk),
	.d(_mult_0_37_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_38_q ));
defparam _mult_0_38 .is_wysiwyg = "true";

fourteennm_ff _mult_0_40 (
	.clk(clk),
	.d(_mult_0_39_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_40_q ));
defparam _mult_0_40 .is_wysiwyg = "true";

fourteennm_ff _mult_0_42 (
	.clk(clk),
	.d(_mult_0_41_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_42_q ));
defparam _mult_0_42 .is_wysiwyg = "true";

fourteennm_ff _mult_0_43 (
	.clk(clk),
	.d(_mult_0_225 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_43_q ));
defparam _mult_0_43 .is_wysiwyg = "true";

fourteennm_ff _mult_0_44 (
	.clk(clk),
	.d(_mult_0_230 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_44_q ));
defparam _mult_0_44 .is_wysiwyg = "true";

fourteennm_ff _mult_0_46 (
	.clk(clk),
	.d(_mult_0_45_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_46_q ));
defparam _mult_0_46 .is_wysiwyg = "true";

fourteennm_ff _mult_0_48 (
	.clk(clk),
	.d(_mult_0_47_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_48_q ));
defparam _mult_0_48 .is_wysiwyg = "true";

fourteennm_ff _mult_0_50 (
	.clk(clk),
	.d(_mult_0_49_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_50_q ));
defparam _mult_0_50 .is_wysiwyg = "true";

fourteennm_ff _mult_0_51 (
	.clk(clk),
	.d(_mult_0_235 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_51_q ));
defparam _mult_0_51 .is_wysiwyg = "true";

fourteennm_ff _mult_0_52 (
	.clk(clk),
	.d(_mult_0_240 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_52_q ));
defparam _mult_0_52 .is_wysiwyg = "true";

fourteennm_ff _mult_0_31 (
	.clk(clk),
	.d(_mult_0_30_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_31_q ));
defparam _mult_0_31 .is_wysiwyg = "true";

fourteennm_ff _mult_0_33 (
	.clk(clk),
	.d(_mult_0_32_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_33_q ));
defparam _mult_0_33 .is_wysiwyg = "true";

fourteennm_ff _mult_0_36 (
	.clk(clk),
	.d(_mult_0_245 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_36_q ));
defparam _mult_0_36 .is_wysiwyg = "true";

fourteennm_ff _mult_0_27 (
	.clk(clk),
	.d(_mult_0_26_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_27_q ));
defparam _mult_0_27 .is_wysiwyg = "true";

fourteennm_ff _mult_0_29 (
	.clk(clk),
	.d(_mult_0_28_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_29_q ));
defparam _mult_0_29 .is_wysiwyg = "true";

fourteennm_ff _mult_0_35 (
	.clk(clk),
	.d(_mult_0_34_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_35_q ));
defparam _mult_0_35 .is_wysiwyg = "true";

fourteennm_ff _mult_0_8 (
	.clk(clk),
	.d(_mult_0_7_q ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_8_q ));
defparam _mult_0_8 .is_wysiwyg = "true";

fourteennm_ff _mult_0_11 (
	.clk(clk),
	.d(_mult_0_255 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_11_q ));
defparam _mult_0_11 .is_wysiwyg = "true";

fourteennm_ff _mult_0_12 (
	.clk(clk),
	.d(_mult_0_260 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_12_q ));
defparam _mult_0_12 .is_wysiwyg = "true";

fourteennm_ff _mult_0_59 (
	.clk(clk),
	.d(_mult_0_265 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_59_q ));
defparam _mult_0_59 .is_wysiwyg = "true";

fourteennm_ff _mult_0_62 (
	.clk(clk),
	.d(_mult_0_270 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_62_q ));
defparam _mult_0_62 .is_wysiwyg = "true";

fourteennm_ff _mult_0_56 (
	.clk(clk),
	.d(_mult_0_275 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_56_q ));
defparam _mult_0_56 .is_wysiwyg = "true";

fourteennm_ff _mult_0_53 (
	.clk(clk),
	.d(_mult_0_280 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_53_q ));
defparam _mult_0_53 .is_wysiwyg = "true";

fourteennm_ff _mult_0_37 (
	.clk(clk),
	.d(_mult_0_285 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_37_q ));
defparam _mult_0_37 .is_wysiwyg = "true";

fourteennm_ff _mult_0_39 (
	.clk(clk),
	.d(_mult_0_290 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_39_q ));
defparam _mult_0_39 .is_wysiwyg = "true";

fourteennm_ff _mult_0_41 (
	.clk(clk),
	.d(_mult_0_295 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_41_q ));
defparam _mult_0_41 .is_wysiwyg = "true";

fourteennm_ff _mult_0_45 (
	.clk(clk),
	.d(_mult_0_300 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_45_q ));
defparam _mult_0_45 .is_wysiwyg = "true";

fourteennm_ff _mult_0_47 (
	.clk(clk),
	.d(_mult_0_305 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_47_q ));
defparam _mult_0_47 .is_wysiwyg = "true";

fourteennm_ff _mult_0_49 (
	.clk(clk),
	.d(_mult_0_250 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_49_q ));
defparam _mult_0_49 .is_wysiwyg = "true";

fourteennm_ff _mult_0_30 (
	.clk(clk),
	.d(_mult_0_310 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_30_q ));
defparam _mult_0_30 .is_wysiwyg = "true";

fourteennm_ff _mult_0_32 (
	.clk(clk),
	.d(_mult_0_315 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_32_q ));
defparam _mult_0_32 .is_wysiwyg = "true";

fourteennm_ff _mult_0_26 (
	.clk(clk),
	.d(_mult_0_320 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_26_q ));
defparam _mult_0_26 .is_wysiwyg = "true";

fourteennm_ff _mult_0_28 (
	.clk(clk),
	.d(_mult_0_325 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_28_q ));
defparam _mult_0_28 .is_wysiwyg = "true";

fourteennm_ff _mult_0_34 (
	.clk(clk),
	.d(_mult_0_330 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_34_q ));
defparam _mult_0_34 .is_wysiwyg = "true";

fourteennm_ff _mult_0_7 (
	.clk(clk),
	.d(_mult_0_335 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_7_q ));
defparam _mult_0_7 .is_wysiwyg = "true";

fourteennm_ff _mult_0_9 (
	.clk(clk),
	.d(_mult_0_340 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_9_q ));
defparam _mult_0_9 .is_wysiwyg = "true";

fourteennm_ff _mult_0_10 (
	.clk(clk),
	.d(_mult_0_345 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_10_q ));
defparam _mult_0_10 .is_wysiwyg = "true";

fourteennm_ff _mult_0_24 (
	.clk(clk),
	.d(_mult_0_350 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_24_q ));
defparam _mult_0_24 .is_wysiwyg = "true";

fourteennm_ff _mult_0_25 (
	.clk(clk),
	.d(_mult_0_355 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_25_q ));
defparam _mult_0_25 .is_wysiwyg = "true";

fourteennm_ff _mult_0_18 (
	.clk(clk),
	.d(_mult_0_360 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_18_q ));
defparam _mult_0_18 .is_wysiwyg = "true";

fourteennm_ff _mult_0_19 (
	.clk(clk),
	.d(_mult_0_365 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_19_q ));
defparam _mult_0_19 .is_wysiwyg = "true";

fourteennm_ff _mult_0_20 (
	.clk(clk),
	.d(_mult_0_370 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_20_q ));
defparam _mult_0_20 .is_wysiwyg = "true";

fourteennm_ff _mult_0_21 (
	.clk(clk),
	.d(_mult_0_375 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_21_q ));
defparam _mult_0_21 .is_wysiwyg = "true";

fourteennm_ff _mult_0_22 (
	.clk(clk),
	.d(_mult_0_380 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_22_q ));
defparam _mult_0_22 .is_wysiwyg = "true";

fourteennm_ff _mult_0_23 (
	.clk(clk),
	.d(_mult_0_385 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_23_q ));
defparam _mult_0_23 .is_wysiwyg = "true";

fourteennm_ff _mult_0_13 (
	.clk(clk),
	.d(_mult_0_390 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_13_q ));
defparam _mult_0_13 .is_wysiwyg = "true";

fourteennm_ff _mult_0_14 (
	.clk(clk),
	.d(_mult_0_395 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_14_q ));
defparam _mult_0_14 .is_wysiwyg = "true";

fourteennm_ff _mult_0_15 (
	.clk(clk),
	.d(_mult_0_400 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_15_q ));
defparam _mult_0_15 .is_wysiwyg = "true";

fourteennm_ff _mult_0_17 (
	.clk(clk),
	.d(_mult_0_405 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_17_q ));
defparam _mult_0_17 .is_wysiwyg = "true";

fourteennm_ff _mult_0_16 (
	.clk(clk),
	.d(_mult_0_410 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_16_q ));
defparam _mult_0_16 .is_wysiwyg = "true";

fourteennm_ff _mult_0_65 (
	.clk(clk),
	.d(_mult_0_415 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_65_q ));
defparam _mult_0_65 .is_wysiwyg = "true";

fourteennm_ff _mult_0_66 (
	.clk(clk),
	.d(_mult_0_420 ),
	.asdata(vcc),
	.clrn(vcc),
	.aload(gnd),
	.sclr(gnd),
	.sload(gnd),
	.ena(vcc),
	.sclr1(gnd),
	.q(_mult_0_66_q ));
defparam _mult_0_66 .is_wysiwyg = "true";

assign dout[0] = _dout_0_reg0_q ;

assign dout[1] = _dout_1_reg0_q ;

assign dout[2] = _dout_2_reg0_q ;

assign dout[3] = _dout_3_reg0_q ;

assign dout[4] = _dout_4_reg0_q ;

assign dout[5] = _dout_5_reg0_q ;

assign dout[6] = _dout_6_reg0_q ;

assign dout[7] = _dout_7_reg0_q ;

assign dout[8] = _dout_8_reg0_q ;

assign dout[9] = _dout_9_reg0_q ;

assign dout[10] = _dout_10_reg0_q ;

assign dout[11] = _dout_11_reg0_q ;

assign dout[12] = _dout_12_reg0_q ;

assign dout[13] = _dout_13_reg0_q ;

assign dout[14] = _dout_14_reg0_q ;

assign dout[15] = _dout_15_reg0_q ;

endmodule
