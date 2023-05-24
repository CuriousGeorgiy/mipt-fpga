module key_pushed
(
	input clk,
	input key,
	output pushed
);

reg key_sync, key_prev;

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
	input [7:0] sw,
	output changed
);

reg [7:0] sw_sync; 
reg [7:0] sw_prev;

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
	input key0,
	input key1,
	input [7:0] num1,
	input [7:0] num2,
	output [7:0] leds1,
	output [7:0] leds2,
	output [7:0] ledsSum,
	output ledOF,
	output [13:0] seg1,
	output [13:0] seg2,
	output [13:0] segSum
);

wire pushed0;
wire pushed1;
	
key_pushed key0_pushed
(
	.clk(clk),
	.key(key0),
	.pushed(pushed0)
);

key_pushed key1_pushed
(
	.clk(clk),
	.key(key1),
	.pushed(pushed1)
);

wire changed1;
wire changed2;

switch_state_changed switch_state_changed1
(
	.clk(clk),
	.sw(num1),
	.changed(changed1)
);

switch_state_changed switch_state_changed2
(
	.clk(clk),
	.sw(num2),
	.changed(changed2)
);

reg [7:0] cnt1;
reg [7:0] cnt2;
reg [8:0] cntSum;
	
always @(posedge clk)
begin
	if(pushed0) begin
		cnt1 <= 8'h0;
		cnt2 <= 8'h0;
		cntSum <= 9'h0;
	end
	else if (pushed1) begin
		cnt1 <= num1;
		cnt2 <= num2;
		cntSum <= cnt1 + cnt2;
	end
	else if (changed1 || changed2) begin
		if (changed1)
			cnt1 <= num1;
		if (changed2)
			cnt2 <= num2;
	end
end

assign leds1 = cnt1;
assign leds2 = cnt2;
assign leds3 = cntSum[7:0];
assign ledOF = cntSum[8];

num2seg num2seg1l
(
	.num(cnt1[3:0]),
	.seg(seg1[6:0])
);
num2seg num2seg1h
(
	.num(cnt1[7:4]),
	.seg(seg1[13:7])
);

num2seg num2seg2l
(
	.num(cnt2[3:0]),
	.seg(seg2[6:0])
);
num2seg num2seg2h
(
	.num(cnt2[7:4]),
	.seg(seg2[13:7])
);

num2seg num2segSuml
(
	.num(cntSum[3:0]),
	.seg(segSum[6:0])
);
num2seg num2segSumh
(
	.num(cntSum[7:4]),
	.seg(segSum[13:7])
);

endmodule