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

module fpga_task
(
	input clk,
	input rst,
	input start_stop,
	input write,
	input show,
	output [13:0] secsHex,
	output [6:0] deciSecsHex,
	output [13:0] savedHex
);

`define CLOCK_FRQ 50000000

wire rst_pushed;
wire start_stop_pushed;
wire write_pushed;
wire show_pushed;
	
key_pushed rst_key_pushed
(
	.clk(clk),
	.key(rst),
	.pushed(rst_pushed)
);

key_pushed start_stop_key_pushed
(
	.clk(clk),
	.key(start_stop),
	.pushed(start_stop_pushed)
);

key_pushed write_key_pushed
(
	.clk(clk),
	.key(write),
	.pushed(write_pushed)
);

key_pushed show_key_pushed
(
	.clk(clk),
	.key(show),
	.pushed(show_pushed)
);

reg counting;
reg [2:0] show_idx;
reg [32:0] timer;
reg [7:0] secs;
reg [3:0] deciSecs;
reg [32:0] saved;
reg [2:0] memory_sz;
reg [32:0] memory[3:0];

genvar Gi;
generate for (Gi=0; Gi<4; Gi=Gi+1) begin: memory_reset_loop1
	always @(posedge clk)
		if(rst_pushed || (write_pushed && !counting))
			memory[Gi] = 32'h0;
end
endgenerate

always @(posedge clk)
begin
	if(rst_pushed) begin
		counting <= 1'h0;
		show_idx <= 3'h0;
		timer <= 32'h0;
		secs <= 7'h0;
		deciSecs <= 4'h0;
		saved <= 32'h0;
		memory_sz <= 3'h0;
	end
	else if (start_stop_pushed) begin
		counting <= ~counting;
	end
	else if (write_pushed) begin
		if (!counting) begin
			saved <= 32'h0;
			memory_sz <= 3'h0;
		end
		else if (memory_sz < 4) begin
			saved <= timer / `CLOCK_FRQ;
			memory[memory_sz] <= timer / (`CLOCK_FRQ / 10);
			memory_sz <= memory_sz + 1;
		end
	end
	else if (show_pushed) begin
		if (!counting) begin
			if (show_idx < 4) begin
				secs <= memory[show_idx] / 10;
				deciSecs <= memory[show_idx] % 10;
				show_idx <= show_idx + 1;
			end
			else begin
				secs <= timer / `CLOCK_FRQ;
				deciSecs <= timer % (`CLOCK_FRQ / 10) % 10;
				show_idx <= 0; 
			end
		end
	end
	else begin
		if (counting) begin
			secs <= timer / `CLOCK_FRQ;
			deciSecs <= timer / (`CLOCK_FRQ / 10) % 10;
			timer <= timer + 1;
		end
	end
end

num2seg num2segSecsDecL
(
	.num(secs % 10),
	.seg(secsHex[6:0])
);
num2seg num2segSecsDecH
(
	.num(secs / 10 % 10),
	.seg(secsHex[13:7])
);

num2seg num2segDeciSecsDecL
(
	.num(deciSecs),
	.seg(deciSecsHex)
);

num2seg num2segSavedDecL
(
	.num(saved % 10),
	.seg(savedHex[6:0])
);
num2seg num2segSavedDecH
(
	.num(saved / 10 % 10),
	.seg(savedHex[13:7])
);

endmodule