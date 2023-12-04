
module buffer1 #(
	parameter word_size = 8
)(
	in,
	out,
	clk,
	clear
);

input [0:word_size-1] in;
input clk;
input clear;

output reg [0:word_size-1] out;

always @(posedge clk or posedge clear)
begin
 if(clear)
  begin
   out <= {word_size{1'b0}};
  end
 else
  begin
   out <= in;
  end
end

endmodule
