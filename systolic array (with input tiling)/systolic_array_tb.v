
`timescale 1ns/1ps

module systolic_array_tb();

parameter word_size = 16;
parameter in_word_size = 8;
parameter out_word_size = 24;

parameter arr1_rows = 3;
parameter arr1_cols = 27;
parameter arr2_rows = 27;
parameter arr2_cols = 3;

parameter arr_rows = arr1_rows;
parameter arr_cols = arr2_cols;
parameter compute_cycles = 5+arr1_rows+arr1_cols;

reg clk;
reg reset;

reg [in_word_size-1:0] left_inputs [0:arr1_rows*arr1_cols-1]; 
reg [in_word_size-1:0] top_inputs [0:arr2_rows*arr2_cols-1];
reg [out_word_size-1:0] valid_results [0:arr_rows*arr_cols-1];

reg [in_word_size*arr_rows-1:0] left_inputs_wire;
reg [in_word_size*arr_cols-1:0] top_inputs_wire;

wire compute_done_out;
wire [out_word_size-1:0] cycles_count_out;

wire [out_word_size-1:0] pe_register_vals_mem [0:arr_rows*arr_cols-1];

reg [out_word_size-1:0] convolution_output [0:arr_rows*arr_cols-1];

wire [0:out_word_size*arr_cols*arr_rows-1] pe_register_vals_wire;


integer i,j,k;
integer row,col,tile_element;

initial begin
clk = 1'b0;
reset = 1'b1;
row = -1;
col = -1;
tile_element = -1;

$readmemh("E:/Modelsim_projects/Tiling Systolic Array/Test3/Lin.txt",left_inputs);
$readmemh("E:/Modelsim_projects/Tiling Systolic Array/Test3/Tin.txt",top_inputs);
//$readmemh("E:/Modelsim_projects/Tiling Systolic Array/Test1/valid_results.dat",valid_results);

#40 reset = 1'b0;
end

always #5 clk = ~clk;

genvar r,c;
generate
for(r=0; r<arr1_rows; r=r+1)
begin:Lin
	always @(posedge clk or posedge reset)
	begin
		if(reset == 1'b1)
		begin
			left_inputs_wire[(r+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
		end
		else
		begin
			if(col < arr1_cols)
			begin
				left_inputs_wire[(r+1)*in_word_size-1 -: (in_word_size)] <= left_inputs[(col*arr1_rows)+r];
			end
			else
			begin
				left_inputs_wire[(r+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
			end
		end
	end
end
endgenerate

generate
for(c=0; c<arr2_cols; c=c+1)
begin:Tin
	always @(posedge clk or posedge reset)
	begin
		if(reset == 1'b1)
		begin
			top_inputs_wire[(c+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
		end
		else
		begin
			if(row < arr2_rows)
			begin
				top_inputs_wire[(c+1)*in_word_size-1 -: (in_word_size)] <= top_inputs[(row*arr2_cols)+c];
			end
			else
			begin
				top_inputs_wire[(c+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
			end
		end
	end
end
endgenerate

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b1)
	begin
		row <= -1;
		col <= -1;
	end
	else
	begin
		row <= row+1;
		col <= col+1;
	end
end

generate
    for(r=0; r<arr_rows * arr_cols; r=r+1)
    begin:pe_reg
        assign pe_register_vals_mem[r] = pe_register_vals_wire[r* out_word_size: (r+1)* out_word_size -1];
    end
endgenerate

/*
reg [0 : arr_rows*arr_cols-1] count = 0;
always @(posedge clk)
begin 
    if(compute_done_out == 1'b1)
    begin
	if(count < arr_cols*arr_rows)
	begin
        for(i=0; i< arr_cols; i=i+1)
        begin
            for (j=0; j< arr_rows; j=j+1)
            begin
                convolution_output[count] = pe_register_vals_mem[j*arr_cols + i];
		count = count + 1;
	    end
	end
    	$writememh("E:/Modelsim_projects/Tiling Systolic Array/Test2/test_results.txt",convolution_output);
	end
   end
end
*/

/*
reg flag = 0;

always @(posedge clk)
begin
if(compute_done_out == 1'b1)
begin
if(!flag)
begin
for(k=0; k<arr_rows*arr_cols; k=k+1)
begin
if(convolution_output[k] != valid_results[k])
begin
flag = 1;
end
end
end
end
end

always @(flag)
case(flag)
0: $display("All outputs match the valid convolution results properly.");
1: $display("Error!");
default: $display("Checking...");
endcase
*/

systolic_array #(
	.in_word_size(in_word_size),
	.out_word_size(out_word_size),
	.num_row(arr_rows),
	.num_col(arr_cols),
	.done(compute_cycles)
) dut(
	.clk(clk),
	.reset(reset),
	.left_inputs(left_inputs_wire),
	.top_inputs(top_inputs_wire),
	.compute_done(compute_done_out),
    .cycles_count(cycles_count_out),
	.pe_register_vals(pe_register_vals_wire)
);

///////////// tiling starts ///////////////

parameter Ltile_rows = 3;
parameter Ltile_cols = 3;
parameter Ttile_rows = 3;
parameter Ttile_cols = 3;

parameter tile_rows = Ltile_rows;
parameter tile_cols = Ttile_cols;

parameter nL_tiles = arr1_cols/Ltile_cols;
parameter nT_tiles = arr2_rows/Ttile_rows;

parameter tile_compute_cycles = 5+tile_rows+tile_cols; // The output available time of a 3by3 systolic array block = 1 + 3*3 CCs = 10 CCs   (CCs --> Clock Cycles)
parameter tile_acc_compute_cycles = 5+tile_rows*tile_cols; // The total accumulation time of each accumulator = 9 CCs (For 3by3 systolic array blocks). So, the total computation time <= 20 CCs 

wire tile_compute_done_out[0:nL_tiles-1]; 
wire [out_word_size-1:0] tile_cycles_count_out [0:nL_tiles-1];

reg [in_word_size-1:0] Ltile [0:nL_tiles-1] [0:Ltile_rows*Ltile_cols-1]; // format: Ltile[row][col] where #row = #tiles (9 (3by3) tiles from 3by27 left_inputs matrix) & #col = #elements in a tile (#elements = 3*3 = 9)
reg [in_word_size-1:0] Ttile [0:nT_tiles-1] [0:Ttile_rows*Ttile_cols-1]; // format: Ltile[row][col] where #row = #tiles (9 (3by3) tiles from 27by3 top_inputs matrix) & #col = #elements in a tile (#elements = 3*3 = 9)

reg [in_word_size*arr_rows-1:0] Ltile_inputs_wire[0:nL_tiles-1];
reg [in_word_size*arr_cols-1:0] Ttile_inputs_wire[0:nL_tiles-1];

wire [0:out_word_size*tile_cols*tile_rows-1] par_tile_PE [0:nL_tiles-1];
wire [out_word_size-1:0] par_tile_PE_mem [0:nL_tiles-1] [0:arr_rows*arr_cols-1];

wire [out_word_size-1:0] acc_val [0:nL_tiles-1];

reg [31:0] res_count = 0;
reg tile_done;

genvar ti,tj,tk;
generate
	for(ti=0; ti<9; ti=ti+1)
	begin
		for(tj=0; tj<3; tj=tj+1)
		begin
			for(tk=tj*3; tk<tj*3+3; tk=tk+1)
			begin
				always @(posedge clk) 
				begin
					Ltile[ti][tk] = left_inputs[tj*arr1_rows+(tk%3)+ti*9];
					Ttile[ti][tk] = top_inputs[tj*arr2_cols+(tk%3)+ti*9];
				end
			end
		end
	end
endgenerate


genvar tr,tc;
generate
for(ti=0; ti<nL_tiles; ti=ti+1)
begin
	for(tr=0; tr<Ltile_rows; tr=tr+1)
	begin:Ltile_in
		always @(posedge clk or posedge reset)
		begin
			if(reset == 1'b1)
			begin
				Ltile_inputs_wire[ti][(tr+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
			end
			else
			begin
				if(col < Ltile_cols)
				begin
					Ltile_inputs_wire[ti][(tr+1)*in_word_size-1 -: (in_word_size)] <= Ltile[ti][(col*Ltile_rows)+tr];
				end
				else
				begin
					Ltile_inputs_wire[ti][(tr+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
				end
			end
		end
	end
end
endgenerate

generate
for(ti=0; ti<nL_tiles; ti=ti+1)
begin
	for(tc=0; tc<Ttile_cols; tc=tc+1)
	begin:Ttile_in
		always @(posedge clk or posedge reset)
		begin
			if(reset == 1'b1)
			begin
				Ttile_inputs_wire[ti][(tc+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
			end
			else
			begin
				if(row < Ttile_rows)
				begin
					Ttile_inputs_wire[ti][(tc+1)*in_word_size-1 -: (in_word_size)] <= Ttile[ti][(row*Ttile_cols)+tc];
				end
				else
				begin
					Ttile_inputs_wire[ti][(tc+1)*in_word_size-1 -: (in_word_size)] <= {in_word_size{1'b0}};
				end
			end
		end
	end
end
endgenerate

generate
for(tc=0; tc<tile_rows * tile_cols; tc=tc+1)
begin
	for(ti=0; ti<nL_tiles; ti=ti+1)
	begin:tile_pe_reg
		assign par_tile_PE_mem[tc][ti] = par_tile_PE [ti][tc* out_word_size: (tc+1)* out_word_size -1];
    end
end
endgenerate

always @(posedge clk)
begin
	if(res_count == tile_acc_compute_cycles || reset)
	begin
		tile_done <= 1;
		tile_element <= -1;
		res_count <= 0;
	end
	else
	begin
		tile_done <= 0;
		tile_element <= tile_element+1;
		res_count <= res_count + 1;
	end
end


generate
for(ti=0; ti<tile_rows*tile_cols; ti=ti+1)
begin: accumulate
	accumulator #(
	.word_size(out_word_size)
	) acc_dut(
		.clk(clk),
		.clear(tile_done),
		.a(par_tile_PE_mem[ti][tile_element]),
		.out(acc_val[ti])
	);
end
endgenerate

genvar ptiles;
generate
	for(ptiles=0; ptiles<9; ptiles=ptiles+1)
	begin:parallel_tiles
		systolic_array #(
			.in_word_size(in_word_size),
			.out_word_size(out_word_size),
			.num_row(arr_rows),
			.num_col(arr_cols),
			.done(tile_compute_cycles)
		) par_dut(
			.clk(clk),
			.reset(reset),
			.left_inputs(Ltile_inputs_wire[ptiles]),
			.top_inputs(Ttile_inputs_wire[ptiles]),
			.compute_done(tile_compute_done_out[ptiles]),
			.cycles_count(tile_cycles_count_out[ptiles]),
			.pe_register_vals(par_tile_PE[ptiles])
		);
	end
endgenerate

/////////////// tiling ends /////////////

endmodule 