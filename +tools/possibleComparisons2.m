function out=possibleComparisons2(N,varargin)

if nargin>=2
    type=varargin{1};
else
    type=1;
end
M=ones(N);

switch type
    case 0 % all
        selection=M==1;
    case 1 % upper, no identity
        selection=triu(M,1)==1;
    case 2 % upper, with identity
        selection=triu(M)==1;
    case 3 % all, no identity
        selection=eye(N)==0;
end

[X Y]=find(selection==1);
out=sortrows([X Y],1:2);
