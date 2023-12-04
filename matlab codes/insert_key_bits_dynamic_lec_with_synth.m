clc; clear all; close all;

% %loading key matrix for insertion
load key_mat.mat 

% %fin_name = name of the verilog file to be modified
fin_name = 's344_synth.v';
open(fin_name),

% %reading contents of verilog file as a string
X = read_file(fin_name); 

% %Specify number of keys to be inserted
[num, selected_nodes, raw] = xlsread('N6.xlsx')
% %no_of_keys = length(selected_nodes)-1;
no_of_keys = 51;

% %Specify nodes to be modified
% %[num, selected_nodes, raw] = xlsread('N6.xls')
j=1;
key_no = 1;
added_node = []
% %%work needs to be done
while key_no<=no_of_keys
    added_node = ['W' key_mat(2*key_no-1:2*key_no)]
    sel_node = ['(' selected_nodes{key_no} ')']
    sel_node2 = selected_nodes{key_no}
    key_no = key_no + 1;
    index1 = strfind(X,['.A ' sel_node])+3  
    index2 = [strfind(X,['.A1 ' sel_node]) strfind(X,['.A2 ' sel_node]) strfind(X,['.A3 ' sel_node]) strfind(X,['.A4 ' sel_node])]+4
    index3 = strfind(X,['.D ' sel_node])+3 % strfind(X,['.Q ' sel_node])+3 strfind(X,['.QN ' sel_node])+4]
    index4 = [strfind(X,['.A ' sel_node]) strfind(X,['.B ' sel_node]) strfind(X,['.S ' sel_node])]+3
    index = [index1 index2 index3 index4];
    flag = 0;
    for i =1:length(index)
        index = index + flag;
        X = [X(1:index(i)) added_node X(index(i)+length(sel_node2)+1:end)];
        flag = flag + length(added_node) - length(sel_node2);
    end
end

ind = 1;
while X(ind) ~= '('
    Y(ind) = X(ind);
    ind=ind+1;  
end
Y(ind) = 'm'
while X(ind) ~= ')'
    Y(ind+1) = X(ind);
    ind=ind+1;
end
j=1;
key_no=1;
while j<=no_of_keys*4
    Y=[Y ',' 'K' key_mat(key_no) key_mat(key_no+1)];
    j=j+4;
    key_no=key_no+2;
end
inp_start = strfind(X,'input')+6;
while ind<=inp_start
    Y(ind+no_of_keys*4+1)=X(ind);
    ind=ind+1;
end
while X(ind) ~= ';'
    Y(ind+no_of_keys*4+1)=X(ind);
    ind=ind+1;
end
j=1;
key_no=1;
while j<=no_of_keys*4
    Y=[Y ',' 'K' key_mat(key_no) key_mat(key_no+1)];
    j=j+4;
    key_no=key_no+2;
end
wire_start = strfind(X,'wire')+5;
while ind<=wire_start
    Y(ind+no_of_keys*8+1)=X(ind);
    ind=ind+1;
end
while X(ind) ~= ';'
    Y(ind+no_of_keys*8+1)=X(ind);
    ind=ind+1;
end
% % j=1;
% % key_no=1;
% % while j<=no_of_keys*4
% %     Y=[Y ',' 'W' key_mat(key_no) key_mat(key_no+1)];
% %     j=j+4;
% %     key_no=key_no+2;
% % end

j=1;
key_no=1;
while j<=no_of_keys*4
    Y=[Y ',' 'W' key_mat(key_no) key_mat(key_no+1) ',' ...
             'P' key_mat(key_no) key_mat(key_no+1)];
% %     Y=[Y ',' 'P' key_mat(key_no) key_mat(key_no+1)];
    j=j+4;
    key_no=key_no+2;
end

endmodule_start = strfind(X,'endmodule');

start_point = length(Y)+1;
% % % ind 
% % % while ind<endmodule_start
% % %     Y(ind+no_of_keys*12+1)=X(ind);
% % %     ind=ind+1;
% % % end

while ind<endmodule_start
    Y(start_point)=X(ind);
    ind=ind+1;
    start_point = start_point+1;
end

key_no=1;

% %%//'XOR2_X1 XOR_' M '2_X1 '  M '_'
% %// S = 's27_synth.v';
% % //X = read_file(S);
k = count_gates(X);
choice = 1; %% 1 for fixed, 0 for random
num_of_different_oc = 3; %% Number of obfuscated cells 1, 2 or 3
available_gates = {'XOR' 'XNOR' 'AND' 'NAND' 'OR' 'NOR'};
correct_keys = [ 0 1 1 1 0 0];
Y_synth = Y;
switch(num_of_different_oc)
    case 1
        if choice==0
            rand1 = randi(length(available_gates));
            M{1} = available_gates{rand1};
            key(1) = correct_keys(rand1);
        else
            M{1} = mean_gates(k); %% min_gates/max_gates/mean_gates
            idx = find(ismember(available_gates, M{1}));
            key(1) = correct_keys(idx);
        end
    case 2
         if choice==0
            rand1 = randi(length(available_gates));
            rand2 = randi(length(available_gates));
            while(rand1==rand2)
                rand2 = randi(length(available_gates));
            end
            M{1} = available_gates{rand1};
            M{2} = available_gates{rand2};
            key(1) = correct_keys(rand1);
            key(2) = correct_keys(rand2);

         else
            M{1} = max_gates(k); %% min_gates/max_gates/mean_gates
            M{2} = min_gates(k); %% min_gates/max_gates/mean_gates
            idx1 = find(ismember(available_gates, M{1}));
            idx2 = find(ismember(available_gates, M{2}));
            key(1) = correct_keys(idx1);
            key(2) = correct_keys(idx2);
         end
    case 3
         if choice==0
            rand1 = randi(length(available_gates));
            rand2 = randi(length(available_gates));
            while(rand1==rand2)
                rand2 = randi(length(available_gates));
            end
            rand3 = randi(length(available_gates));
            while(rand3==rand2 || rand3==rand1)
                rand3 = randi(length(available_gates));
            end
            
            M{1} = available_gates{rand1};
            M{2} = available_gates{rand2};
            M{3} = available_gates{rand3};
            key(1) = correct_keys(rand1);
            key(2) = correct_keys(rand2);
            key(3) = correct_keys(rand3);
            
         else
            M{1} = max_gates(k); %% min_gates/max_gates/mean_gates
            M{2} = min_gates(k); %% min_gates/max_gates/mean_gates
            M{3} = mean_gates(k); %% min_gates/max_gates/mean_gates
            idx1 = find(ismember(available_gates, M{1}));
            idx2 = find(ismember(available_gates, M{2}));
            idx3 = find(ismember(available_gates, M{3}));
            key(1) = correct_keys(idx1);
            key(2) = correct_keys(idx2);
            key(3) = correct_keys(idx3);
         end
end
                    
% % % M=max_gates(k);
j=1;
while j<=no_of_keys
    if length(M)>1       
        chosen_oc_idx = randi(num_of_different_oc)
        chosen_oc = M{chosen_oc_idx};
        chosen_key(j) = key(chosen_oc_idx);
    else
        chosen_oc = M{1};
        chosen_key(j) = key(1);
    end
    if strcmp(chosen_oc,('XOR'))
        Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A (0)'...
          ', .B (' selected_nodes{key_no} ')'...
          ', .Z (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];

        Y_synth=[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
          ', .B (' selected_nodes{key_no} ')'...
          ', .Z (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
      
    elseif strcmp(chosen_oc,('XNOR'))
        Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A (1)'...
          ', .B (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
        
        Y_synth =[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
          ', .B (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
      
    elseif strcmp(chosen_oc,('AND'))
        Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A1 (1)'...
          ', .A2 (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
        
        Y_synth=[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A1 (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
          ', .A2 (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];

     elseif strcmp(chosen_oc,('NAND'))
         Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
           '(.A1 (1)'...
           ', .A2 (' selected_nodes{key_no} ')'...
           ', .ZN (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];
         Y=[Y 'INV_X1 ' 'INV_P' num2str(key_mat(2*key_no-1:2*key_no)) ...
           '(.A (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
           ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];
       
         Y_synth=[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
           '(.A1 (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
           ', .A2 (' selected_nodes{key_no} ')'...
           ', .ZN (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];
         Y_synth =[Y_synth 'INV_X1 ' 'INV_P' num2str(key_mat(2*key_no-1:2*key_no)) ...
           '(.A (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
           ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];

     elseif strcmp(chosen_oc,('OR'))
        Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A1 (0)'...
          ', .A2 (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
      
        Y_synth=[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
          '(.A1 (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
          ', .A2 (' selected_nodes{key_no} ')'...
          ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
          sprintf('\n')];
      
    elseif strcmp(chosen_oc,('NOR'))
      Y=[Y chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
        '(.A1 (0)'...
        ', .A2 (' selected_nodes{key_no} ')'...
        ', .ZN (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
        sprintf('\n')];
      Y=[Y 'INV_X1 ' 'INV_P' num2str(key_mat(2*key_no-1:2*key_no)) ...
           '(.A (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
           ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];
       
      Y_synth=[Y_synth chosen_oc '2_X1 '  chosen_oc '_' num2str(key_mat(2*key_no-1:2*key_no))...
        '(.A1 (K' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
        ', .A2 (' selected_nodes{key_no} ')'...
        ', .ZN (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
        sprintf('\n')];
      Y_synth =[Y_synth 'INV_X1 ' 'INV_P' num2str(key_mat(2*key_no-1:2*key_no)) ...
           '(.A (' 'P' num2str(key_mat(2*key_no-1:2*key_no)) ')'...
           ', .ZN (' 'W' num2str(key_mat(2*key_no-1:2*key_no)) '));'...
           sprintf('\n')];
    end
    j=j+1;
    key_no=key_no+1;
end

% for i=1:no_of_keys
%     added_line = ['assign K' key_mat(2*i-1:2*i) '=' int2str(chosen_key(i)) ';' sprintf('\n')];
%     Y = [Y added_line];
% end

Y = [Y 'endmodule'];
Y_synth = [Y_synth 'endmodule'];

% % while ind<=length(X)
% %     Y(ind+no_of_keys*42)=X(ind);
% %     ind=ind+1;
% % end

% %fout_name = name of the modified verilog file 
fout_name='s344m_dyn_lec.v';
fout_name2 ='s344m.v';

% %Save the modified string as the modified verilog file
r = save_file(fout_name,Y);
r2 = save_file(fout_name2,Y_synth);