//////////////////////////////////////////////////////////////////////////////////
// Company: UW Madison
// Engineer: Jesse Pakula
// 
// Create Date:   
// Design Name: 
// Module Name:    spart_rx 
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
module spart_rx(
    input clk,
    input rst,
	input rxd,
	input [15:0] divisor_buffer, // determinces baud rate, loaded from control on power-cycle
    output logic rda,  // receive data available
	output logic [9:0] rx_shift_reg
    );
	
reg [15:0] baud_cnt;
reg [15:0] rx_middle;
reg [15:0] rx_middle_cnt;
reg [3:0] bit_cnt;
					 
logic baud_empty;
logic baud_cnt_en;
logic rx_shift_en;
logic clr;
logic middle_found; // for checking we are at rxd line
logic rx_middle_en;
logic rx_buf_full;


// states for rx transmission
typedef enum reg [2:0] {IDLE, RX_FRONT_PORCH, RX} state_t;
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
assign baud_empty = (baud_cnt == 16'h0000); // baud_empty when baud_cnt is 0 


assign rx_middle = divisor_buffer >> 1'b1; // will sample in middle of bits (divide by 2)

// counter to determine middle_found for correct sampling of rx
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_middle_cnt <= rx_middle;
	else if (rx_middle_en)
		rx_middle_cnt <= rx_middle_cnt - 16'b1;
	else 
		rx_middle_cnt <= rx_middle; 
end
assign middle_found = (rx_middle_cnt == 0);

// rx bit counter, include start and stop bits.
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		bit_cnt <= 4'hA; // always start at 10 for start bit, 8 data, then stop bit
	else if (rx_shift_en)
		bit_cnt <= bit_cnt - 4'h1; // count down on enable so we know when byte frame ends
	else if (rx_buf_full)
		bit_cnt <= 4'hA; // reload bit counter every time our buffer is full
	else
		bit_cnt <= 4'hA; // reload 10 when enable goes low
end
assign rx_buf_full = (bit_cnt == 4'h0); // signal buffer is full after stop bit



// rx_shift_reg implementation
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_shift_reg <= 10'b0;  // 0 on reset
	else if (rx_shift_en)
		rx_shift_reg <= {rxd, rx_shift_reg[9:1]}; // shift rxd from left if enable high
	else 
		rx_shift_reg <= rx_shift_reg; // intentional latch
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
	rx_middle_en = 1'b0;
	rx_shift_en = 1'b0;
	baud_cnt_en = 1'b0;
	rda = 1'b0;
	
	case(state)
	
		IDLE:
			begin
				if (!rxd) // should respond to getting data no matter what, getting data supercedes receiving
					next_state = RX_FRONT_PORCH;
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
				else if (rx_buf_full) begin
					if (rx_shift_reg[9]) begin // check that stop bit was high
						 rda = 1'b1;   // receive buffer in control module will latch shift reg in receive buffer
						next_state = IDLE; // done processing this byte
					end
				
					else
						next_state = IDLE; // don't signal rda if stop bit wasn't high
				end
				else
					next_state = RX;
			end
						
	endcase
end

endmodule
