function [table selectionMatrix]=pivotTable(varargin)

%%% Set default values
op='length';
target_col=1;
if nargin>=1
    data=varargin{1};    
end
if nargin>=2
    cols=varargin{2};
end
if nargin>=3
    op=varargin{3};
end
if nargin>=4
    target_col=varargin{4};
end
if nargin>=5
    arguments=varargin{5};
end
Ncols=length(cols);

%%% get all levels
levels=cell(1,Ncols);
%levelNames=cell(1,Ncols);
for col_index=1:Ncols
    levels{col_index}=unique(data(:,cols(col_index)));
    %levelNames{col_index}=fieldNames{cols(col_index)};
end

%%% get all combinations of all levels
selectionMatrix=zeros(0,Ncols+2);
count=1;
if Ncols==1
    L1=levels{1};
    N1=length(L1);
    for i=1:length(L1)
        selectionMatrix(count,1:Ncols+1)=[count L1(i)];
        count=count+1;
    end
elseif Ncols==2
    L1=levels{1};
    L2=levels{2};
    N1=length(L1);
    N2=length(L2);
    selectionMatrix=zeros(N1*N2,3);
    for i=1:N1
        for j=1:N2
            selectionMatrix(count,:)=[count L1(i) L2(j)];
            count=count+1;
        end
    end
elseif Ncols==3
    L1=levels{1};
    L2=levels{2};
    L3=levels{3};
    N1=length(L1);
    N2=length(L2);
    N3=length(L3);
    selectionMatrix=zeros(N1*N2*N3,4);
    for i=1:N1
        for j=1:N2
            for k=1:N3
                selectionMatrix(count,:)=[count L1(i) L2(j) L3(k)];
                count=count+1;
            end
        end
    end
end

%%% get requested statistic
if Ncols==1
    table=NaN(N1,1);
    for row_index=1:size(selectionMatrix,1)
        L1_index=selectionMatrix(row_index,2);
        selection=data(:,cols(1))==L1_index;
        
        value=NaN;
        part=data(selection,target_col);
        if ~isempty(part)
            if ~exist('arguments','var')
                eval(['value=' op '(part);'])
            else
                if strcmpi(op,'prctile')
                    eval(['value=' op '(part,' num2str(arguments(1)) ');'])
                end
            end
        end
        
        table(L1==L1_index,1:length(value))=value;
        
        selectionMatrix(row_index,Ncols+2:Ncols+1+length(value))=value;
    end
elseif Ncols==2
    table=NaN(N1,N2);
    for row_index=1:size(selectionMatrix,1)
        L1_index=selectionMatrix(row_index,2);
        L2_index=selectionMatrix(row_index,3);
        selection=data(:,cols(1))==L1_index&data(:,cols(2))==L2_index;
        
        value=NaN;
        part=data(selection,target_col);
        if ~isempty(part)
            eval(['value=' op '(part);'])
        end      
        table(L1==L1_index,L2==L2_index)=value;
        
        selectionMatrix(row_index,Ncols+2)=value;
    end
elseif Ncols==3
    table=NaN(N1,N2,N3);
    for row_index=1:size(selectionMatrix,1)
        L1_index=selectionMatrix(row_index,2);
        L2_index=selectionMatrix(row_index,3);
        L3_index=selectionMatrix(row_index,4);
        selection=data(:,cols(1))==L1_index&data(:,cols(2))==L2_index&data(:,cols(3))==L3_index;
        
        value=NaN;
        part=data(selection,target_col);
        if ~isempty(part)
            eval(['value=' op '(part);'])
        end
        table(L1==L1_index,L2==L2_index,L3==L3_index)=value;
        
        selectionMatrix(row_index,Ncols+2)=value;
    end
end


