//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output iocs,
    output iorw,
    input rda,
    input tbr,
    output [1:0] ioaddr,
    inout [7:0] databus
    );

// instantiate DUT
	
	
initial begin
	clk = 1'b0;
	rst = 1'b0; // start in reset
	iocs = 1'b1; // don't select fpga yet
	iorw = 1'b1; // start with read operation
	ioaddr = 2'b00; // address is receive buffer
	
	
	
	
	

endmodule
