module accumulator #(
	parameter word_size = 8
)(
	a,
	out,
	clk,
	clear
);

input clk, clear;
input [0:word_size-1] a;
output reg [0:word_size-1] out;

always @(posedge clk)
begin
	if(clear) out <= 0;
	else out <= out+a;
end

endmodule 