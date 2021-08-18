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

module add_4_plus_1 (
    input ci, 
    input a0, 
    input b0, 
    input c0, 
    input d0, 
    input d1, 
    output z0, 
    output z1, 
    output co
);

wire carry;

fourteennm_lcell_comb add_0 (        
    .dataa(a0),
    .datab(b0),        
    .datac(c0),        
    .datad(d0),        
    .cin(ci),        
    .sumout(z0),
    .cout(carry));
defparam add_0.lut_mask = 64'h0000000096006996;

fourteennm_lcell_comb add_1 (        
    .dataa(a0),
    .datab(b0),        
    .datac(c0),        
    .datad(d1),        
    .cin(carry),        
    .sumout(z1),
    .cout(co));
defparam add_1.lut_mask = 64'h00000000E80017E8;

endmodule


module s10_5_to_2_compressor #(parameter WIDTH = 16) (
    input [WIDTH-1:0] din_a,
    input [WIDTH-1:0] din_b,
    input [WIDTH-1:0] din_c,
    input [WIDTH-1:0] din_d,
    input [WIDTH-1:0] din_e,
    output [WIDTH-1:0] dout_y,
    output [WIDTH-1:0] dout_z
);

wire [WIDTH/2+1:0] carry_y;
wire [WIDTH/2+1:0] carry_z;

wire [WIDTH:0] wa;
wire [WIDTH:0] wb;
wire [WIDTH:0] wc;
wire [WIDTH:0] wd;
wire [WIDTH+1:0] we;

wire [WIDTH:0] wy;
wire [WIDTH+1:0] wz;

assign wa = {1'b0, din_a};
assign wb = {1'b0, din_b};
assign wc = {1'b0, din_c};
assign wd = {1'b0, din_d};
assign we = {2'b0, din_e};

assign dout_z[WIDTH-1:1] = wz[WIDTH-1:1];
assign dout_y[WIDTH-1:0] = wy[WIDTH-1:0];

assign carry_y[0] = 1'b0;
assign carry_z[0] = 1'b0;

assign dout_z[0] = din_e[0];

genvar i;
generate
for (i = 0; i < WIDTH; i = i + 2)
begin: loop
    add_4_plus_1 add_y(
	.ci(carry_y[i/2]), 
	.a0(wa[i]), 
	.b0(wb[i]), 
	.c0(wc[i]), 
	.d0(wd[i]), 
	.d1(wd[i+1]),
	.z0(wy[i]),
	.z1(wy[i+1]),
	.co(carry_y[i/2+1])
    );

    add_4_plus_1 add_z(
	.ci(carry_z[i/2]), 
	.a0(wa[i+1]), 
	.b0(wb[i+1]), 
	.c0(wc[i+1]), 
	.d0(we[i+1]), 
	.d1(we[i+2]),
	.z0(wz[i+1]),
	.z1(wz[i+2]),
	.co(carry_z[i/2+1])
    );
end
endgenerate

endmodule
