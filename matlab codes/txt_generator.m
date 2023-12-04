clc
clear variables
close all


file_a = fopen('Lin_M.dat','w');
file_b = fopen('Tin_N.dat','w');
file_c = fopen('valid_results.dat','w');

a = [1 2 1 1 0 2 0 3 1 2 0 1;
     2 0 1 3 2 1 3 2 2 1 1 3;
     1 1 0 2 0 3 1 1 0 1 3 3;
     1 3 2 2 3 2 1 0 1 3 3 2];
 
 b = [1 0;
      2 1;
      0 2;
      1 3;
      1 1;
      0 2;
      1 3;
      0 3;
      1 1;
      1 1;
      1 2;
      1 0];
  
c = a * b;

[row_a,col_a] = size(a);
[row_b,col_b] = size(b);
[row_c,col_c] = size(c);

% Preparing input data for left inputs
for i = 1 : col_a
    for j = 1 : row_a
        fprintf(file_a,'%x\n',a(j,i)); % Column major storing
    end
end

% Preparing input data for top inputs
for i = 1 : row_b
    for j = 1 : col_b
        fprintf(file_b,'%x\n',b(i,j)); % Row major storing
    end
end

% Preparing output data for the matrix product
for i = 1 : col_c
    for j = 1 : row_c
        fprintf(file_c,'%x\n',c(j,i));
    end
end

fclose(file_a);
fclose(file_b);
fclose(file_c);


% save('leftin.txt','a','-ascii')
% file = fopen('Lin.txt','w');
% fprintf(file,'%x\n',a);
% dlmwrite('myfile.txt',a,'delimiter',' ');
% fclose(file);