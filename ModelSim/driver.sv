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
logic [7:0] write_data; // multiplexed in state machine between db_buffer and read_reg
reg [7:0] read_reg; // will latch receive buffer on rda and send back to transmit buffer
reg read_en;
 
typedef enum reg [2:0] {DB_LOW_LOAD, DB_HIGH_LOAD, IDLE, READ, WRITE} state_t;
state_t state, next_state;

// tristate databus on read operations or when not selected
assign databus = (iocs & ~iorw) ? write_data : 8'bz;

// TODO: MAKE SURE LOADED IN VALUES ARE CORRECT
always_comb begin
	case(br_cfg)
		2'b00 : db_buffer = 16'd1042; // 
		2'b01 : db_buffer = 16'd521;
		2'b10 : db_buffer = 16'd260;
		2'b11 : db_buffer = 16'd130;
	endcase
end

// read register
always @(posedge clk, negedge rst) begin
	if (!rst) 
		read_reg <= 8'hxx; // don't care whats there on reset
	else if (read_en) // latch databus on read signal
		read_reg <= databus;
	else
		read_reg <= read_reg; // intentional latch
end

// state flop
always_ff @(posedge clk, negedge rst) begin
	if (!rst) 
		state <= DB_LOW_LOAD;
	else
		state <= next_state;
end

// TODO: we could make this more robust with tbr/rda signals
always_comb begin
	next_state = DB_LOW_LOAD; // default state
	iocs = 1'b0;
	iorw = 1'b0;
	ioaddr = 2'b00;
	read_en = 1'b0;
	
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
				next_state = IDLE;
			end
				
		IDLE: // this state should wait for rx input and then echo it back on txd for demo
			begin
				if (rda) begin // signal read to put receive buffer on databus, read next cycle
					iocs = 1'b1;
					iorw = 1'b1;
					ioaddr = 2'b00;
					next_state = READ;
				end
				else
					next_state = IDLE;
			end
		READ:
			begin
				read_en = 1'b1; // latch databus (may need to be in previous state
				next_state = WRITE;
			end
		WRITE:
			begin
				iocs = 1'b1;
				iorw = 1'b0;
				ioaddr = 2'b00;
				write_data = read_reg;
				next_state = IDLE;
			
			end
	endcase
end

endmodule
