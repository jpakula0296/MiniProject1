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
	input [9:0] rx_shift_reg, // connected from rx module, latched when rx_done goes high
	output logic [7:0] transmit_buffer, // tx module will latch this after write operation to it
	output logic tx_begin, // kicks off transmission when it goes high

	input rx_done, // from rx module, latch shift reg in receive buffer and put rda high when asserted
    output logic rda,  // receive data available right when rx module signal rx_done
    input tbr,  // transmit buffer ready
	
	output logic [15:0] divisor_buffer, // this is needed by rx/tx modules
    input [1:0] ioaddr,
    inout [7:0] databus,
	
	// not sure how to handle having these lines in different modules with the wrapper
	// just leaving them as are for now
	input rxd,
	output txd

    );
	
reg [7:0] division_buffer_low;
reg [7:0] division_buffer_high;
reg [7:0] receive_buffer;
reg [7:0] status;
reg [7:0] read_data; // multiplexed output of receive buffer and status reg for databus read (ioaddr)
					 
logic clr;
logic receive_buffer_en;  // enables receiving of data to begin from IO device
logic status_register_read;
logic status_read; // high when reading status register for rda and tbr



// wire write_data [7:0]; // for reading from databus on write operations

// Instantiate rx and tx modules
spart_rx rx_mod(
	.clk (clk),
	.rst (rst),
	.rxd (rxd), // leave rxd unconnected since this comes from workstation, not connected to control
	.divisor_buffer (divisor_buffer), // connect directly
	.rx_done (rx_done),
	.rx_shift_reg (rx_shift_reg));
	
spart_tx tx_mod(
	.clk (clk),
	.rst (rst),
	.tx_begin (tx_begin),
	.transmit_buffer (transmit_buffer),
	.tbr (tbr),
	.divisor_buffer (divisor_buffer),
	.txd (txd)); // connected to workstation, not the control unit

// states for SPART
typedef enum reg [1:0] {IDLE, RECEIVE_READ, TRANSMIT_WRITE} state_t;
state_t state, next_state;

// put receive buffer or status reg (depending on ioaddr) on databus if read op
// otherwise high z since SPART will be reading it
assign databus = (iorw) ? read_data : 8'bz;
// assign write_data = databus [7:0];

assign divisor_buffer = {division_buffer_high[7:0], division_buffer_low[7:0]}; // concatenate for buffer


// first bit of ioaddr is select signal for multiplexer, choosing between status reg and receive_buffer
assign read_data = (ioaddr[0]) ? status : receive_buffer;

// status register has rda at bit 0, tbr bit 1, 0s elsewhere.
assign status = {6'b000000, tbr, rda};


// DB_HIGH flop, only load it from data bus when enable signal goes high for 1 clk cycle
always_ff @(posedge clk, negedge rst) begin
	if(!rst)
		division_buffer_high <= 8'b0;
	else if((ioaddr == 2'b11) && iocs && !iorw)
		division_buffer_high <= databus;
	else
		division_buffer_high <= division_buffer_high;
end

// DB_LOW flop, only load on enable, otherwise hold value
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		division_buffer_low <= 8'b0;
	else if (ioaddr[1] & ~ioaddr[0] & iocs & ~iorw)
		division_buffer_low <= databus;
	else
		division_buffer_low <= division_buffer_low;
end


// transmit buffer loads in data from databus when ioaddr enables it
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		transmit_buffer <= 8'b0;
	else if ((ioaddr == 2'b00) && iocs && !iorw && tbr)
		transmit_buffer <= databus;  
	else
		transmit_buffer <= transmit_buffer; // intentional latch
end


// receive_buffer latches rx_shift data bits when rx_tx_buf_full is asserted
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		receive_buffer <= 8'b0;
	else if (rx_done)
		receive_buffer <= rx_shift_reg[8:1]; // data bits in middle, start/stop bits on end
	else
		receive_buffer <= receive_buffer; // intentional latch
end

// rda high for one clock cycle when we latch rx_shift_reg
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rda <= 1'b0;
	else if (rx_done)
		rda <= 1'b1;
	else 
		rda <= 1'b0;
end

endmodule

