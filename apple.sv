// module for generating the apple for the snake game
// inputs:
// 	update - signal to generate a new apple
// 	randNum - random number for choosing the location for the new apple
// 	SnPos - packed array [15:0][15:0] represeting the location of the snake
// 	reset - resets the apple location
// 	clk - fast clock 
// outputs:
// 	Aplpos - packed array [15:0][15:0] represeting the location of the apple
module apple (update, randNum, SnPos, AplPos, reset, clk);
	input logic [7:0] randNum;
	input logic [15:0][15:0] SnPos;
	input logic update, clk, reset;
	output logic [15:0][15:0] AplPos;

	logic [3:0] outX, outY;
	logic PUpdate, search;
	
	always_ff @(posedge clk) begin
		if(reset) begin
			outX <= 4'b1111;
			outY <= 4'b1111;
			search <= 1'b0;
			PUpdate <= 1'b0;
		end else begin
			PUpdate <= update;
			
			if(update && !PUpdate) search <= 1'b1;
			
			if(search) begin
				if(SnPos[randNum[7:4]][randNum[3:0]] == 1'b0) begin
					outY <= randNum[7:4];
					outX <= randNum[3:0];
					search <= 1'b0;
				end
			end
		end
	end
	
	always_comb begin
		AplPos = '0;
		AplPos[outY][outX] = 1'b1;
	end	

endmodule

module apple_testbench();
	logic update, clk, reset;
	logic [15:0][15:0] SnPos, AplPos;
	logic [7:0] randNum;
	
	apple dut (.update, .randNum, .SnPos, .AplPos, .reset, .clk);
	
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;	// Forever toggle the clock
	end
	
	initial begin
	reset <= 1;
	update <= 0;
	randNum <= 8'b00000000;
	SnPos <= '0;
	@(posedge clk);
	@(posedge clk);
	reset <= 0;
	@(posedge clk);
	
	//1
	randNum <= 8'b00100011;
	update <= 1; @(posedge clk);
	update <= 0; @(posedge clk);
	@(posedge clk);
	
	//2
	SnPos <= '0;
	SnPos[4][5] <= 1'b1;
	
	randNum <= 8'b01000101;   // (4,5) occupied
	update <= 1; @(posedge clk);
	update <= 0; @(posedge clk);

	randNum <= 8'b01100111;   // (6,7)
	@(posedge clk);
	@(posedge clk);
	
	//3
	SnPos <= '0;
	SnPos[1][1] <= 1'b1;
	SnPos[2][2] <= 1'b1;
	SnPos[3][3] <= 1'b1;

	randNum <= 8'b00010001;   // (1,1)
	update <= 1; @(posedge clk);
	update <= 0; @(posedge clk);

	randNum <= 8'b00100010;   // (2,2)
	@(posedge clk);

	randNum <= 8'b00110011;   // (3,3)
	@(posedge clk);

	randNum <= 8'b01000100;   // (4,4) free
	@(posedge clk);
	
	//4
	SnPos <= '0;
	SnPos[1][1] <= 1'b1;

	randNum <= 8'b00010001;
	update <= 1; @(posedge clk);   // rising edge here starts search

	randNum <= 8'b00100010;
	@(posedge clk);                // update still high, should NOT restart search

	randNum <= 8'b00110011;
	@(posedge clk);                // still high

	update <= 0; @(posedge clk);   // drop low after several cycles
	@(posedge clk);
	
	
	$stop;
	end
endmodule
