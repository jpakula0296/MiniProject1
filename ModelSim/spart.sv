//////////////////////////////////////////////////////////////////////////////////
// Company: UW Madison
// Engineer: 
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
    output logic rda,  // read data available
    output logic tbr,  // 
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );
	
reg [15:0] baud_cnt;
reg [7:0] division_buffer_low;
reg [7:0] division_buffer_high;
reg [15:0] divisor_buffer;
reg [10:0] rx_shift_reg;
reg [15:0] rx_middle;
reg [15:0] rx_middle_cnt;
reg [3:0] rx_receive_cnt;
reg [7:0] receive_buffer;
reg [7:0] status;
logic baud_empty;
logic baud_cnt_en;
logic rx_shift_en;
logic tx_shift_en;
logic clr;
logic middle_found; // for checking we are at rxd line
logic rx_middle_en;
logic rx_receive_en;
logic rx_buf_full;


// states for SPART
typedef enum reg [2:0] {IDLE, RX_FRONT_PORCH, RX, RX_BACK_PORCH, TX, BUFFER_WRITE} state_t;
state_t state, next_state;
	
// BAUD RATE CALCULATONS
// 4800 = 1042 clocks
// 9600 = 521 clocks
// 19200 = 260 clocks
// 38400 = 130 clocks

// count down divisor buffer
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		baud_cnt <= divisor_buffer;
	else if (baud_empty)
		baud_cnt <= divisor_buffer;
	else if (baud_cnt_en)
		baud_cnt <= baud_cnt - 16'b1;  // only count if enable is on
	else
		baud_cnt <= divisor_buffer;	// if we stop counting we want to reset to 0
end


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
		rx_receive_cnt <= 4'hA;
	else if (rx_receive_en)
		rx_receive_cnt <= rx_receive_cnt - 4'b1;
	else
		rx_receive_cnt <= 4'hA;
end
assign rx_buf_full = (rx_receive_cnt == 4'h0);


// rx_shift_reg implementation
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		rx_shift_reg <= 10'b0;  // 0 on reset
	else if (rx_shift_en)
		rx_shift_reg <= {rxd, rx_shift_reg[9:1]}; // shift in rxd if enable high
	else 
		rx_shift_reg <= rx_shift_reg; // intentional latch
end

// receive_buffer latches rx_shift data bits when rx_buf_full is asserted
always_ff @(posedge clk, negedge rst) begin
	if (!rst)
		receive_buffer <= 8'b0;
	else if (rx_buf_full)
		receive_buffer <= rx_shift_reg[8:1];
	else
		receive_buffer <= receive_buffer; // intentional latch
end


// rx_shift_en is HIGH in middle of bit being sent: sample in middle of signal
// assign rx_shift_en = middle of bit being sent

// TODO set default signal values

always_comb begin
	next_state = IDLE; // default state
	rx_middle_en = 1'b0;
	rx_shift_en = 1'b0;
	tx_shift_en = 1'b0;
	baud_cnt_en = 1'b0;
	rda = 1'b0;
	
	case(state)
	
		IDLE:
			begin
				if (rxd == 1'b0 && iocs == 1'b1) // only come out of IDLE if chip select is high
				
					next_state = RX_FRONT_PORCH;
					
				else
					next_state = IDLE;
			
			end
			
		RX_FRONT_PORCH:
			begin
				rx_middle_en = 1'b1; // might need to have this in previous state on transition too.
				if (middle_found) begin
					rx_shift_en = 1'b1;
					next_state = RX;
				end
				else
					next_state = RX_FRONT_PORCH;
			end
		
					
		RX:
			begin
				baud_cnt_en = 1'b1;
				if (rx_buf_full) // receive buffer automatically latches on this signal
					
					next_state = RX_BACK_PORCH;
				else
					next_state = RX;
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
