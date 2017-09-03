function data=fillTheGaps2(data)
%function data=fillTheGaps2(data)
% Take the data and use the data itself to fill in blank spots, usually
% represented by NaN values. Three possible scenarios, blank at begin, in
% middle or at the end. Multiple blanks can occur.
%%
switch 0
    case 0
    case 1
        data=[NaN NaN 1.5 1 1];
    case 2
        data=[1 NaN 1.2 1];
    case 3
        data=[1 1 2.6 NaN];
    case 4
        data=[NaN NaN 1.4 1 NaN NaN .6 2.5 NaN NaN];
end


%%% Preprocess: make col vector
data=data(:);

%%% Detect all blank values
blank=isnan(data);

%%% Create switch detector
switch_detector=diff([0 ; blank ; 0]);

%%% Find start and end point of each period
idx_start=find(switch_detector==1)-1;
idx_end=find(switch_detector==-1);
nBlanks=length(idx_start);
if length(idx_end)==nBlanks
    for iBlank=1:nBlanks
        if idx_start(iBlank)==0
            A=data(idx_end(iBlank));
            B=data(idx_end(iBlank));
        elseif idx_end(iBlank)>length(data)
            A=data(idx_start(iBlank));
            B=data(idx_start(iBlank));
        else
            A=data(idx_start(iBlank));
            B=data(idx_end(iBlank));
        end
        len=idx_end(iBlank)-idx_start(iBlank)+1;        
        fill=linspace(A,B,len);
        data(idx_start(iBlank)+1:idx_end(iBlank)-1)=fill(2:end-1);
    end
else
    die
end


%[data(idx_start(1)) data(idx_end(1))]

% if ~exist('data','var')
%     nPoints=1000;
%     nBreaks=3;
%     breakSize=30;
%     data=gaussSmooth(randn(1,nPoints),200);
%     breaks=sort(Randi(nPoints-breakSize,[1 nBreaks]));
%     data_real=data(:);
%     for index=1:nBreaks
%         data(breaks(index):breaks(index)+breakSize)=NaN;
%     end
% end
% data=data(:);
% A=isnan(data);
%
% %%% Fix start and end NaN periods
% if A(1)==1 % NaN at start
%     index=find(A==0,1,'first');
%     value=data(index);
%     data(1:index-1)=value;
% end
% if A(end)==1 % NaN at end
%     index=find(A==0,1,'last');
%     value=data(index);
%     data(index+1:end)=value;
% end
%
% B=diff(isnan(data));
% M=[find(B==1)-1 find(B==-1)+1];
% N=size(M,1);
%
% if ~isempty(M)
%     for index=1:N
%         interpolated=linspace(data(M(index,1)+1),data(M(index,2)),diff(M(index,:)));
%         data(M(index,1)+2:M(index,2)-1)=interpolated(2:end-1);
%     end
% else
%     M
%     die
% end
%
% plotIt=0;
% if plotIt==1
%     X_AS=1:length(data);
%     plot(X_AS(A==0),data(A==0),'bo')
%     hold on
%     plot(X_AS(A==1),data(A==1),'go')
%     plot(data,'r-')
%     if exist('data_real','var')
%         plot(data_real,'b-')
%         title(sci(sum((data_real-data).^2)*1000))
%     end
%     hold off
%     axis square
%     box off
%     drawnow
% end