clear all
clc

plotIt=1;
saveIt=1;
kernelSize=30; % was 35
nIter=10; % Determines number of random distributions to base population on (usually 10)
rescaleFactor=2; % improves the resolution of the resulting eps image


filename='01_TineV_Acq.mat'; nTotal=3001; window_type=1;
% filename='02_TineV_Probe.mat'; nTotal=2501;
%filename='03_TineV_Ext.mat'; nTotal=2501; % + half half

%%% Define windows
%nTotal=3000;
switch window_type
    case 1 % full
        windowSize=nTotal;%125;
        nOverlap=0;%100;
    case 2
        windowSize=125;
        nOverlap=0;
    case 3
        windowSize=1250;
        nOverlap=0;
end

%saveName=fullfile('dataSets',filename);
saveName=fullfile('dataSets_17parameters',filename);
load(saveName)
allTracks=AllTracks.data;

tracks=unique(allTracks(:,2));
nTracks=length(tracks);

X_min=min(allTracks(:,5));
Y_min=min(allTracks(:,6));

min_value=min([X_min Y_min])-10;

%use_sorting='days';
use_sorting='groups';
switch use_sorting
    case 'groups'
        groupAllocation_vector=TrialAllocation.data(:,1);
    case 'days'
        groupAllocation_vector=TrialAllocation.data(:,4);
end
nGroups=length(unique(groupAllocation_vector));

%imSize=[154 154];
imSize=[200 200];
if exist('poolCoords','var')
    centerCoords=poolCoords.center;
    radius=poolCoords.radius;
    platformCoords=platFormCoords.current;
    platformRadius=platFormCoords.radius;
    poolCoords.imSize=imSize;
else
    centerCoords=[109 76];
    radius=75;
    platformCoords=[138 103];
    platformRadius=7;
end

if saveIt==0
    rescaleFactor=2;
end

%%
offset=windowSize-nOverlap;
nWindows=floor((nTotal-nOverlap)/offset);
timePoints=[(((1:nWindows)-1)*offset+1)' (((1:nWindows)-1)*offset+windowSize)'];
nIntervals=size(timePoints,1);

[a core]=fileparts(filename);
mask=drawCircle(poolCoords.radius*rescaleFactor,(poolCoords.center-min_value)*rescaleFactor,poolCoords.imSize*rescaleFactor);

clf
for interval=1:nIntervals
    timeInterval=timePoints(interval,:);
    
    nCols=floor(sqrt(nGroups));
    nRows=ceil(nGroups/nCols);
    for groupNr=1:nGroups
        switch use_sorting
            case 'groups'
                groupName=folderList{groupNr};
                groupName(groupName=='_')=' ';                
            case 'days'
                groupName=sprintf('Day%02d',groupNr);                
        end
        selectedTracks=find(ismember(groupAllocation_vector,groupNr));
                
        saveName=['output\' core '\' core '_' groupName '_T_' padZeros(timeInterval(1),3) '-' padZeros(timeInterval(2),3) '.png'];        
        if saveIt==0 || ~exist(saveName,'file')
                       
            if max(allTracks(:,3))>nTotal
                sprintf('Maximum trial duration (%3.2f) > nTotal (%3.2f).',[max(allTracks(:,3)) nTotal])
                warning('Not using all available data, check value of nTotal')                                
            end
            
            tracks=allTracks(ismember(allTracks(:,2),selectedTracks)&between(allTracks(:,3),timeInterval),[2 5 6]);
            %tracks=allTracks(allTracks(:,1)==groupNr&between(allTracks(:,3),timeInterval),[2 5 6]);
            tracks(:,2:3)=tracks(:,2:3)-min_value;
            
            A=makeNormalizedHeatplot(tracks,poolCoords,kernelSize,nIter);
            Ymin=min(A(:));
            
            if saveIt==0
                subplot(nRows,nCols,groupNr)
                %subplot(nIntervals,nRows,(interval-1)*nGroups+groupNr)                
                %Ymax=max(A(:));
                Ymax=5;
                Yrange=[-2 Ymax];
                title([groupName ' (t' num2str(timeInterval(1)) '-' num2str(timeInterval(2)) ')'])
                hold on
                lineWidth=1;
            else
                symmetricColorScale=0;
                switch symmetricColorScale
                    case 1
                        Ymax=3; % fixed value based on visual inspection
                        Yrange=[-Ymax Ymax];
                    case 0
                        Yrange=[-2 3];
                end
                lineWidth=3;
            end
            
            %%
            HP=imresize(A,rescaleFactor);
            im=imshow(HP,Yrange);
            hold on
            circle((poolCoords.center-min_value)*rescaleFactor,poolCoords.radius*rescaleFactor+1,1000,'k-',lineWidth);
            plot((poolCoords.center([1 1])-min_value)*rescaleFactor,((poolCoords.center([2 2])-min_value)+[-poolCoords.radius poolCoords.radius])*rescaleFactor,'k-','lineWidth',lineWidth);
            plot(((poolCoords.center([1 1])-min_value)+[-poolCoords.radius poolCoords.radius])*rescaleFactor,(poolCoords.center([2 2])-min_value)*rescaleFactor,'k-','lineWidth',lineWidth);
            
            circle((platFormCoords.current-min_value)*rescaleFactor,platFormCoords.radius*rescaleFactor,1000,'k-',lineWidth);
            if isfield(platFormCoords,'previous')
                circle((platFormCoords.previous-min_value)*rescaleFactor,platFormCoords.radius*rescaleFactor,1000,'k--',lineWidth);
            end
            hold off
            
            colormap jet
            %colormap hot
            set(im,'AlphaData',mask)
            
            %%
            imageHandles(groupNr)=im;                                    
            
            if saveIt==1
                savec(saveName)
                print(gcf,'-dpng','-r300',saveName)
            else
                set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
                %set(gca,'fontsize',6)
                t=title(groupName,'FontSize',6);
                %set(t,'FontSize',6)
            end
        end
        
    end
end


%%
if saveIt==0
    for groupNr=1:nGroups
        maxVal=5;
        H=get(imageHandles(groupNr),'parent');
        set(H,'Clim',[-maxVal maxVal])
    end
end