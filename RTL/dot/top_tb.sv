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

`timescale 1ps/1ps

module top_tb ();

parameter SIZEA = 8;
parameter SIZEB = 8;
parameter DOT = 128;

reg signed [SIZEA-1:0] din_a[0:DOT-1];
reg signed [SIZEB-1:0] din_b[0:DOT-1];
wire signed [$clog2(DOT)+SIZEA+SIZEB-1:0] dout;

reg clk = 1'b0;

s10_2s8x8_x128_v2 dut (.*);

integer i;

integer counter = 0;

always @(negedge clk) begin
    for (i = 0; i < DOT; i = i + 1) begin
        din_a[i] <= $random;
	    din_b[i] <= $random;
	end
end


reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r1 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r2 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r3 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r4 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r5 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r6 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r7 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r8 = 0;
reg signed [$clog2(DOT)+SIZEA+SIZEB-1:0] alternate_dout_r9 = 0;


integer partial_sum;
always @(posedge clk) begin
    partial_sum = 0;
    for (i = 0; i < DOT; i++) begin
	partial_sum = partial_sum + din_a[i] * din_b[i];
    end

	alternate_dout_r1 <= partial_sum;
    alternate_dout_r2 <= alternate_dout_r1;
    alternate_dout_r3 <= alternate_dout_r2;
    alternate_dout_r4 <= alternate_dout_r3;
    alternate_dout_r5 <= alternate_dout_r4;
    alternate_dout_r6 <= alternate_dout_r5;
    alternate_dout_r7 <= alternate_dout_r6;
    alternate_dout_r8 <= alternate_dout_r7;
    alternate_dout_r9 <= alternate_dout_r8;
    alternate_dout <= alternate_dout_r9;
    
end

reg flushing = 1'b1;
reg fail = 1'b0;
always @(negedge clk) begin
	#10
	if (!flushing) begin
		if (dout !== alternate_dout) begin
			$display ("%b expected %b",
				dout, alternate_dout
			);
			fail = 1'b1;
		end
	end
end

integer k = 0;
initial begin
	for (k=0; k<15; k=k+1) @(negedge clk);
	flushing = 1'b0;
	for (k=0; k<1000; k=k+1) @(negedge clk);
	if (!fail) $display ("PASS");
	@(negedge clk);
	$stop();	
end

always begin
	#1000 clk = ~clk;
end

endmodule
