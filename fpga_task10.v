module key_pushed
(
	input clk,
	input key,
	output pushed
);

reg key_sync;
reg key_prev;

always @(posedge clk)
begin
	key_sync <= key;
	key_prev <= key_sync;
end
	
assign pushed = key_prev & ~key_sync;

endmodule

module switch_state_changed
(
	input clk,
	input [2:0] sw,
	output changed
);

reg [2:0] sw_sync; 
reg [2:0] sw_prev;

always @(posedge clk)
begin
	sw_sync <= sw;
	sw_prev <= sw_sync;
end
	
assign changed = sw_prev & ~sw_sync;

endmodule

module num2seg
(
	input [3:0] num,
	output [6:0] seg
);

assign seg = num == 4'h0 ? 7'b1000000 :
				 num == 4'h1 ? 7'b1111001 :
				 num == 4'h2 ? 7'b0100100 :
				 num == 4'h3 ? 7'b0110000 :
				 num == 4'h4 ? 7'b0011001 :
				 num == 4'h5 ? 7'b0010010 :
				 num == 4'h6 ? 7'b0000010 :
				 num == 4'h7 ? 7'b1111000 :
				 num == 4'h8 ? 7'b0000000 :
				 num == 4'h9 ? 7'b0010000 :
				 num == 4'hA ? 7'b0001000 :
				 num == 4'hB ? 7'b0000011 :
				 num == 4'hC ? 7'b1000110 :
				 num == 4'hD ? 7'b0100001 :
				 num == 4'hE ? 7'b0000110 :
				                7'b0001110;
endmodule

module num2leds
(
	input [2:0] num,
	output [6:0] leds
);

assign leds = num == 3'h0 ? 7'b0000000 :
				  num == 3'h1 ? 7'b0000001 :
				  num == 3'h2 ? 7'b0000011 :
				  num == 3'h3 ? 7'b0000111 :
				  num == 3'h4 ? 7'b0001111 :
				  num == 3'h5 ? 7'b0011111 :
				  num == 3'h6 ? 7'b0111111 :
				                7'b1111111;
									 
		
endmodule

module fpga_task
(
	input clk,
	input rst,
	input write,
	input [2:0] addr,
	input [7:0] val,
	output [7:0] leds
);

wire rst_pushed;
wire write_pushed;
	
key_pushed rst_key_pushed
(
	.clk(clk),
	.key(rst),
	.pushed(rst_pushed)
);

key_pushed write_key_pushed
(
	.clk(clk),
	.key(write),
	.pushed(write_pushed)
);

wire addr_changed;

switch_state_changed addr_state_changed
(
	.clk(clk),
	.sw(addr),
	.changed(addr_changed)
);

reg [7:0] memory[7:0];
reg [7:0] valAtAddr;

genvar Gi;
generate for (Gi=0; Gi<8; Gi=Gi+1) begin: memory_init_loop
	always @(posedge clk) begin
		if (rst_pushed) begin
			memory[Gi] = 8'h0;
		end
	end
end
endgenerate

always @(posedge clk)
begin
	if(rst_pushed)
		valAtAddr <= 8'h0;
	else if (write_pushed) begin
		memory[addr] <= val;
		valAtAddr <= val;
	end
	else if (addr_changed)
		valAtAddr <= memory[addr];
end

assign leds = valAtAddr;

endmodule