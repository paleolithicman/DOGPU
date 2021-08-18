module reorder_validQ
#(parameter ADDR_WIDTH=4)
(
	input wrdata,
	input [(ADDR_WIDTH-1):0] wraddr, rdaddr,
	input we_a, clock, nrst,
	output reg q_a
);
// Declare the RAM variable
reg [2**ADDR_WIDTH-1:0] ram;

always @ (posedge clock)
begin
    if (!nrst) begin
        ram <= 0;
        q_a <= 0;
    end
    else begin
        // Port A  is for writing only
        if (we_a) begin
            ram[wraddr] <= wrdata;
        end
        // Port B is for reading only
        q_a <= ram[rdaddr];
    end
end
	
endmodule

