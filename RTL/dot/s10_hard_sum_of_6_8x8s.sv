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

module s10_hard_sum_of_6_8x8s #(
	parameter SIZEA = 8, // Don't change it!!!
	parameter SIZEB = 8, // Don't change it!!!
	parameter DOT = 6    // Don't change it!!!
)(
	input clk,
	input signed [SIZEA-1:0] din_a[0:DOT-1],
	input signed [SIZEB-1:0] din_b[0:DOT-1],
	output signed [SIZEA+SIZEB+1:0] dout
);

wire signed [63:0] chainout;
wire signed [63:0] chainout2;

fourteennm_mac  #(
	.ax_width (8),
	.ay_scan_in_width (8),
	.bx_width (8),
	.by_width (8),
	.operation_mode ("m18x18_sumof2"),
	.operand_source_max ("input"),
	.operand_source_may ("input"),
	.operand_source_mbx ("input"),
	.operand_source_mby ("input"),
	.signed_max ("true"),
	.signed_may ("true"),
	.signed_mbx ("true"),
	.signed_mby ("true"),
	.preadder_subtract_a ("false"),
	.preadder_subtract_b ("false"),
	.ay_use_scan_in ("false"),
	.by_use_scan_in ("false"),
	.delay_scan_out_ay ("false"),
	.delay_scan_out_by ("false"),
	.use_chainadder ("false"),
	.enable_double_accum ("false"),
	.load_const_value (0),
	.ax_clock ("0"),
	.ay_scan_in_clock ("0"),
	.az_clock ("none"),
	.bx_clock ("0"),
	.by_clock ("0"),
	.bz_clock ("none"),
	.coef_sel_a_clock ("none"),
	.coef_sel_b_clock ("none"),
	.sub_clock ("none"),
	.negate_clock ("none"),
	.accumulate_clock ("none"),
	.accum_pipeline_clock ("none"),
	.load_const_clock ("none"),
	.load_const_pipeline_clock ("none"),
	.input_pipeline_clock ("none"),
	.output_clock ("0"),
	.scan_out_width (8),
	.result_a_width (17)
) dsp1 (
	.clr (2'b0),
	.ax (din_a[0]),
	.ay (din_b[0]),
	.bx (din_a[1]),
	.by (din_b[1]),
	.clk ({clk, clk, clk}),
	.ena (3'b111),
	.resulta (),
	.resultb (),
	.accumulate (),
	.az (),
	.bz (),
	.chainin (),
	.chainout (chainout),
	.coefsela (),
	.coefselb (),
	.dftout (),
	.loadconst (),
	.negate (),
	.scanin (),
	.scanout (),
	.sub ()
);

fourteennm_mac  #(
	.ax_width (8),
	.ay_scan_in_width (8),
	.bx_width (8),
	.by_width (8),
	.operation_mode ("m18x18_sumof2"),
	.operand_source_max ("input"),
	.operand_source_may ("input"),
	.operand_source_mbx ("input"),
	.operand_source_mby ("input"),
	.signed_max ("true"),
	.signed_may ("true"),
	.signed_mbx ("true"),
	.signed_mby ("true"),
	.preadder_subtract_a ("false"),
	.preadder_subtract_b ("false"),
	.ay_use_scan_in ("false"),
	.by_use_scan_in ("false"),
	.delay_scan_out_ay ("false"),
	.delay_scan_out_by ("false"),
	.use_chainadder ("true"),
	.enable_double_accum ("false"),
	.load_const_value (0),
	.ax_clock ("0"),
	.ay_scan_in_clock ("0"),
	.az_clock ("none"),
	.bx_clock ("0"),
	.by_clock ("0"),
	.bz_clock ("none"),
	.coef_sel_a_clock ("none"),
	.coef_sel_b_clock ("none"),
	.sub_clock ("none"),
	.negate_clock ("none"),
	.accumulate_clock ("none"),
	.accum_pipeline_clock ("none"),
	.load_const_clock ("none"),
	.load_const_pipeline_clock ("none"),
	.input_pipeline_clock ("0"),
	.output_clock ("0"),
	.scan_out_width (8),
	.result_a_width (18)
) dsp2 (
	.clr (2'b0),
	.ax (din_a[2]),
	.ay (din_b[2]),
	.bx (din_a[3]),
	.by (din_b[3]),
	.clk ({clk, clk, clk}),
	.ena (3'b111),
	.resulta (),
	.resultb (),
	.accumulate (),
	.az (),
	.bz (),
	.chainin (chainout),
	.chainout (chainout2),
	.coefsela (),
	.coefselb (),
	.dftout (),
	.loadconst (),
	.negate (),
	.scanin (),
	.scanout (),
	.sub ()
);

fourteennm_mac  #(
	.ax_width (8),
	.ay_scan_in_width (8),
	.bx_width (8),
	.by_width (8),
	.operation_mode ("m18x18_sumof2"),
	.operand_source_max ("input"),
	.operand_source_may ("input"),
	.operand_source_mbx ("input"),
	.operand_source_mby ("input"),
	.signed_max ("true"),
	.signed_may ("true"),
	.signed_mbx ("true"),
	.signed_mby ("true"),
	.preadder_subtract_a ("false"),
	.preadder_subtract_b ("false"),
	.ay_use_scan_in ("false"),
	.by_use_scan_in ("false"),
	.delay_scan_out_ay ("false"),
	.delay_scan_out_by ("false"),
	.use_chainadder ("true"),
	.enable_double_accum ("false"),
	.load_const_value (0),
	.ax_clock ("0"),
	.ay_scan_in_clock ("0"),
	.az_clock ("none"),
	.bx_clock ("0"),
	.by_clock ("0"),
	.bz_clock ("none"),
	.coef_sel_a_clock ("none"),
	.coef_sel_b_clock ("none"),
	.sub_clock ("none"),
	.negate_clock ("none"),
	.accumulate_clock ("none"),
	.accum_pipeline_clock ("none"),
	.load_const_clock ("none"),
	.load_const_pipeline_clock ("none"),
	.input_pipeline_clock ("0"),
	.second_pipeline_clock ("0"),
	.output_clock ("0"),
	.scan_out_width (8),
	.result_a_width (18)
) dsp3 (
	.clr (2'b0),
	.ax (din_a[4]),
	.ay (din_b[4]),
	.bx (din_a[5]),
	.by (din_b[5]),
	.clk ({clk, clk, clk}),
	.ena (3'b111),
	.resulta (dout),
	.resultb (),
	.accumulate (),
	.az (),
	.bz (),
	.chainin (chainout2),
	.chainout (),
	.coefsela (),
	.coefselb (),
	.dftout (),
	.loadconst (),
	.negate (),
	.scanin (),
	.scanout (),
	.sub ()
);

endmodule
