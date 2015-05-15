function data=fillTheGaps2(data)

if ~exist('data','var')
    nPoints=1000;
    nBreaks=3;
    breakSize=30;
    data=gaussSmooth(randn(1,nPoints),200);
    breaks=sort(Randi(nPoints-breakSize,[1 nBreaks]));
    data_real=data(:);
    for index=1:nBreaks
        data(breaks(index):breaks(index)+breakSize)=NaN;
    end
end
data=data(:);
A=isnan(data);

%%% Fix start and end NaN periods
if A(1)==1 % NaN at start
    index=find(A==0,1,'first');
    value=data(index);
    data(1:index-1)=value;
end
if A(end)==1 % NaN at end
    index=find(A==0,1,'last');
    value=data(index);
    data(index+1:end)=value;
end

B=diff(isnan(data));
M=[find(B==1)-1 find(B==-1)+1];
N=size(M,1);

if ~isempty(M)
    for index=1:N
        interpolated=linspace(data(M(index,1)+1),data(M(index,2)),diff(M(index,:)));
        data(M(index,1)+2:M(index,2)-1)=interpolated(2:end-1);
    end
end

plotIt=0;
if plotIt==1
    X_AS=1:length(data);
    plot(X_AS(A==0),data(A==0),'bo')
    hold on
    plot(X_AS(A==1),data(A==1),'go')
    plot(data,'r-')
    if exist('data_real','var')
        plot(data_real,'b-')
        title(sci(sum((data_real-data).^2)*1000))
    end
    hold off
    axis square
    box off
    drawnow
end