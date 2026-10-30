// Kevin Xu
// Due 3/15/2026
// Class: EE271

// Top module for DE1_SoC board, runs a snake game using the 16 by 16 led matrix on the GPIO connector. 
// 
// player moves the snake with KEY 1 as left, KEY0 as right, KEY3 as up, and KEY2 as down. 
// resetting the game using switch 9
// LED 0 lights up when the game is over
//
// The goal is the snake (green) to eat the apple (red). Everytime the snake eats the apple, it will grow
// in length by 1. the game will be over if the player hits the side wall or if the snake hits itself. 
module DE1_SoC (CLOCK_50, GPIO_1, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW); 	
	input  logic         CLOCK_50; // 50MHz clock.	
	output logic  [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5; 		
	output logic  [9:0]  LEDR;
	output logic  [35:0] GPIO_1;
	input  logic  [3:0]  KEY;
	input  logic  [9:0]  SW; 		
	
	logic Reset, clkSelect, GT;
	
	logic [31:0] div_clk, div_clk2;
	
	assign HEX0 = 7'b1111111;
	assign HEX1 = 7'b1111111;
	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;
	
	assign Reset = SW[9];
	
	parameter whichClock = 9;
	clock_divider cdiv (.clock(CLOCK_50),	
                       .reset(Reset),	
                       .divided_clocks(div_clk));		
	
	// Clock selection; allows for easy switching between sim and board clocks
	// Detect when we're in Quartus and use the divided clock,
	// otherwise assume we're in ModelSim and use the fast clock
	`ifdef ALTERA_RESERVED_QIS
	    assign clkSelect = div_clk[whichClock]; // for board
	`else
	    assign clkSelect = CLOCK_50; // for simulation
	`endif
	
	//generate game tick
	parameter whichClock2 = 13;
	clock_divider cdiv1 (.clock(clkSelect),	
                       .reset(Reset),	
                       .divided_clocks(div_clk2));	
							  
	assign GT = div_clk2[whichClock2];
	
	//make game tick 1 clkSelect
	logic pGT;
	logic oneGT;
	always_ff @(posedge clkSelect) begin
		if(Reset) begin
			pGT   <= 1'b0;
			oneGT <= 1'b0;
		end else begin
			pGT <= GT;
			if(!pGT && GT) oneGT <= 1'b1;
			else oneGT <= 1'b0;
		end
	end
		
	//rand gen
	logic [7:0] LFSROut;
	LFSR randGen (.clk(clkSelect), .reset(Reset), .out(LFSROut));
	
	// movement modules
	logic rightIn, leftIn, upIn, downIn;
	userInput l (.Clock(clkSelect), .Reset, .In(~KEY[1]), .Out(leftIn));
	userInput r (.Clock(clkSelect), .Reset, .In(~KEY[0]), .Out(rightIn));
	userInput u (.Clock(clkSelect), .Reset, .In(~KEY[3]), .Out(upIn));
	userInput d (.Clock(clkSelect), .Reset, .In(~KEY[2]), .Out(downIn));
	
	// movement encoding
	logic [1:0] pmov, nmov;
	logic valid;
	always_comb begin
		if(rightIn) begin
			nmov = 2'b00; 
			valid = 1;
		end else if(leftIn) begin
			nmov = 2'b01; 
			valid = 1;
		end else if(upIn) begin
			nmov = 2'b10; 
			valid = 1;
		end else if(downIn) begin
			nmov = 2'b11; 
			valid = 1;
		end else begin
			nmov = pmov; 
			valid = 1'b0;
		end
	end
	
	always_ff @(posedge clkSelect) begin
		if(Reset) pmov <= 2'b00;
		else if (valid) begin
			if (!((pmov == 2'b00 && nmov == 2'b01) || 
					(pmov == 2'b01 && nmov == 2'b00) ||  
					(pmov == 2'b10 && nmov == 2'b11) ||  
					(pmov == 2'b11 && nmov == 2'b10)))   
				pmov <= nmov;
		end
	end
	
	// snake
	logic [15:0][15:0] SnPos;
	logic [15:0][15:0] AplPos;
	logic gameOver, ateApple;
	snake snk (.mov(pmov), .clk(clkSelect), .GT(oneGT), .reset(Reset), .ateApple, .gameOver, .SnPos, .AplPos);
	
	//apple
	apple apl (.update(ateApple), .randNum(LFSROut), .SnPos, .AplPos, .reset(Reset), .clk(clkSelect));
	
	//led display
	LEDDriver disp (.GPIO_1, .RedPixels(AplPos), .GrnPixels(SnPos), .EnableCount(1'b1), .CLK(clkSelect), .RST(Reset));
	
	assign LEDR[0] = gameOver;
endmodule		

// Overall testbench for the DE1_SoC. Simulates switch activation, button presses, etc...
// Current setup for snake game
module DE1_SoC_testbench();
	logic CLOCK_50;
	logic [35:0] GPIO_1;
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;
	logic [3:0] KEY;
	logic [9:0] SW;

	DE1_SoC dut (.CLOCK_50, .GPIO_1, .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .LEDR, .SW);

	// speed up game tick in simulation
	defparam dut.whichClock2 = 3;

	parameter CLOCK_PERIOD = 100;
	initial begin
		CLOCK_50 <= 0;
		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
	end

	initial begin
		KEY <= 4'b1111;
		SW <= 10'b0000000000;

		// reset
		SW[9] <= 1'b1; @(posedge CLOCK_50);
						  @(posedge CLOCK_50);
						  @(posedge CLOCK_50);
		SW[9] <= 1'b0; @(posedge CLOCK_50);
						  @(posedge CLOCK_50);

		// let default right movement happen for a few snake moves
		
		for (int i = 0; i < 15; i++)begin
			@(posedge dut.oneGT);
		end
		KEY[2] <= 1'b0; @(posedge CLOCK_50);
		KEY[2] <= 1'b1; @(posedge CLOCK_50);
		for (int i = 0; i < 15; i++) begin
			@(posedge dut.oneGT);
		end

		// move down (+y direction)
		KEY[1] <= 1'b0; @(posedge CLOCK_50);
		KEY[1] <= 1'b1; @(posedge CLOCK_50);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		// try reverse direction (up) while moving down
		KEY[0] <= 1'b0; @(posedge CLOCK_50);
		KEY[0] <= 1'b1; @(posedge CLOCK_50);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		// turn left
		KEY[3] <= 1'b0; @(posedge CLOCK_50);
		KEY[3] <= 1'b1; @(posedge CLOCK_50);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		
		// test for multiple button presses
		KEY[0] <= 1'b0;
		KEY[2] <= 1'b0;
		@(posedge CLOCK_50);
		KEY[0] <= 1'b1;
		KEY[2] <= 1'b1;
		@(posedge CLOCK_50);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		KEY[1] <= 1'b0;
		KEY[3] <= 1'b0;
		@(posedge CLOCK_50);
		KEY[1] <= 1'b1;
		KEY[3] <= 1'b1;
		@(posedge CLOCK_50);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);
		@(posedge dut.oneGT);

		$stop;
	end
endmodule
