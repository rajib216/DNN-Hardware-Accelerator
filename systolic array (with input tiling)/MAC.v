module MAC #(
	parameter in_word_size = 8,
	parameter out_word_size = 16
)(
	a,
	b,
	a_fwd,
	b_fwd,
	out,
	clk,
	clear
);

input [0:in_word_size-1] a,b;
input clk;
input clear;

output reg [0:out_word_size-1] out;
output reg [0:in_word_size-1] a_fwd,b_fwd;

wire [0:out_word_size-1] mult_out;
wire [0:out_word_size-1] adder_out;


assign mult_out = a*b;
assign adder_out = mult_out+out;

always @(posedge clk)
begin
 if(clear)
 begin
  a_fwd <= {in_word_size{1'b0}};
  b_fwd <= {in_word_size{1'b0}};
  out <= {out_word_size{1'b0}};
 end
 else
 begin
  a_fwd <= a;
  b_fwd <= b;
  out <= adder_out;
 end
end

endmodule 