`timescale 1ns/100ps

module test();

parameter word_size = 8;
parameter fractional_bits = 0;

reg clk,reset;
reg [word_size-1:0] a;
reg [word_size-1:0] b;

wire [word_size-1:0] a_fwd,b_fwd;
wire [word_size-1:0] out;

MAC_fp #(
.word_size(word_size),
.fractional_bits(fractional_bits)
) dut(
	.a(a),
	.b(b),
	.a_fwd(a_fwd),
	.b_fwd(b_fwd),
	.out(out),
	.clk(clk),
	.clear(reset)
);

wire [word_size-1:0] adder_out = dut.add.c;
wire [word_size-1:0] mult_out = dut.mult.q_result;

initial begin
	$display ("time \t a\t b\t out\t a_fwd\t b_fwd\t reset");
	$monitor ("%g\t %d\t%d\t%d\t%d\t%d\t%d",$time, a, b, out, a_fwd, b_fwd, reset);
	
	clk = 1'b0;
	reset = 1'b1;
	#2; reset = 1'b0;
	
	a = 1; b = 1;
	#2;
	a = 0; b = 1;
	#2;
	a = 3; b = 4;
	#2;
	a = 7; b = 16;
	#2;
	
	reset = 1'b1;
	#10; reset = 1'b0;
	
	a = 5; b = 2;
	#2;
	a = 2; b = 3; 
	#5;
end

always #1 clk = ~clk;

endmodule 