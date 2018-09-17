module uart_tx_tb();
	reg clk,rst_n;
	reg tx_start;
	reg [7:0]tx_data;
	wire tx, tx_rdy;
	
	parameter baud_clk  = 2604; 
	
	uart_tx_DUT iDUT(.clk(clk), .rst_n(rst_n), .tx_start(tx_start), .tx_data(tx_data), .tx_rdy(tx_rdy), .tx(tx));
	
	initial begin
		clk = 1'b0;
		rst_n = 1'b0;
		tx_data = 8'b11001100;
		tx_start = 1'b0;
		
		repeat (5) @(posedge clk);
		
		rst_n = 1'b1;
		repeat (5) @(posedge clk);
		
		tx_start = 1'b1;
		repeat (1) @(posedge clk);
		tx_start = 1'b0;
		repeat (baud_clk*15) @(posedge clk);
		
		tx_data = 8'b10100111;
		tx_start = 1'b1;
		repeat (1) @(posedge clk);
		tx_start = 1'b0;
		repeat (baud_clk*15) @(posedge clk);
		
		$stop;
	end
	
	always begin
		#1 clk = ~clk;
	end
endmodule
