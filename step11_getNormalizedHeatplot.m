clear all
clc

header_script_MWM

plotIt=1;
saveIt=1;
kernelSize=30; % was 35
nPerm=2; % Determines number of random distributions to base population on (usually 10)
rescaleFactor=2; % improves the resolution of the resulting eps image

nTotal=3001; 
window_type=1;


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

loadName=fullfile('dataSets',databaseName);
%saveName=fullfile('dataSets_17parameters',databaseName);
load(loadName)
allTracks=cat(1,AllTracks.data);

X_min=min(allTracks(:,2));
Y_min=min(allTracks(:,3));

min_value=min([X_min Y_min])-10;

%use_sorting='days';
use_sorting='batch-days';
switch use_sorting
    case 'groups'
        groupAllocation_vector=TrialAllocation.data(:,1);
    case 'days'
        groupAllocation_vector=TrialAllocation.data(:,4);
    case 'batch-days'
        batch_select=4;
        sel=TrialAllocation.data(:,3)==batch_select;
        groupAllocation_vector=TrialAllocation.data(sel,1);
end
group_nrs=unique(groupAllocation_vector);
nGroups=length(group_nrs);

%imSize=[154 154];
imSize=[200 200];
if exist('poolCoords','var')
    centerCoords=poolCoords.center;
    radius=poolCoords.radius;
    platForm_coords=platFormCoords.coords(1).center;
    platForm_radius=platFormCoords.coords(1).radius;
    poolCoords.imSize=imSize;
else
    centerCoords=[109 76];
    radius=75;
    platForm_coords=[138 103];
    platForm_radius=7;
end

if saveIt==0
    rescaleFactor=2;
end

%%
offset=windowSize-nOverlap;
nWindows=floor((nTotal-nOverlap)/offset);
timePoints=[(((1:nWindows)-1)*offset+1)' (((1:nWindows)-1)*offset+windowSize)'];
nIntervals=size(timePoints,1);

mask=drawCircle(poolCoords.radius*rescaleFactor,(poolCoords.center-min_value)*rescaleFactor,poolCoords.imSize*rescaleFactor);

clf
for interval=1:nIntervals
    timeInterval=timePoints(interval,:);
    
    nCols=floor(sqrt(nGroups));
    nRows=ceil(nGroups/nCols);
    for iGroup=1:nGroups
        group_nr=group_nrs(iGroup);
        switch use_sorting
            case 'groups'
                groupName=folder_list{iGroup};
                groupName(groupName=='_')=' ';                
            case 'days'
                groupName=sprintf('Day%02d',iGroup);                
            case 'batch-days'
                groupName=folder_list{group_nr}
        end
        
        selectedTracks=find(ismember(groupAllocation_vector,group_nr));
                
        %saveName=['output\' databaseName '\' databaseName '_' groupName '_T_' padZeros(timeInterval(1),3) '-' padZeros(timeInterval(2),3) '.png'];
        saveName=fullfile('output',databaseName,[databaseName '_' groupName '_T_' padZeros(timeInterval(1),3) '-' padZeros(timeInterval(2),3) '.png']);
        if saveIt==0 || ~exist(saveName,'file')
                       
            if max(allTracks(:,3))>nTotal
                sprintf('Maximum trial duration (%3.2f) > nTotal (%3.2f).',[max(allTracks(:,3)) nTotal])
                warning('Not using all available data, check value of nTotal')                                
            end
            
            allTracks=cat(1,AllTracks(selectedTracks).data);
            tracks=allTracks(between(allTracks(:,1),timeInterval),:);
            tracks(:,2:3)=tracks(:,2:3)-min_value;
            
            %%% Get real data
            HP_actual=makeHeatplot(tracks(:,2:3),kernelSize,poolCoords.imSize,[0 0]);
            %imagesc(HP_actual)
            %axis equal
            
            %%% Get random data            
            perm_matrix=zeros(nPerm,3);
            t0=clock;
            for iPerm=1:nPerm
                tracks_random=[];
                for iTrack=1:length(selectedTracks)
                    track=AllTracks(selectedTracks(iTrack)).data(:,2:3);
                    randomtrack=randomizeTrack(track,poolCoords);
                    tracks_random=cat(1,tracks_random,randomtrack);
                end
                
                tracks_random(:,1)=tracks_random(:,1)-min(tracks_random(:,1))+1;
                tracks_random(:,2)=tracks_random(:,2)-min(tracks_random(:,2))+1;
                HP_random=makeHeatplot(tracks_random,kernelSize,poolCoords.imSize,[1 0]);
                perm_matrix(iPerm,:)=[iPerm mean(HP_random(:)) std(HP_random(:))];
                %imagesc(HP_random)
                %axis equal                
                progress(iPerm,nPerm,t0)
            end
            
            MU=mean(perm_matrix(:,2));
            SIGMA=mean(perm_matrix(:,3));
            
            heatplot_norm=(HP_actual-MU)/SIGMA;
                        
            A=heatplot_norm;
            Ymin=min(A(:));
            
            if saveIt==0
                %%
                subplot(nRows,nCols,iGroup)
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
            
            circle((platForm_coords-min_value)*rescaleFactor,platForm_radius*rescaleFactor,1000,'k-',lineWidth);
            if length(platFormCoords.coords)==2
                circle((platFormCoords.coords(2).center-min_value)*rescaleFactor,platFormCoords.coords(2).radius*rescaleFactor,1000,'k--',lineWidth);
            end
            hold off
            
            colormap jet
            %colormap hot
            set(im,'AlphaData',mask)
            
            %%
            imageHandles(iGroup)=im;                                    
            
            if saveIt==1
                savec(saveName)
                print(gcf,'-dpng','-r300',saveName)
            else
                set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
                %set(gca,'fontsize',6)
                t=title(groupName,'FontSize',6);
                drawnow
                %set(t,'FontSize',6)
            end
        end
        
    end
end


%%
if saveIt==0
    for iGroup=1:nGroups
        maxVal=5;
        H=get(imageHandles(iGroup),'parent');
        set(H,'Clim',[-maxVal maxVal])
    end
end