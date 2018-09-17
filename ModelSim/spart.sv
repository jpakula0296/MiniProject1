//////////////////////////////////////////////////////////////////////////////////
// Company: UW Madison
// Engineer: Jesse Pakula
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
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
module spart(
    input clk,
    input rst,
    input iocs,  // I/O chip select, basically enable in this project
    input iorw,	 // I/O Read Not Write bit
	input rx_rdy, // from rx module, receive buffer latches shift reg on this signal
	input [9:0] rx_shift_reg, // connected from rx module, latched when rx_rdy goes high
	output logic [7:0] transmit_buffer, // tx module will latch this after write operation to it
	output logic tx_begin, // kicks off transmission when it goes high

	// currently have rx and tx modules handling these but not sure if that will screw up things in demo
    input rda,  // receive data available right when rx module signal rx_rdy
    input tbr,  // transmit buffer ready
	
	output logic [15:0] divisor_buffer, // this is needed by rx/tx modules
    input [1:0] ioaddr,
    inout [7:0] databus
    );
	
reg [7:0] division_buffer_low;
reg [7:0] division_buffer_high;
reg [7:0] receive_buffer;
reg [7:0] status;
reg [7:0] read_data; // multiplexed output of receive buffer and status reg for databus read (ioaddr)
reg [7:0] write_data; // multiplexed output of transmit buffer, DB(Low), and DB(High) based on ioaddr
					 
logic clr;
logic transmit_buffer_en = iocs & !iorw; // enables loading databus into transmission buffer
logic receive_buffer_en;  // enables receiving of data to begin from IO device
logic status_register_read;
logic status_read; // high when reading status register for rda and tbr

logic db_high_en;
logic db_low_en;

// Instantiate rx and tx modules
spart_rx rx_mod(
	.clk (clk),
	.rst (rst),
	.rxd (), // leave rxd unconnected since this comes from workstation, not connected to control
	.divisor_buffer (divisor_buffer), // connect directly
	.rda (rda),
	.rx_shift_reg (rx_shift_reg));
	
spart_tx tx_mod(
	.clk (clk),
	.rst (rst),
	.tx_begin (tx_begin),
	.transmit_buffer (transmit_buffer),
	.tbr (tbr),
	.divisor_buffer (divisor_buffer),
	.txd ()); // connected to workstation, not the control unit

// states for SPART
typedef enum reg [3:0] {IDLE, READ, WRITE} state_t;
state_t state, next_state;

// put receive buffer or status reg (depending on ioaddr) on databus if read op
// otherwise high z since SPART will be reading it
assign databus = (iorw) ? read_data : 8'bz;

// first bit of ioaddr is select signal for multiplexer, choosing between status reg and receive_buffer
assign read_data = (ioaddr[0]) ? status : receive_buffer;

// status register has rda at bit 0, tbr bit 1, 0s elsewhere.
assign status = {6'b000000, tbr, rda};

// DB_HIGH flop, only load it from data bus when enable signal goes high for 1 clk cycle
always_ff @(posedge clk, negedge rst) begin
	if(!rst)
		// TODO division buffer needs to load starting value based on DIP switches
		division_buffer_high <= 8'b0;
	else if(db_high_en)
		division_buffer_high <= databus;
	else
		division_buffer_high <= division_buffer_high;
end

// DB_LOW flop, only load on enable, otherwise hold value
always_ff @(posedge clk, negedge rst) begin
	if(!rst)
		// TODO load correct starting value based on switches.
		division_buffer_low <= 8'b0;
	else if(db_low_en)
		division_buffer_low <= databus;
	else
		division_buffer_low <= division_buffer_low;
end

assign divisor_buffer = {division_buffer_high[7:0], division_buffer_low[7:0]}; // concatenate for buffer

// receive_buffer latches rx_shift data bits when rx_tx_buf_full is asserted
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		receive_buffer <= 8'b0;
	else if (rda) // THIS MAY NEED TO BE DELAYED ONE CLOCK CYCLE
		receive_buffer <= rx_shift_reg[8:1]; // data bits in middle, start/stop bits on end
	else
		receive_buffer <= receive_buffer; // intentional latch
end

// transmit buffer loads in data from databus when ioaddr enables it
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		transmit_buffer <= 8'b0;
	else if (transmit_buffer_en)
		transmit_buffer <= databus;  
	else
		transmit_buffer <= transmit_buffer; // intentional latch
end


always @(posedge clk, negedge rst) begin
	receive_buffer_en = 1'b0;
	db_high_en = 1'b0;
	db_low_en = 1'b0;
	status_read = 1'b0;
	case(ioaddr)
		2'b00:  
			begin
				if(iorw)
					receive_buffer_en <= 1'b1;
			end
		2'b01:  
			begin
				if(iorw)
					status_read = 1'b1;
				else
					;// nothing
			end
		2'b10:		
			begin
				db_low_en = 1'b1;
			end
		2'b11:
			begin
				db_high_en = 1'b1;
			end
	endcase
end

always_comb begin
	next_state = IDLE; // default state
	tx_begin = 1'b0;
	transmit_buffer_en = 1'b0;
	
	case(state)
	
		IDLE:
			begin
				if (iocs & !iorw)
					next_state = WRITE;
				else
					next_state = IDLE;
			end
			
		READ:  
			begin
				
			
			
			end
			
		WRITE:
			begin 
				
			
			
			end
		
	endcase
end

endmodule
