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
    output logic iocs,
    output logic iorw,
    input rda,
    input tbr,
    output logic [1:0] ioaddr,
    inout [7:0] databus
    );
 
 reg [15:0] db_buffer;
 reg [7:0] write_data;
 
// instatntiate SPART
spart iDUT(.clk(clk), .rst(rst), .iocs(iocs), .iorw(iorw), .rda(rda), .tbr(tbr), .ioaddr(ioaddr), .databus(databus), .txd(txd), .rxd(rxd));

typedef enum reg [1:0] {DB_LOW_LOAD, DB_HIGH_LOAD, RUNNING} state_t;
state_t state, next_state;

// tristate databus on read operations or when not selected
assign databus = (iocs & ~iorw) ? write_data : 8'bz;

// TODO: MAKE SURE LOADED IN VALUES ARE CORRECT
always_comb begin
	case(br_cfg)
		2'b00 : db_buffer = 16'd5208;
		2'b01 : db_buffer = 16'd2604;
		2'b10 : db_buffer = 16'd1302;
		2'b11 : db_buffer = 16'd651;
	endcase
end
	

// state flop
always_ff @(posedge clk, negedge rst) begin
	if (!rst) 
		state <= DB_LOW_LOAD;
	else
		state <= next_state;
end

always_comb begin
	next_state = DB_LOW_LOAD; // default state
	iocs = 1'b0;
	iorw = 1'b0;
	ioaddr = 2'b00;
	
	
	case(state)
		DB_LOW_LOAD: // first thing we do is load division buffer values
			begin
				iocs = 1'b1; // select spart
				iorw = 1'b0; // performing write operation
				ioaddr = 2'b10; // address is db_low
				write_data = db_buffer[7:0]; // put lower 8 bits of db_buffer on databus
				next_state = DB_HIGH_LOAD;
			end
			
		DB_HIGH_LOAD: // load high bits of divisor buffer
			begin
				iocs = 1'b1;
				iorw = 1'b0;
				ioaddr = 2'b11; // address for db_high
				write_data = db_buffer [15:8];
				next_state = RUNNING;
			end
				
		RUNNING: 
			begin
				next_state = RUNNING;
			
			end
	endcase
end

			/*
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
	databus = db_buffer[15:8];
	
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
*/
endmodule
