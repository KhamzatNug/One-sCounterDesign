`timescale 1ns/100ps


module Ones_Counter(count, Ready, data, Start, clock, reset);
	parameter R1_size = 8, R2_size = 4;
	output [R2_size-1:0] count;
	output Ready;
	input [R1_size-1:0] data;
	input Start, clock, reset;
	wire Zero, One, Load_Regs, Shift_R1, Incr_R2;
	
	DataPath D0(count, Zero, One, data, Load_Regs, Incr_R2, Shift_R1, clock);
	Controller M0(Ready, Load_Regs, Incr_R2, Shift_R1, Start, Zero, One, clock, reset);
endmodule 


module Controller(Ready, Load_Regs, Incr_R2, Shift_R1, Start, Zero, One, clock, reset);
	output reg Ready, Load_Regs, Incr_R2, Shift_R1;
	input Start, Zero, One, clock, reset;

	reg [2:0] state, next_state;
	parameter S_idle = 3'b001, S_1 = 3'b010, S_2 = 3'b100;

	//state logic
	always @(posedge clock, negedge reset)
		if (reset == 0) state <= S_idle;
		else state <= next_state;

	//next_state logic
	always @* begin
		next_state = S_idle;
		case(state)
			S_idle: if (Start) next_state = S_1; else next_state = S_idle;
			S_1: if (Zero) next_state = S_idle; else next_state = S_2;
			S_2: next_state = S_1;
		endcase  
	end

	//output logic
	always @* begin
		Ready = 0;
		Load_Regs = 0;
		Incr_R2 = 0;
		Shift_R1 = 0;
		case (state)
			S_idle: begin Ready = 1; if(Start) Load_Regs = 1; end
			S_1: if (!Zero & One) Incr_R2 = 1;
			S_2: Shift_R1 = 1;
		endcase
	end

endmodule 


module DataPath(count, Zero, One, data, Load_Regs, Incr_R2, Shift_R1, clock);
	parameter R1_size = 8, R2_size = 4;
	output [R2_size-1:0] count;
	output Zero, One;
	input Load_Regs, Incr_R2, Shift_R1, clock;
	input [R1_size-1:0] data;

	reg [R1_size-1:0] R1;
	reg [R2_size-1:0] R2;

	always @(posedge clock) begin
		if (Load_Regs) begin
			R1 <= data;
			R2 <= 4'b0;
		end

		if (Incr_R2) 
			R2 <= R2+1;

		if (Shift_R1)
			R1 <= R1 >> 1;
	end

	assign Zero = (R1 == 0);
	assign One  = R1[0] ;
	assign count = R2;

endmodule 

module test_bench;
	parameter R1_size = 8, R2_size = 4;
	reg Start, clock, reset;
	reg [R1_size-1:0] data;
	wire [R2_size-1:0] count;
	wire Ready;
	Ones_Counter C0(count, Ready, data, Start, clock, reset);

	initial #200 $finish;

	initial begin clock = 0; forever #5 clock = ~clock; end

	initial fork 
		data = 8'b0100_1100;
		reset = 0;
		#3 reset = 1;
		#10 Start = 1;
		#20 Start = 0;
	join  

	initial begin 
		$monitor("state = %3b Load = %b Incr = %b Shift = %b R1 = %8b R2 = %4b One = %b Zero = %b", C0.M0.state, C0.Load_Regs, C0.Incr_R2, C0.Shift_R1,
																									C0.D0.R1, C0.D0.R2, C0.One, C0.Zero);
	end

	/*initial begin 
		$dumpfile("Ones_Count.vcd");
		$dumpvars(0,test_bench);
	end*/ 
endmodule 