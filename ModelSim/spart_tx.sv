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
module spart_tx(
    input clk,
    input rst,
	input tx_begin, // from rx module, receive buffer latches shift reg on this signal
	input [7:0] transmit_buffer, // tx module will latch this after write operation to it
	input  [15:0] divisor_buffer, // this is needed by rx/tx modules
	output logic tbr,
	output logic txd
	
    );
	
reg [15:0] baud_cnt;
reg [9:0] tx_shift_reg;
reg [3:0] bit_cnt;

					 
logic baud_empty;
logic baud_cnt_en;
logic tx_shift_en;
logic bit_cnt_en;
logic tx_buf_full;
logic latch_transmit_buffer;


// states for SPART
typedef enum reg {IDLE, TX} state_t;
state_t state, next_state;

// count down divisor buffer
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		baud_cnt <= divisor_buffer;
	else if (baud_empty)
		baud_cnt <= divisor_buffer;
	else if (baud_cnt_en)
		baud_cnt <= baud_cnt - 16'h0001;  // only count if enable is on
	else
		baud_cnt <= divisor_buffer;	// if we stop counting we want to reset to divisor buffer
end

// baud rate signal
assign baud_empty = (baud_cnt == 16'h0000); // baud_empty when baud_cnt is 0 

// tx bit counter, include start and stop bits.
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		bit_cnt <= 4'hA; // always start at 10 for start bit, 8 data, then stop bit
	else if (bit_cnt_en)
		bit_cnt <= bit_cnt - 4'h1; // count down on enable so we know when byte frame ends
	else if (tx_buf_full)
		bit_cnt <= 4'hA; // reload bit counter every time our buffer is full
	else
		bit_cnt <= bit_cnt; // intentional latch
end
assign tx_buf_full = (bit_cnt == 4'h0); // signal buffer is full after stop bit
assign bit_cnt_en =  tx_shift_en; // continue counting when bits are shifted


assign txd = tx_shift_reg[0];  // lsb will be consistently transmitted

// tx_shift_reg implementation, latch transmit buffer after tx_begin
// double flop tx_begin so we latch at the right time
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		latch_transmit_buffer <= 1'b0;
	else if (tx_begin)
		latch_transmit_buffer <= 1'b1;
	else 
		latch_transmit_buffer <= 1'b0;
end
		
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		tx_shift_reg <= 10'hFF;  // all 1's on reset to hold txd high
	else if(latch_transmit_buffer)
		tx_shift_reg <= {1'b1, transmit_buffer[7:0], 1'b0};
	else if (tx_shift_en)
		tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
	else
		tx_shift_reg <= tx_shift_reg;  // intentional latch	
end

// state flop
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		state <= IDLE;
	else
		state <= next_state;
end

always_comb begin
	next_state = IDLE; // default state
	tx_shift_en = 1'b0;
	baud_cnt_en = 1'b0;
	tbr = 1'b0; // transmit buffer not ready by default
	
	case(state)
	
		IDLE:
			begin
				if (tx_begin) // tx_shift reg automatically latches transmit buffer					
					next_state = TX;
				else
					next_state = IDLE;
					tbr = 1'b1; // buffer ready if we are IDLE
			end
			
		TX:
			begin
				
				baud_cnt_en = 1'b1;
				if(baud_empty) begin
					tx_shift_en = 1'b1;
					next_state = TX;
				end
				else if(tx_buf_full)
					next_state = IDLE;
					
				else
					next_state = TX;
					
			end	
	endcase
end

endmodule
