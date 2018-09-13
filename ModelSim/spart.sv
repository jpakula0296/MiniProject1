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
    output logic rda,  // receive data available
    output logic tbr,  // transmit buffer ready
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );
	
reg [15:0] baud_cnt;
reg [7:0] division_buffer_low;
reg [7:0] division_buffer_high;
reg [15:0] divisor_buffer;
reg [9:0] rx_shift_reg;
reg [9:0] tx_shift_reg;
reg [15:0] rx_middle;
reg [15:0] rx_middle_cnt;
reg [3:0] rx_tx_cnt;
reg [7:0] receive_buffer;
reg [7:0] transmit_buffer;
reg [7:0] status;
logic baud_empty;
logic baud_cnt_en;
logic rx_shift_en;
logic tx_shift_en;
logic clr;
logic middle_found; // for checking we are at rxd line
logic rx_middle_en;
logic rx_tx_cnt_en;
logic rx_tx_buf_full;
logic transmit_buffer_en; // enables loading databus into transmission buffer
logic receive_buffer_en;  // enables receiving of data to begin from IO device
logic tx_begin;  // enables loading transmission buffer into tx_shift_reg


// states for SPART
typedef enum reg [2:0] {IDLE, RX_FRONT_PORCH, RX, RX_BACK_PORCH, TX_LOAD, TX, BUFFER_WRITE} state_t;
state_t state, next_state;

// IO addr states
typedef enum reg [1:0] {RX_TX_BUFFER, STATUS_REGISTER, DB_LOW, DB_HIGH} io_state_t;
io_state_t io_state, next_io_state;
	

// count down divisor buffer
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		baud_cnt <= divisor_buffer;
	else if (baud_empty)
		baud_cnt <= divisor_buffer;
	else if (baud_cnt_en)
		baud_cnt <= baud_cnt - 16'b1;  // only count if enable is on
	else
		baud_cnt <= divisor_buffer;	// if we stop counting we want to reset to divisor buffer
end

// status register has rda at bit 0, tbr bit 1, 0s elsewhere.
assign status = {6'b000000, tbr, rda};

// TODO set up locations for division buffer info, needs to be writeable
// division buffer and baud rate signals
assign baud_empty = !(|baud_cnt); // baud_empty when baud_cnt is 0 
assign divisor_buffer = {division_buffer_high[7:0], division_buffer_low[7:0]}; // concatenate for buffer

// TODO find better way to sample in middle of rx line, division is expensive
assign rx_middle = divisor_buffer >> 1'b1; // will sample in middle of bits (divide by 2)
// counter to determine middle_found
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_middle_cnt <= rx_middle;
	else if (rx_middle_en)
		rx_middle_cnt <= rx_middle_cnt - 16'b1;
	else 
		rx_middle_cnt <= rx_middle; 
end
assign middle_found = (rx_middle_cnt == 0);

// rx bit counter 
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_tx_cnt <= 4'hA;
	else if (rx_tx_cnt_en)
		rx_tx_cnt <= rx_tx_cnt - 4'b1;
	else
		rx_tx_cnt <= 4'hA; // Don't we want this to latch and stay where it was?
end
assign rx_tx_buf_full = (rx_tx_cnt == 4'h0);


// rx_shift_reg implementation
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_shift_reg <= 10'b0;  // 0 on reset
	else if (rx_shift_en)
		rx_shift_reg <= {rxd, rx_shift_reg[9:1]}; // shift rxd from left if enable high
	else 
		rx_shift_reg <= rx_shift_reg; // intentional latch
end

// receive_buffer latches rx_shift data bits when rx_tx_buf_full is asserted
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		receive_buffer <= 8'b0;
	else if (rx_tx_buf_full)
		receive_buffer <= rx_shift_reg[8:1];
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

assign transmit_buffer_framed = {1'b1, transmit_buffer, 1'b0};  // framing the data for transmission

assign txd = tx_shift_reg[0];  // lsb will be consistently transmitted

// tx_shift_reg implementation
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		tx_shift_reg <= 10'b1111111111;  // all 1's on reset to hold txd high
	else if(tx_begin)
		tx_shift_reg <= transmit_buffer_framed;
	else if (tx_shift_en)
		tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
	else
		tx_shift_reg <= tx_shift_reg;  // intentional latch	
end

// rx_shift_en is HIGH in middle of bit being sent: sample in middle of signal
// assign rx_shift_en = middle of bit being sent

		//  Do we need to set up a state and next state for this?
		//  I feel like flopping the ioaddr input may cause problems


// TODO set default signal values
always_comb begin
	transmit_buffer_en = 1'b0;
	receive_buffer_en = 1'b0;
	case(ioaddr)
		RX_TX_BUFFER:  
			begin
				if(iorw)
					receive_buffer_en <= 1'b1;
				else
					transmit_buffer_en <= 1'b1;
			end
		STATUS_REGISTER:  
			begin
				if(iorw)
					// TODO status register
				else
			end
		DB_LOW:		
			begin
				// TODO DB_LOW
			end
		DB_HIGH:
			begin
				// TODO DB_HIGH
			end
	endcase
end

	

always_comb begin
	next_state = IDLE; // default state
	rx_middle_en = 1'b0;
	rx_shift_en = 1'b0;
	tx_shift_en = 1'b0;
	tx_begin = 1'b0;
	baud_cnt_en = 1'b0;
	rda = 1'b0;
	databus = 8'hzz; // high impedance on data bus until we have useful data
	
	case(state)
	
		IDLE:
			begin
				if (receive_buffer_en & !rxd & iocs ) // only come out of IDLE if chip select is high
					next_state = RX_FRONT_PORCH;
				
				else if (transmit_buffer_en & iocs)
					next_state = TX_LOAD;
				else
					next_state = IDLE;
			
			end
			
		RX_FRONT_PORCH:
			begin
				rx_middle_en = 1'b1; // might need to have this in previous state on transition too.
				if (middle_found) begin
					if (!rxd) begin // verify start bit is low
						rx_shift_en = 1'b1;
						next_state = RX; // start sampling data if we have low start bit
					end
					else 
						next_state = IDLE; // back to IDLE if start bit was not low
				end
				else
					next_state = RX_FRONT_PORCH;
			end
		
					
		RX:
			begin
				baud_cnt_en = 1'b1;
				if(baud_empty) begin
					rx_shift_en = 1'b1;
					next_state = RX;
				end
				else if (rx_tx_buf_full) // receive buffer automatically latches on this signal
					if (receive_buffer[9]) // check that stop bit was high
						next_state = RX_BACK_PORCH; // done processing this byte
					else
						next_state = IDLE; // go to IDLE if stop bit wasn't high
				else
					next_state = RX;
			end
			
		TX_LOAD: 
			begin
				tx_begin = 1'b1;
				next_state = TX;
			end
			
		TX:
			begin
				baud_cnt_en = 1'b1;
				if(baud_empty) begin
					tx_shift_en = 1'b1;
					next_state = TX;
				end
				else if(rx_tx_buf_full)
					next_state = IDLE;
				else
					next_state = TX;
					
			end
		// let processor know we have data ready
		RX_BACK_PORCH:
			begin
				rda= 1'b1;
				next_state = IDLE;
			end
			
		
				
	endcase
end

endmodule
