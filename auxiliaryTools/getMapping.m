function mapping=getMapping(string_array)

unique_vector=unique(string_array);
N=length(unique_vector);
mapping=zeros(N,1);
for index=1:N
    sel=string_array==unique_vector(index);
    mapping(sel)=index;
end
