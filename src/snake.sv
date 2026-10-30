// module for running the snake game
// inputs:
// 	mov - movement direction for snake
// 	clk - fast clock
// 	GT - slow game tick
// 	reset - resets the game
// 	AplPos - packed array [15:0][15:0] represeting the location of the apple
// outputs:
//		ateApple - if the snake ate the apple
// 	gameOver - if the game is over
// 	SnPos - packed array [15:0][15:0] represeting the location of the snake
module snake (mov, clk, GT, reset, ateApple, gameOver, SnPos, AplPos);
	input logic clk, GT, reset;
	input logic [1:0] mov; //00 = right, 01 = left, 10 = up, 11 = down
	input logic [15:0][15:0] AplPos;
	
	output logic gameOver, ateApple;
	output logic [15:0][15:0] SnPos;
	
	logic [3:0] headX, headY, tailX, tailY, nextHeadX, nextHeadY, nextTailX, nextTailY;
	logic [15:0][15:0][1:0] dir;
	logic GONext, wCol, sCol, grow;
	logic [1:0] tailMovDir;
	logic [8:0] length;
	
	always_comb begin
		tailMovDir = dir[tailY][tailX];
		nextHeadX = headX;
		nextHeadY = headY;
		nextTailX = tailX;
		nextTailY = tailY;
		
		grow = 1'b0;
		
		wCol = 1'b0; sCol = 1'b0; GONext = 1'b0;
		
		case(mov)
			2'b00: begin
				if(headX == 4'b1111) wCol = 1'b1;
				else nextHeadX = headX + 4'b0001;
			end
			2'b01: begin
				if(headX == 4'b0000) wCol = 1'b1;
				else nextHeadX = headX - 4'b0001;
			end
			2'b10: begin
				if(headY == 4'b0000) wCol = 1'b1;
				else nextHeadY = headY - 4'b0001;
			end
			2'b11: begin
				if(headY == 4'b1111) wCol = 1'b1;
				else nextHeadY = headY + 4'b0001;
			end
		endcase
		
		grow = (AplPos[nextHeadY][nextHeadX] === 1'b1);
		
		sCol = SnPos[nextHeadY][nextHeadX] && !(nextHeadX == tailX && nextHeadY == tailY && !grow);
	
		GONext = wCol || sCol;
		
		case(tailMovDir) 
			2'b00: nextTailX = tailX + 4'b0001;
			2'b01: nextTailX = tailX - 4'b0001;
			2'b10: nextTailY = tailY - 4'b0001;
			2'b11: nextTailY = tailY + 4'b0001;
		endcase
	end
	
	
	always_ff @(posedge clk) begin
		if (reset) begin
			SnPos <= '0;
			dir <= '0;
			gameOver <= 1'b0;
			SnPos[0][0] <= 1'b1;
			headX <= 0;
			headY <= 0;
			tailX <= 0;
			tailY <= 0;
			ateApple <= 0;
			length <= 9'b000000001;
		end
		else begin
			ateApple <= 1'b0;
			
			if (GT && !gameOver) begin
				if (GONext) begin
					gameOver <= 1'b1;
				end
				else begin
					dir[headY][headX] <= mov;
					headY <= nextHeadY;
					headX <= nextHeadX;
					
					if (!grow) begin
						SnPos[tailY][tailX] <= 1'b0;
						if (length == 9'b000000001) begin
							tailX <= nextHeadX;
							tailY <= nextHeadY;
						end else begin
							tailX <= nextTailX;
							tailY <= nextTailY;
						end
					end else begin
						length <= length + 1'b1;
						ateApple <= 1'b1;
					end
					// Set the head after clearing the departing tail. If both
					// refer to the same cell, the new head must remain occupied.
					SnPos[nextHeadY][nextHeadX] <= 1'b1;
				end
			end
		end
	end
endmodule

// testbench for the above snake module
module snake_testbench();
	logic clk, GT, reset, ateApple, gameOver;
	logic [1:0] mov;
	logic [15:0][15:0] SnPos, AplPos;
	
	snake dut (.mov, .clk, .GT, .reset, .ateApple, .gameOver, .SnPos, .AplPos);
	
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;	// Forever toggle the clock
	end
	
	initial begin
	reset <= 1;
	GT <= 0;
	mov <= 2'b00;   // start moving right
	AplPos <= '0;
	@(posedge clk);
	@(posedge clk);
	
	reset <= 0;
	@(posedge clk);
	
	AplPos <= '0;
	AplPos[15][15] <= 1'b1;
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);

	AplPos <= '0;
	AplPos[0][4] <= 1'b1;
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	mov <= 2'b11;
	AplPos <= '0;
	AplPos[15][15] <= 1'b1;
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	GT <= 1; @(posedge clk);
	GT <= 0; @(posedge clk);
	
	$stop;
	end
endmodule
