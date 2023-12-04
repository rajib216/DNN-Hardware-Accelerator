module MAC_fp #(
	parameter word_size = 16,
	parameter fractional_bits = 0
)(
	a,
	b,
	a_fwd,
	b_fwd,
	out,
	clk,
	clear
);

input [0:word_size-1] a,b;
input clk;
input clear;

output reg [0:word_size-1] out;
output reg [0:word_size-1] a_fwd,b_fwd;

wire [0:word_size-1] mult_out;
wire [0:word_size-1] adder_out;
wire overflow;

//The fixed-point multiplier module
qmult #(
	.N(word_size),
	.Q(fractional_bits)
) mult(
	.a(a),
	.b(b),
	.q_result(mult_out),
	.overflow(overflow)
);

//The fixed-point adder module
qadd #(
	.N(word_size),
	.Q(fractional_bits)
) add(
	.a(mult_out),
	.b(out),
	.c(adder_out)
);

always @(posedge clk)
begin
	if(clear)
	begin
		a_fwd <= {word_size{1'b0}};
		b_fwd <= {word_size{1'b0}};
		out <= {word_size{1'b0}};
	end
	else
	begin
		a_fwd <= a;
		b_fwd <= b;
		out <= adder_out;
	end
end
endmodule

