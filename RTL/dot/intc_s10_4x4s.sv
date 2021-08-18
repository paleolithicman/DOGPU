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

module intc_s10_4x4s #(
	parameter PIPELINE = 1
)(
	input clk,
	
	input signed [3:0] din_a,
	input signed [3:0] din_b,
	output signed [7:0] dout
);

wire signed [7:0] sum_w;

wire [3:0] ab0 = {din_a[3], din_a[3:1]} & {4{din_b[0]}};
wire [3:0] ab1 = din_a & {4{din_b[1]}};
wire [3:0] ab2 = {din_a[3], din_a[3:1]} & {4{din_b[2]}};
wire [3:0] ab3 = ~din_a & {4{din_b[3]}};

wire [4:0] ab01 = {1'b0, !ab0[3], ab0[2:0]} + {1'b0, !ab1[3], ab1[2:0]};
wire [4:0] ab23 = {1'b0, !ab2[3], ab2[2:0]} + {1'b0, !ab3[3], ab3[2:0]};


wire signed [3:0] din_a_w;
wire signed [3:0] din_b_w;
wire [4:0] ab01_w;
wire [4:0] ab23_w;


generate
	if (PIPELINE == 1)
	begin
		reg signed [3:0] din_a_r;
		reg signed [3:0] din_b_r;
		reg [4:0] ab01_r;
		reg [4:0] ab23_r;
		always @(posedge clk) begin
			din_a_r <= din_a;
			din_b_r <= din_b;
			ab01_r <= ab01;
			ab23_r <= ab23;
		end
		assign din_a_w = din_a_r;
		assign din_b_w = din_b_r;	
		assign ab01_w = ab01_r;
		assign ab23_w = ab23_r;
	end
	else
	begin
		assign din_a_w = din_a;
		assign din_b_w = din_b;	
		assign ab01_w = ab01;
		assign ab23_w = ab23;	
	end

endgenerate


assign sum_w[1] = ab01_w[0];


wire [5:0] cout_w;

// c&d
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_0000_F000),
    .dont_touch("on")
) cAND (
    .dataa(), 
    .datab(), 
    .datac(din_a_w[0]), 
    .datad(din_b_w[0]), 
    .cin(1'b0),
    .sumout(sum_w[0]), 
    .cout(cout_w[0]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);



// c&d + b
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_C000_3CCC)
) c0 (
    .dataa(), 
    .datab(ab01_w[1]), 
    .datac(din_a_w[0]), 
    .datad(din_b_w[2]), 
    .cin(cout_w[0]),
    .sumout(sum_w[2]), 
    .cout(cout_w[1]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);

// c^d + a
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_0AA0_A55A)
) c1 (
    .dataa(din_b_w[3]), 
    .datab(), 
    .datac(ab01_w[2]), 
    .datad(ab23_w[0]), 
    .cin(cout_w[1]),
    .sumout(sum_w[3]), 
    .cout(cout_w[2]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);

// c&d + a^b
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_6000_9666)
) c2 (
    .dataa(ab01_w[3]), 
    .datab(ab23_w[1]), 
    .datac(ab01_w[2]), 
    .datad(ab23_w[0]), 
    .cin(cout_w[2]),
    .sumout(sum_w[4]), 
    .cout(cout_w[3]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);

// !c^d + a&b
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_8008_7887)
) c3 (
    .dataa(ab01_w[3]), 
    .datab(ab23_w[1]), 
    .datac(ab01_w[4]), 
    .datad(ab23_w[2]), 
    .cin(cout_w[3]),
    .sumout(sum_w[5]), 
    .cout(cout_w[4]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);

// !c&d + !a^b
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_0900_9699)
) c4 (
    .dataa(ab01_w[4]), 
    .datab(ab23_w[3]), 
    .datac(ab01_w[4]), 
    .datad(ab23_w[2]), 
    .cin(cout_w[4]),
    .sumout(sum_w[6]), 
    .cout(cout_w[5]),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);

// c^d + !a&b
fourteennm_lcell_comb #(
    .lut_mask(64'h0000_0000_0440_4BB4)
) c5 (
    .dataa(ab01_w[4]), 
    .datab(ab23_w[3]), 
    .datac(ab01_w[4]), 
    .datad(ab23_w[4]), 
    .cin(cout_w[5]),
    .sumout(sum_w[7]), 
    .cout(),
    .datae(), .dataf(), .datag(), .datah(), .sharein(), .shareout(), .combout()
);


reg signed [7:0] sum_r = 8'b0;
always @(posedge clk) begin
    sum_r <= sum_w;
end

assign dout = sum_r;	
	
endmodule
