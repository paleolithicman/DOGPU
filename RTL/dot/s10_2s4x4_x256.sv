// Copyright 2018 Intel Corporation. 
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

module s10_2s4x4_x256 #(
	parameter SIZEA = 4, // Don't change it!!!
	parameter SIZEB = 4, // Don't change it!!!
	parameter DOT = 256,
	parameter PIPELINE = 1
)(
	input clk,
	input signed [SIZEA-1:0] din_a[0:DOT-1],
	input signed [SIZEB-1:0] din_b[0:DOT-1],
	output signed [$clog2(DOT)+SIZEA+SIZEB-1:0] dout
);
	
	wire [SIZEA+SIZEB-1:0] product[0:DOT-1];
	wire [SIZEA+SIZEB+3:0] product1[0:DOT/16-1];

	genvar i;
	generate
	for (i = 0; i < DOT; i = i+1)
	begin: loop
		intc_s10_4x4s #(PIPELINE) mult(.clk(clk), .din_a(din_a[i]), .din_b(din_b[i]), .dout(product[i]));
	end

	for (i = 0; i < DOT/16; i = i+1)
	begin: loop1
		adder_tree_s #(SIZEA+SIZEB, 16) tree(.clk(clk), .din(product[16*i:16*i+15]), .dout(product1[i]));	
	end

	adder_tree_s #(SIZEA+SIZEB+4, DOT/16) final_tree(.clk(clk), .din(product1), .dout(dout));	
	
	endgenerate	
endmodule
