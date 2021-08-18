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

module s10_a_plus_b_plus_const #(
	parameter SIZE = 12,
	parameter CONST = 1
)(
	input signed [SIZE-1:0] a,
	input signed [SIZE-1:0] b,
	output signed [SIZE+1:0] out
);
	wire [SIZE+1:0] left;
	wire [SIZE+1:0] right;
	wire temp;
	
	wire [SIZE-1:0] w_xor;
	wire [SIZE-1:0] w_maj;
	assign w_xor = a ^ b ^ CONST;
	assign w_maj = a & b | a & CONST | b & CONST;
	assign left = {w_xor[SIZE-1], w_xor[SIZE-1], w_xor};
	assign right = {w_maj[SIZE-1], w_maj, 1'b0};
	assign out = left + right;
	
endmodule
