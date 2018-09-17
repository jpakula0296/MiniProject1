// Jesse Pakula & Blake Vandercar
// ECE 551 Excercise 8

// UART rxdreciever testbench
module spart_rx_tb();

// declare all signals we will manipulate as type reg
reg clk, rst, iocs, iorw;
reg [1:0] br_cfg;
reg [1:0] ioaddr;
reg rxd;

wire rda;
wire [7:0] databus;

reg [7:0] correct_value;

parameter baud_clk = 2604;

// instantiate DUT
spart_DUT iDUT(.clk(clk), .rst(rst), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));
driver_DUT dDUT(.clk(clk), .rst(rst), .br_cfg(br_cfg), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));

initial begin
	clk = 1'b0;		// start with reset asserted
	rst = 1'b0;
	
	repeat (3) @(negedge clk);
	
	rst = 1'b1;	// de-assert reset
	rxd= 1'b1;
	repeat(baud_clk*3) @(negedge clk);	// delay start bit assertion
	
	// transmit h'A5 as in example
	correct_value = 8'hA5;
	//start bit
	rxd= 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 10100101
	rxd= 1'b1;
	repeat(baud_clk) @(negedge clk);
	rxd= 1'b0;
	repeat(baud_clk) @(negedge clk);
	rxd= 1'b1;
	repeat(baud_clk) @(negedge clk);
	rxd= 1'b0;
	repeat (baud_clk*2) @(negedge clk);
	rxd= 1'b1;
	repeat (baud_clk) @(negedge clk);
	rxd= 1'b0;
	repeat (baud_clk) @(negedge clk);
	rxd= 1'b1;
	repeat (baud_clk) @(negedge clk);
	// stop bit
	rxd= 1'b1;
	repeat (baud_clk*3) @(negedge clk);
	
	// transmit h'E7 as in example
	correct_value = 8'hE7;
	//start bit
	rxd= 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 11100111
	rxd= 1'b1;
	repeat(baud_clk*3) @(negedge clk);
	rxd= 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rxd= 1'b1;
	repeat(baud_clk*3) @(negedge clk);
	// stop bit
	rxd= 1'b1;
	repeat (baud_clk) @(negedge clk);
	
	// transmit h'24 as in example
	correct_value = 8'h24;
	//start bit
	rxd= 1'b0;
	repeat(baud_clk) @(negedge clk);
	// 00100100
	rxd= 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rxd= 1'b1;
	repeat(baud_clk) @(negedge clk);
	rxd= 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	rxd= 1'b1;
	repeat (baud_clk) @(negedge clk);
	rxd= 1'b0;
	repeat(baud_clk*2) @(negedge clk);
	// stop bit
	rxd= 1'b1;
	repeat (baud_clk) @(negedge clk);
$stop;


end

always @(posedge clk) begin
	if (rda) begin
		if (databus == correct_value)
			$display("databus=%h , correct value=%h, PASS",databus,correct_value);
		else
			$display("databus=%h , correct value=%h, FAIL",databus,correct_value);
	end
end

always begin
	#1 clk = ~clk;		// period 2 clock
end


endmodule 