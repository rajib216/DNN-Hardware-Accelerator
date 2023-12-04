function [conv_out,tile,wgt_flat] = testdatagenerator(data_in,weight,n,f,dim_in,dim_out,slider)

out_size = (n-f)/slider + 1; % output size of convolution

% Input matrix flattening
in_flat = zeros(1,dim_in*n^2);
for k = 1 : dim_in
    for i = 1 : n
        for j = 1 : n
            in_flat(((k-1)*n+i-1)*n+j) = data_in(i,j,k);
        end
    end
end

% Weight flattening
wgt_flat = zeros(dim_in*f^2,dim_out);
for l = 1 : dim_out
    for k = 1 : dim_in
        for i = 1 : f
            for j = 1 : f
                wgt_flat((((k-1)*f+i-1)*f+j),l) = weight(i,j,k,l);
            end
        end
    end
end

% Tile preparation
tile1 = zeros(out_size^2,f^2,dim_in);
tile = zeros(out_size^2,f^2*dim_in);
lim = out_size*slider;

for k = 1 : dim_in
    q = 1;
    for i = 1 : slider : lim
        for j = 1 : slider : lim
            for p = 0 : f-1
                tile1(q,p*f+1:p*f+f,k) = in_flat(((k-1)*n+i-1+p)*n+j:((k-1)*n+i-1+p)*n+j+f-1);
            end
            q = q+1;
        end 
    end
    tile(:,(k-1)*f^2+1:(k)*f^2) = tile1(:,:,k);
end

% Convolution output
conv_out = tile * wgt_flat;

% Text files generation
file_a = fopen('E:\Modelsim_projects\Systolic Array (tiled convolution)\Test2\Lin_M.dat','w');
file_b = fopen('E:\Modelsim_projects\Systolic Array (tiled convolution)\Test2\Tin_N.dat','w');
file_c = fopen('E:\Modelsim_projects\Systolic Array (tiled convolution)\Test2\valid_results.dat','w');

[row_a,col_a] = size(tile);
[row_b,col_b] = size(wgt_flat);
[row_c,col_c] = size(conv_out);

% Preparing input data for left inputs
for i = 1 : col_a
    for j = 1 : row_a
        fprintf(file_a,'%x\n',tile(j,i)); % Column major storing
    end
end

% Preparing input data for top inputs
for i = 1 : row_b
    for j = 1 : col_b
        fprintf(file_b,'%x\n',wgt_flat(i,j)); % Row major storing
    end
end

% Preparing output data for the matrix product
for i = 1 : col_c
    for j = 1 : row_c
        fprintf(file_c,'%x\n',conv_out(j,i));
    end
end

fclose(file_a);
fclose(file_b);
fclose(file_c);

end