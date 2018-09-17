// Jesse Pakula & Blake Vandercar
// ECE 551 Excercise 8

// UART RX reciever testbench
module uart_rx_tb();

reg clk, rst_n, rx;

wire rx_rdy;
wire [7:0] rx_data;

reg [7:0] correct_value;

parameter baud_clk = 2604;

// instantiate DUT
uart_rx_DUT iDUT(.rx_data(rx_data), .rx_rdy(rx_rdy), .clk(clk), .rst_n(rst_n),.rx(rx));


initial begin
	clk = 1'b0;		// start with reset asserted
	rst_n = 1'b0;
	repeat (3) @(negedge clk);
	
	rst_n = 1'b1;	// de-assert reset
	rx = 1'b1;
	repeat(baud_clk*3) @(negedge clk);	// delay start bit assertion
	
	// transmit h'A5 as in example
	correct_value = 8'hA5;
	//start bit
	rx = 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 10100101
	rx = 1'b1;
	repeat(baud_clk) @(negedge clk);
	rx = 1'b0;
	repeat(baud_clk) @(negedge clk);
	rx = 1'b1;
	repeat(baud_clk) @(negedge clk);
	rx = 1'b0;
	repeat (baud_clk*2) @(negedge clk);
	rx = 1'b1;
	repeat (baud_clk) @(negedge clk);
	rx = 1'b0;
	repeat (baud_clk) @(negedge clk);
	rx = 1'b1;
	repeat (baud_clk) @(negedge clk);
	// stop bit
	rx = 1'b1;
	repeat (baud_clk*3) @(negedge clk);
	
	// transmit h'E7 as in example
	correct_value = 8'hE7;
	//start bit
	rx = 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 11100111
	rx = 1'b1;
	repeat(baud_clk*3) @(negedge clk);
	rx = 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rx = 1'b1;
	repeat(baud_clk*3) @(negedge clk);
	// stop bit
	rx = 1'b1;
	repeat (baud_clk) @(negedge clk);
	
	// transmit h'24 as in example
	correct_value = 8'h24;
	//start bit
	rx = 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 00100100
	rx = 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rx = 1'b1;
	repeat(baud_clk) @(negedge clk);
	rx = 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rx = 1'b1;
	repeat (baud_clk) @(negedge clk);
	rx = 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	// stop bit
	rx = 1'b1;
	repeat (baud_clk) @(negedge clk);
$stop;


end

always @(posedge clk) begin
	if (rx_rdy) begin
		if (rx_data == correct_value)
			$display("rx_data=%h , correct value=%h, PASS",rx_data,correct_value);
		else
			$display("rx_data=%h , correct value=%h, FAIL",rx_data,correct_value);
	end
end

always begin
	#1 clk = ~clk;		// period 2 clock
end


endmodule 