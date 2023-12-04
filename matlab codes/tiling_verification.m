clc
clear variables
close all

load('data.mat');
load('weight.mat');

dim_in = 1;
dim_out = 1;
n = 10;
f = 3;
stride = 1;
out_size = (n-f)/stride + 1;

data_in = data(1:n,1:n,1:dim_in);
wgt = weight(:,:,1:dim_in,1:dim_out);

conv_result = testdatagenerator(data_in,wgt,n,f,dim_in,dim_out,stride);

valid_output = zeros(out_size,out_size,1:dim_out);
for k = 1 : dim_out
    for i = 1 : out_size
        for j = 1 : out_size
            valid_output(i,j,k) = conv_result(((k-1)*out_size+i-1)*out_size+j);
        end
    end
end

tile_size = 5;
tiles = zeros(tile_size,tile_size,(n/tile_size)^2);

for i = 1 : n/tile_size
    for j = 1 : n/tile_size
        tiles(:,:,(i-1)*(n/tile_size)+j) = data_in((i-1)*tile_size+1 : i*tile_size, (j-1)*tile_size+1 : j*tile_size);
    end
end

% % Zero Pad the tiles % %
       % Here %
% %------------------- % %

tile_out_size = (tile_size-f)/stride + 1;
tiled_output = zeros(tile_out_size*tile_out_size,(n/tile_size)^2);

for k = 1 : (n/tile_size)^2
    tiled_output(:,k) = testdatagenerator(tiles(:,:,k),wgt,tile_size,f,dim_in,dim_out,stride);
end

valid_tiles = zeros(tile_out_size,tile_out_size,(n/tile_size)^2);

for k = 1 : (n/tile_size)^2
    for i = 1 : tile_out_size
        for j = 1 : tile_out_size
            valid_tiles(i,j,k) = tiled_output((i-1)*tile_out_size+j,k);
        end
    end
end