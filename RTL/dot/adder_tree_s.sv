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

module adder_tree_s #(
	parameter SIZE = 8,
	parameter NUM = 256
)(
   input clk,
   input signed [SIZE-1:0] din[0:NUM-1],
   output signed [$clog2(NUM)+SIZE-1:0] dout
);

	wire signed [$clog2(NUM)+SIZE-1:0] dout_w;
	genvar i;
	generate
	if (NUM == 2)
	begin
		reg signed [$clog2(NUM)+SIZE-1:0] dout_r;
		always @(posedge clk)
		begin
			dout_r <= {1'b0, !din[0][SIZE-1], din[0][SIZE-2:0]} + {1'b0, !din[1][SIZE-1], din[1][SIZE-2:0]};
		end
		assign dout = {!dout_r[$clog2(NUM)+SIZE-1], dout_r[$clog2(NUM)+SIZE-2:0]};
	end
	else
	begin
		localparam HALF_NUM = (NUM + 1) / 2;
		reg [SIZE:0] first_level[0:HALF_NUM-1];
		for (i = 0; i < NUM/2; i = i+1)
		begin: level
			always @(posedge clk)
			begin
				first_level[i] <= {1'b0, !din[2*i][SIZE-1], din[2*i][SIZE-2:0]} + {1'b0, !din[2*i+1][SIZE-1], din[2*i+1][SIZE-2:0]};
			end
		end
		adder_tree_u #(SIZE+1, HALF_NUM) inst(.clk(clk), .din(first_level), .dout(dout_w));
		assign dout = {!dout_w[$clog2(NUM)+SIZE-1], dout_w[$clog2(NUM)+SIZE-2:0]};
	end
	endgenerate
endmodule
