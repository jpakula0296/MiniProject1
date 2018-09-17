module spart_tx_tb();

	// declare all signals we will manipulate as type reg
	reg clk, rst, iocs, iorw;
	reg [1:0] br_cfg;
	reg [1:0] ioaddr;
	reg [7:0] databus;
	
parameter baud_clk = 2604;

	
	spart_DUT iDUT(.clk(clk), .rst(rst), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));
	driver_DUT dDUT(.clk(clk), .rst(rst), .br_cfg(br_cfg), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));
	
	initial begin
///////////////////////////////////////////////////////////////////////////////
//////////////// TRANSMIT TEST/////////////////////////////////////////////////
		clk = 1'b0;
		rst = 1'b0; // start in reset state
		iocs = 1'b0; // start low to keep off
		iorw = 1'b0; // low for write operation
		br_cfg = 2'b00;
		ioaddr = 2'b00; // receive/transmit buffer as address
		
		repeat (5) @(posedge clk);
		rst = 1'b1; // come out of reset
		
		repeat (5) @(posedge clk);
		iocs = 1'b1; 
		databus = 8'b11001100;
		// watch tx line to make sure we spit out this pattern
		
		repeat (1) @(posedge clk);
		
		repeat (baud_clk*15) @(posedge clk); // 
		$stop;
	end
	
	always begin
		#1 clk = ~clk;
	end
endmodule
