`define CLK_IN_HZ 50000000
`define BAUD_RATE 256000

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

module rs232_uart_tx
(
	input clk,
	input rst,
	input send,
	output reg tx_busy,
	input [7:0] tx_data,
	output reg txd
);

localparam TX_PERIOD = `CLK_IN_HZ / `BAUD_RATE - 1;

reg [15:0] tx_period;
reg [3:0] tx_position;
reg [9:0] tx_byte;
reg [7:0] tx_data_reg;

always @ (posedge clk) begin
	if (rst) begin
		tx_period <= 16'h0;
		tx_position <= 4'h0;
		tx_byte <= 10'b1111111111;
		tx_data_reg <= 8'b11111111;
		tx_busy <= 1'b0;
	end 
	else begin
		if (send && ~tx_busy) begin                    
			tx_data_reg <= tx_data;  
			tx_busy <= 1'b1;  
		end
		if (tx_period == TX_PERIOD[15:0] >> 1) begin
			if (tx_position == 1) begin
				if (tx_busy) begin
					tx_byte[8:1] <= tx_data_reg[7:0];
					tx_byte[9] <= 1'b1;
					tx_byte[0] <= 1'b0;
					tx_busy <= 1'b0;
				end
			end
			else begin
				tx_byte[8:0] <= tx_byte[9:1];
				tx_byte[9] <= 1'b1;
			end
		end
		if (tx_period == 0) begin
			tx_period <= TX_PERIOD[15:0];
			txd <= tx_byte[0];
			if (tx_position == 0) 
				tx_position <= 4'h9;
			else 
				tx_position <= tx_position - 1'b1;
		end
		else
			tx_period <= tx_period - 1'b1;
	end
end

endmodule

module rs232_uart_rx
(
	input wire clk,
	input wire rst,
	input wire rxd,
	output reg rx_rdy,
	output reg [7:0] rx_data
);

localparam RX_PERIOD = `CLK_IN_HZ / `BAUD_RATE - 1;

reg [15:0] rx_period;
reg [3:0] rx_position;
reg [9:0] rx_byte;
reg rxd_reg;
reg last_rxd;
reg	rx_busy;
reg rx_last_busy;

wire rx_trigger;
assign rx_trigger = ~rxd_reg && last_rxd && ~rx_busy;

always @ (posedge clk) begin
	if (rst) begin
		rx_period <= 16'h0;
		rx_position <= 4'h0;
		rx_byte <= 10'h0;
		rxd_reg <= 1'h0;
		last_rxd <= 1'h0;
		rx_busy <= 1'h0;
		rx_last_busy <= 1'h0;
	end
	else begin
		rxd_reg <= rxd;
		last_rxd <= rxd_reg;

		rx_last_busy <= rx_busy;
		rx_rdy <= rx_last_busy && ~rx_busy;

		if (rx_trigger) begin
			rx_period <= RX_PERIOD[15:0] >> 1;
			rx_busy <= 1'd1;
			rx_position <= 4'h9;
		end
		else begin
			if (rx_period == 0) begin
					rx_period <= RX_PERIOD[15:0];
					if (rx_position != 0) begin
						rx_position <= rx_position - 1'd1;
						rx_byte[9] <= rxd_reg;
						rx_byte[8:0] <= rx_byte[9:1];
					end
					else begin
						rx_data <= rx_byte[9:2];
						rx_busy <= 1'b0;
					end
			end
			else
				rx_period <= rx_period - 1'b1;
		end
	end
end

endmodule

module de2_115
(
  input  wire        CLOCK_50, // Clock
  input  wire [17:0] SW,       // Switches
  input  wire [3:0]  KEY,      // Buttons, 1 when unpressed
  output wire [17:0] LEDR,     // Red leds
  output wire [8:0]  LEDG,     // Green leds
  output wire [6:0]  HEX0,     // 7-segment displays
  output wire [6:0]  HEX1,
  output wire [6:0]  HEX2,
  output wire [6:0]  HEX3,
  output wire [6:0]  HEX4,
  output wire [6:0]  HEX5,
  output wire [6:0]  HEX6,
  output wire [6:0]  HEX7,
  output TXD
);

wire clk;
assign clk = CLOCK_50;

wire [7:0] val;
assign val = SW[7:0]; 
 
wire rst_pushed;
assign rst_pushed = ~KEY[0];

wire is_tx;
assign is_tx = SW[8];

wire send_pushed;
key_pushed send_key_pushed
(
	.clk(clk),
	.key(KEY[1]),
	.pushed(send_pushed)
);

wire tx_busy;
rs232_uart_tx rs232_uart_tx
(
	.clk(clk),
	.rst(rst_pushed),
	.send(send_pushed),
	.tx_busy(tx_busy),
	.tx_data(val),
	.txd(TXD)
);

wire rx_rdy;
wire [7:0] rx_data;
rs232_uart_rx rs232_uart_rx
(
	.clk(clk),
	.rst(rst_pushed),
	.rxd(RXD),
	.rx_rdy(rx_rdy),
	.rx_data(rx_data)
);

reg [7:0] mem;
always @(posedge clk) begin
	if(rst_pushed)
		mem <= 8'h0;
	else if (rx_rdy)
		mem <= rx_data;
end

num2seg num2segValL
(
	.num(val[3:0]),
	.seg(HEX6)
);

num2seg num2segValH
(
	.num(val[7:4]),
	.seg(HEX7)
);

num2seg num2segMemL
(
	.num(mem[3:0]),
	.seg(HEX4)
);

num2seg num2segMemH
(
	.num(mem[7:4]),
	.seg(HEX5)
);

endmodule