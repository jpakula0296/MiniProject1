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

// BAUD RATE CALCULATONS
// 4800 = 1042 clocks
// 9600 = 521 clocks
// 19200 = 260 clocks
// 38400 = 130 clocks


// TODO: load starting divison buffer values on reset
always_ff @(posedge clk, negedge rst) begin
	if (!rst) begin
		case(br_cfg)
			2'b00: 
				begin
					databus <= 16'h0412;
				end
			2'b01:
				begin
					databus <= 16'h0209;
				end
			2'b10:
				begin
					databus <= 16'h0104;
				end
			2'b11:
				begin
					databus <= 16'h0082;
				end
		endcase
	
	end
	else
		databus = db_buffer[15:8];

end

always @(*) begin
	



end	

endmodule
