// Jesse Pakula & Blake Vandercar
// ECE 551 Excercise 8

// UART RX reciever testbench
module spart_rx_tb();

// declare all signals we will manipulate as type reg
reg clk, rst, iocs, iorw;
reg [1:0] br_cfg;
reg [1:0] ioaddr;

wire rx_rdy;
wire [7:0] rx_data;

reg [7:0] correct_value;

parameter baud_clk = 2604;

// instantiate DUT
spart_DUT iDUT(.clk(clk), .rst(rst), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));
driver_DUT dDUT(.clk(clk), .rst(rst), .br_cfg(br_cfg), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));

initial begin
	clk = 1'b0;		// start with reset asserted
	rst = 1'b0;
	
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