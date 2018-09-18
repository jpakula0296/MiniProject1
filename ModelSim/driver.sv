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
    input [1:0] br_cfg, // connected to switches, determine divisor for loading correct baud rate
    output logic iocs,  // chip select, SPART does nothing if this is low
    output logic iorw,  // read not write bit, databus is tristated based on this
    input rda,          // read data available, read from receive buffer when this goes high from SPART
    input tbr,				// transmit buffer ready, high when transmit buffer can receive new data
    output logic [1:0] ioaddr,
    inout [7:0] databus
    );
 
reg [15:0] db_buffer; // holds divisor buffer to be loaded to control module on reset
logic [7:0] write_data; // multiplexed in state machine between db_buffer and read_reg
logic [1:0] write_select; // determines which register we are writing too
reg read_en; 
reg [7:0] read_reg;
wire fifo_empty;

// fifo stuff that might fix junk data being sent occasionally
// reg [39:0] fifo; // holding 5 data bytes
// reg [2:0] fifo_cnt;

 
typedef enum reg [2:0] {DB_LOW_LOAD, DB_HIGH_LOAD, IDLE, WRITE} state_t;
state_t state, next_state;

// tristate databus on read operations or when not selected
assign databus = (iocs & ~iorw) ? write_data : 8'bz;

always_comb begin
	case(br_cfg)
		2'b00 : db_buffer = 16'd10416; // 38400 baud
		2'b01 : db_buffer = 16'd5208;  // 19200 baud
		2'b10 : db_buffer = 16'd2604;  // 9600 baud
		2'b11 : db_buffer = 16'd1302;  // 4800 baud
	endcase
end

// assign fifo_empty = (fifo_cnt == 3'h0);



// NOTE: below fifo stuff could fix issues with junk data being sent if we type too fast
/* fifo_cnt flop to keep track of when we have data to transmit
always @(posedge clk, negedge rst) begin
	if (!rst)
		fifo_cnt <= 3'h0;
	else if (read_en)
		fifo_cnt <= fifo_cnt + 1'b1;
	else if (write_en)
		fifo_cnt <= fifo_cnt - 1'b1;
	else 
		fifo_cnt <= fifo_cnt;
end
*/

// fifo implementation 
/*
always @(posedge clk, negedge rst) begin
	if (!rst) 
		fifo <= 40'h0000000000; // don't care whats there on reset
	else if (read_en) // latch databus on read signal
		fifo <= {fifo[31:0], databus};
	else if (write_en)
		fifo <= {8'h00, fifo[39:8]};
	else
		fifo <= fifo; // intentional latch
end
*/

// read_reg flop, latch databus when read_en is high, reading receive buffer from SPART
always @(posedge clk, negedge rst) begin
	if (!rst)
		read_reg <= 8'h00;
	else if (read_en)
		read_reg <= databus;
	else
		read_reg <= read_reg;
end



// write_data multiplexer
always_comb begin
	case(write_select)
		2'b00 : write_data = read_reg; // replace read_reg with fifo potentially
		2'b01 : write_data = db_buffer[7:0];  
		2'b10 : write_data = db_buffer[15:8];
		2'b11 : write_data = 8'h00;
	endcase
end

// state flop
always_ff @(posedge clk, negedge rst) begin
	if (!rst) 
		state <= DB_LOW_LOAD; // first thing we do is load divisor buffer
	else
		state <= next_state;
end

always begin
	next_state = DB_LOW_LOAD; // default state
	iocs = 1'b0; // don't do anything in IDLE
	iorw = 1'b0;
	ioaddr = 2'b00;
	read_en = 1'b0;
	write_select = 2'b00;
	
	case(state)
		DB_LOW_LOAD: // first thing we do is load division buffer values
			begin
				iocs = 1'b1; // select spart
				iorw = 1'b0; // performing write operation
				ioaddr = 2'b10; // address is db_low
				write_select = 2'b01; // put lower 8 bits of db_buffer on databus
				next_state = DB_HIGH_LOAD;
			end
			
		DB_HIGH_LOAD: // load high bits of divisor buffer
			begin
				iocs = 1'b1;
				iorw = 1'b0;
				ioaddr = 2'b11; // address for db_high
				write_select = 2'b10;
				next_state = IDLE;
			end

		IDLE: // this state should wait for rx input and then echo it back on txd for demo
			begin
				if (rda) begin // signal read to put receive buffer on databus, read next cycle
					iocs = 1'b1;
					iorw = 1'b1;
					ioaddr = 2'b00;
					read_en = 1'b1;
					next_state = WRITE;
				end
				else
					next_state = IDLE;
			end

		WRITE: // read_reg has latched recieve buffer, can transmit it now
			begin
				if (tbr) begin // only allow transmit if tbr is high, otherwise we overwrite data
					iocs = 1'b1;
					iorw = 1'b0;
					ioaddr = 2'b00;
					next_state = IDLE;
				end
				else
					next_state = WRITE;
			
			end
	endcase
end

endmodule
