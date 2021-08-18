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

module s10_2s8x8_x128_v2 #(
	parameter SIZEA = 8, // Don't change it!!!
	parameter SIZEB = 8, // Don't change it!!!
	parameter DOT = 128    // Don't change it!!!
)(
	input clk,
	input signed [SIZEA-1:0] din_a[0:DOT-1],
	input signed [SIZEB-1:0] din_b[0:DOT-1],
	output reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] dout
);


    wire signed [17:0] soft_out[0:15];
    wire signed [17:0] hard_out[0:7];
    
    wire signed [21:0] dout1;
    wire signed [20:0] dout2;
    reg signed [20:0] dout2_r;
    reg signed [20:0] dout2_r2;

	genvar i;
	generate
	for (i = 0; i < 16; i = i+1)
	begin: soft_loop
		s10_soft_sum_of_5_8x8s dot(.clk(clk), .din_a(din_a[5*i:5*i+4]), .din_b(din_b[5*i:5*i+4]), .dout(soft_out[i]));
	end
	
	for (i = 0; i < 8; i = i+1)
	begin: hard_loop
		s10_hard_sum_of_6_8x8s dot(.clk(clk), .din_a(din_a[6*i+80:6*i+85]), .din_b(din_b[6*i+80:6*i+85]), .dout(hard_out[i]));
	end
	endgenerate	
	
	adder_tree_s #(.SIZE(18), .NUM(16)) tree1 (.clk(clk), .din(soft_out), .dout(dout1));
	adder_tree_s #(.SIZE(18), .NUM(8)) tree2 (.clk(clk), .din(hard_out), .dout(dout2));
	
	always @(posedge clk) begin
	    dout2_r <= dout2;
	    dout2_r2 <= dout2_r;
	    dout <= dout1 + dout2_r2;
	end
	
endmodule
