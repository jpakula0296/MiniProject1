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
 
 reg [15:0] db_buffer;
 
// instatntiate SPART
spart_DUT iDUT(.clk(clk), .rst(rst), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));

// TODO: load starting divison buffer values on reset
always_ff @(posedge clk, negedge rst) begin
	if (!rst) begin
		case(br_cfg)
			2'b00: 
				begin
				
				end
			2'b01:
				begin
								// TODO: assign db_buffer to different values depending on the br_cfg
				end
			2'b10:
				begin
				
				end
			2'b11:
				begin
				
				end
		endcase
	
	end


end

always @(negedge rst) begin
	iocs = 1'b0;
	iorw = 1'b0;
	ioaddr = 2'b10;  //division buffer low to start
	databus = 8'b0;
	
	repeat(2) @(negedge clk);
	
	databus = db_buffer[7:0];
	
	repeat(2) @(negedge clk);
	
	iocs = 1'b1;
	
	repeat(2) @(negedge clk);
	
	iocs = 1'b0;
	ioaddr = 2'b11;
	databus = db_buffer[15:8]
	
	repeat(2) @(negedge clk);

	iocs = 1'b1;

	repeat(2) @(negedge clk);
	
	iocs = 1'b0;
	ioaddr = 2'b00;
	databus = 8'b01101101;
	
	repeat(2) @(negedge clk);
	
	iocs = 1'b1;
	while(!tbr);
	
	repeat(15) @(negedge clk);
	
	iocs = 1'b0;
	iorw = 1'b1;
	databus = 8'bzzzzzzzz;
	
	repeat(2) @(negedge clk);
	
	iocs = 1'b1;
	while(!rda);

	repeat(2) @(negedge clk);
	
	$stop;



end	

endmodule
