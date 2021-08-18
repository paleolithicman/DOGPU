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

module s10_soft_sum_of_5_8x8s #(
	parameter SIZEA = 8, // Don't change it!!!
	parameter SIZEB = 8, // Don't change it!!!
	parameter DOT = 5    // Don't change it!!!
)(
	input clk,
	input signed [SIZEA-1:0] din_a[0:DOT-1],
	input signed [SIZEB-1:0] din_b[0:DOT-1],
	output signed [SIZEA+SIZEB+1:0] dout
);

	wire signed [SIZEA+SIZEB-1:0] product[0:DOT-1];
	wire [SIZEA+SIZEB+1:0] product_ext[0:DOT-1];	
	
	wire [SIZEA+SIZEB+1:0] sum[0:1];
	reg [SIZEA+SIZEB+1:0] sum_r[0:1];

	reg signed [SIZEA+SIZEB+1:0] dout_r;
	reg signed [SIZEA+SIZEB+3:0] dout_w;

	genvar i;
	generate
	for (i = 0; i < DOT; i = i+1)
	begin: loop
		s10_8x8s mult(.clk(clk), .din_a(din_a[i]), .din_b(din_b[i]), .dout(product[i]));		
	end

	for (i = 0; i < DOT; i = i+1)
	begin: loop2
		assign product_ext[i] = {2'b0, ~product[i][15], product[i][14:0]};	
    end    
    
    s10_5_to_2_compressor #(18) compressor1 (
        .din_a(product_ext[0]), 
        .din_b(product_ext[1]), 
        .din_c(product_ext[2]), 
        .din_d(product_ext[3]),  
        .din_e(product_ext[4]), 
        .dout_y(sum[0]),
        .dout_z(sum[1])
    );
	endgenerate	

	always @(posedge clk) begin
	    sum_r[0] <= sum[0];
	    sum_r[1] <= sum[1];
        
        //dout_r <= {~sum_r[0][SIZEA+SIZEB+1], sum_r[0][SIZEA+SIZEB:0]} + sum_r[1] - (1 << 15);
        dout_r <= dout_w[SIZEA+SIZEB+1:0];
	end
	
	s10_a_plus_b_plus_const #(.SIZE(18), .CONST(18'b011000000000000000)) final_adder(
	    .a(sum_r[0]), .b(sum_r[1]), .out(dout_w));
	
	assign dout = dout_r;
	
endmodule
