// Jesse Pakula & Blake Vandercar
// ECE 551 Excercise 8

// UART rxdreciever testbench
module spart_rx_tb();

// declare all signals we will manipulate as type reg
reg clk, rst, iocs, iorw;
reg [1:0] ioaddr;
reg rxd;
logic [7:0] databus;

wire rda;
reg [7:0] correct_value;

parameter baud_clk = 2604;
parameter DB_LOW = 8'b00001111; // no idea what this should be yet
parameter DB_HIGH = 8'b00001111;

// instantiate DUT
spart control_DUT(
	.clk (clk),
	.rst (rst),
	.iocs (iocs),
	.iorw (iorw),
	.rx_shift_reg (rx_shift_reg),
	.transmit_buffer (transmit_buffer),
	.tx_begin (tx_begin),
	.rx_done (rx_done),
	.rda (rda),
	.tbr (tbr),
	.divisor_buffer (divisor_buffer),
	.ioaddr (ioaddr),
	.databus (databus),
	.rxd(rxd),
	.txd(txd)
	);

spart_rx rx_DUT(
	.clk (clk),
	.rst (rst),
	.rxd (rxd),
	.divisor_buffer (divisor_buffer),
	.rx_done (rx_done),
	.rx_shift_reg (rx_shift_reg)
	);
	
spart_tx tx_DUT(
	.clk (clk),
	.rst (rst),
	.tx_begin (tx_begin),
	.transmit_buffer (transmit_buffer),
	.divisor_buffer (divisor_buffer),
	.tbr (tbr),
	.txd (txd)
	);


initial begin
//////////////////////////////////  LOAD DIVISION BUFFER  /////////////////////
	clk = 1'b0;		
	rst = 1'b0; // start in reset
	iocs = 1'b0; 
	iorw = 1'b0; // write operation
	ioaddr = 2'b10; // load DB_Low first
	databus = DB_LOW;
	
	repeat (3) @(posedge clk);
	rst = 1'b1; // come out of reset
	repeat (3) @(posedge clk);
	iocs = 1'b1; // assert chip select to begin loading division buffer values
	repeat (2) @(posedge clk); // wait for write to occur
	ioaddr = 2'b11; // load DB_HIGH next
	databus = DB_HIGH;
	repeat (2) @(posedge clk); // wait for write to occur
	iocs = 1'b0; // deselect the system
	databus = 8'bz; // high z databus
	
	$stop;

	
///////////////////////// RX TEST //////////////////////////////////////////////
	
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

/*
always @(posedge clk) begin
	if (rda) begin
		if (databus == correct_value)
			$display("databus=%h , correct value=%h, PASS",databus,correct_value);
		else
			$display("databus=%h , correct value=%h, FAIL",databus,correct_value);
	end
end
*/

always begin
	#1 clk = ~clk;		// period 2 clock
end


endmodule 