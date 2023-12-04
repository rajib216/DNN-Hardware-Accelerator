
module buffern #(
	parameter word_size = 8,
	parameter length = 1
)(
	in,
	out,
	clk,
	clear
);

input [0:word_size-1] in;
input clk,clear;

output [0:word_size-1] out;

wire [0:word_size*(length+1)-1] intermediates;

assign intermediates[0:word_size-1] = in;
assign out = intermediates[word_size*length:word_size*(length+1)-1];

genvar k;
generate
for(k=0; k<length; k=k+1)
begin:shift
 buffer1 #(
	.word_size(word_size)
 ) buffer(
	.in(intermediates[word_size*k:word_size*(k+1)-1]),
	.out(intermediates[word_size*(k+1):word_size*(k+2)-1]),
	.clk(clk),
	.clear(clear)
	);
end
endgenerate

endmodule 