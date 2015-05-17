clear all
%clc

header_script_MWM

platform_present=1;
plotIt=1;
overwrite=0;

% %filename='ACL_Reference_memory_acquisition_track.mat';
% filename='ACL_Reversal_acquisition_track.mat';
% if platform_present==0
%     filename_acq='ACL_Amira_Acq.mat';
%     %filename_acq=subFolderNames{filename_acq_index}
% end

loadName=fullfile('dataSets',databaseName);
% loadName=fullfile('dataSets_17parameters',filename);
load(loadName,'AllTracks','nTracks','demographics','TrackInfo')

M=cat(1,AllTracks.data);
X=M(:,2);
Y=M(:,3);

%%% find center of points
switch 1
    case 1
        centerX=mean([min(X) max(X)]);
        centerY=mean([min(Y) max(Y)]);
    case 2
        centerX=mean([prctile(X,.4) prctile(X,99.6)]);
        centerY=mean([prctile(Y,.4) prctile(Y,99.6)]);
end
poolCoords.center=[centerX centerY];
poolCoords.top=[centerX min(Y)];
poolCoords.bottom=[centerX max(Y)];
poolCoords.left=[min(X) centerY];
poolCoords.right=[max(X) centerY];
poolCoords.imSize=[154 207];

%% calculate optimal radius of pool in pixels
[angles dist_vector]=cart2pol(X-centerX,Y-centerY);
switch 2
    case 1
        %radius=max(abs(dist_vector));
        radius=prctile(abs(dist_vector),99.6);
    case 2
        radiusX=max(X)-centerX;
        radiusY=max(Y)-centerY;
        radius=max([radiusX radiusY]);
end
poolCoords.radius=radius;

%% find all last points of each track
endCoords=zeros(nTracks,4);
for iTrack=1:nTracks
    track_data=AllTracks(iTrack).data;
    endCoords(iTrack,:)=[iTrack size(track_data,1) track_data(end,2:3)];
end
failure_trials=endCoords(:,2)==max(endCoords(:,2));
endCoords(failure_trials==1,:)=[];
[mean(endCoords(:,3:4)) std(endCoords(:,3:4))]

%%
nPlatform_pos=4;
colors={'r','g','b','k','m','c'};
vector=zeros(nPlatform_pos,1);
for iPF=1:nPlatform_pos
    mapping=kmeans(endCoords(:,3:4),iPF);
    vector(iPF)=mean(pivotTable([mapping endCoords(:,3:4)],1,'std',2));
    
    subplot(3,2,iPF)    
    for iClust=1:iPF
        sel=mapping==iClust;
        plot(endCoords(sel,3),endCoords(sel,4),'color',colors{iClust},'marker','.')
        hold on
    end
    hold off
    axis([-300 300 -300 300])
    axis square 
    box off
end

subplot(3,2,[5 6])
bar(vector)
nClust=find(vector<5,1,'first');
mapping=kmeans(endCoords(:,3:4),nClust);
if nClust==2
    if mapping(1)==nClust
        mapping=nClust+1-mapping;
    end
end

%%
PF_allocation=NaN(nTracks,1);
PF_allocation(failure_trials==0)=mapping;

PF_matrix=[demographics PF_allocation(:)];

nFolders=length(unique(PF_matrix(:,1)));

for iFolder=1:nFolders
    sel=PF_matrix(:,1)==iFolder;
    PF_matrix(sel,6)=fillTheGaps2(PF_matrix(sel,6));
end

%M=AllTracks.data;
% lastRows=[unique(M(:,2)) pivotTable(M,2,'max',3)];
% endCoordsSelection=lastRows(:,2)<500;
% lastRows=lastRows(endCoordsSelection,:);
% 
% endCoords=zeros(size(lastRows,1),2);
% t0=clock;
% for index=1:size(lastRows,1)
%     progress(index,size(lastRows,1),t0)
%     endCoords(index,:)=M(M(:,2)==lastRows(index,1)&M(:,3)==lastRows(index,2),5:6);
% end

%% Calculate population preference for each quadrant
sel=between(AllTracks.data(:,4),[0 32]+4*0);
X_slice=AllTracks.data(sel,5);
Y_slice=AllTracks.data(sel,6);

Q1=mean(X_slice<centerX&Y_slice<centerY);
Q2=mean(X_slice>centerX&Y_slice<centerY);
Q3=mean(X_slice<centerX&Y_slice>centerY);
Q4=mean(X_slice>centerX&Y_slice>centerY);
quadrants_sorted=[Q1 Q2 Q3 Q4];

subplot(221)
plot(X_slice,Y_slice,'.')
hold on
plot([centerX centerX],[centerY-160 centerY+160],'k-')
plot([centerX-160 centerX+160],[centerY centerY],'k-')
text(centerX-100,centerY-60,'Q1')
text(centerX+70,centerY-60,'Q2')
text(centerX-100,centerY+60,'Q3')
text(centerX+70,centerY+60,'Q4')
hold off
axis equal
if MWMtype==2
    axis([-207 207 -154 154]/2)
else
    axis([0 207 0 154])
end
box off
axis ij

subplot(222)
pie(quadrants_sorted,quadrants_sorted==max(quadrants_sorted),{'Q1','Q2','Q3','Q4'})

for index=1:25
    sel=between(AllTracks.data(:,4),[0 4]+4*(index-1));
    X_slice=AllTracks.data(sel,5);
    Y_slice=AllTracks.data(sel,6);
    
    Q1=mean(X_slice<centerX&Y_slice<centerY);
    Q2=mean(X_slice>centerX&Y_slice<centerY);
    Q3=mean(X_slice<centerX&Y_slice>centerY);
    Q4=mean(X_slice>centerX&Y_slice>centerY);
    dataMatrix(index,:)=[Q1 Q2 Q3 Q4];
end

subplot(2,2,[3 4])
p=plot(dataMatrix);
box off
legend(p,{'Q1','Q2','Q3','Q4'})

%%
sel=AllTracks.data(:,4)==1;

D=AllTracks.data(sel,4:6);

%%
switch platform_present
    case 1
        clear platFormCoords
        if isempty(lastRows)
            %platFormCoords.current=[138 102];
            %platFormCoords.current=poolCoords.center-[27.5 27.5];
            switch MWMtype
                case 1
                    switch 1
                        case 1
                            platFormCoords.current=poolCoords.center+[27.5 27.5];
                        case 2
                            % 137.752; 102.15
                            platFormCoords.current= [137.752 102.15];% straal 7.394
                        case 3
                            platFormCoords.current= [33.12 -22.99];
                    end
                    
                    %platFormCoords.radius= 7.394;
                    platFormCoords.radius=8.49;
                    platFormCoords.targetZoneRadius= 19.2500;
                    
                    
                    
                    % 110.092; 77.777
                    % straal 76.133
                    %poolCoords.center=[107.3558 75.8600];
                    %poolCoords.center= [110.092 77.777];
                    %poolCoords.top= [78.8769 5];
                    %poolCoords.bottom= [78.8769 149.3009];
                    %poolCoords.left= [5 76.9089];
                    %poolCoords.right= [152.6031 76.9089];
                    %poolCoords.imSize= [154 207];
                    %poolCoords.radius= 76.133;
                    %poolCoords.radius= 73.9442;
                    %poolCoords.annulusRadii= [34.1517 49.5517 61.1017];
                    
                case 2
                    coordsPositive=0;
                    switch coordsPositive
                        case 1
                            % 137.752; 102.15
                            % straal 7.394
                            platFormCoords.current= [137.752 102.15];
                            platFormCoords.radius= 7.394;
                            platFormCoords.targetZoneRadius= 19.2500;
                            
                            % 110.092; 77.777
                            % straal 76.133
                            poolCoords.center= [110.092 77.777];
                            poolCoords.top= [78.8769 5];
                            poolCoords.bottom= [78.8769 149.3009];
                            poolCoords.left= [5 76.9089];
                            poolCoords.right= [152.6031 76.9089];
                            poolCoords.imSize= [154 207];
                            poolCoords.radius= 76.133;
                            poolCoords.annulusRadii= [34.1517 49.5517 61.1017];
                            
                        case 0
                            % midden en straal van pool en platform
                            % platform: midden -12.17; 29.84 / straal 8.4
                            platFormCoords.current= [-12.17 29.84];
                            platFormCoords.radius= 8.4;
                            platFormCoords.targetZoneRadius= 19.2500;
                            
                            % pool: midden 19.12; 1.159 / straal 75.031
                            %poolCoords.center= [19.12 1.159];
                            %poolCoords.top= [78.8769 5];
                            %poolCoords.bottom= [78.8769 149.3009];
                            %poolCoords.left= [5 76.9089];
                            %poolCoords.right= [152.6031 76.9089];
                            %poolCoords.imSize= [154 207];
                            %poolCoords.radius= 75.031;
                            %poolCoords.annulusRadii= [34.1517 49.5517 61.1017];
                    end
                otherwise
                    platFormCoords.current=poolCoords.center+[27.5 27.5];
            end
            %platFormCoords.current=[46.9999 107.7878];
            
            %platFormCoords.current=[107.3998 45.4256];
            %platFormCoords.previous=[46.9999 107.7878];
            platFormCoords.radius=7;
        else
            switch 2
                case 0
                case 1
                    platFormCoords.current=median(endCoords,1);
                case 2
                    pcrtiles=[1 99];
                    platFormCoords.current=[mean(prctile(endCoords(:,1),pcrtiles)) mean(prctile(endCoords(:,2),pcrtiles))];
                case 3
                    nTotal=875;
                    windowSize=175;
                    nOverlap=0;
                    
                    allocation=1:nTracks;
                    allocation=allocation(endCoordsSelection);
                    windows=makeSlidingWindows(nTotal,windowSize,nOverlap);
                    
                    nPositions=size(windows,1);
                    for group_index=1:nPositions
                        platFormCoords.platformAllocation(windows(group_index,1):windows(group_index,2),1)=group_index;
                        coords_subset=endCoords(between(allocation,[windows(group_index,1) windows(group_index,2)]),:);
                        %platFormCoords.platformPositions(group_index,:)=median(coords_subset,1);
                        
                        pcrtiles=[1 99];
                        platFormCoords.platformPositions(group_index,:)=[mean(prctile(coords_subset(:,1),pcrtiles)) mean(prctile(coords_subset(:,2),pcrtiles))];
                    end
                    platFormCoords.nPositions=nPositions;
                    platFormCoords.current=platFormCoords.platformPositions(1,:);
                case 4
            end
            
            [Theta Rho]=cart2pol(endCoords(:,1)-platFormCoords.current(1),endCoords(:,2)-platFormCoords.current(2));
            
            %%
            switch 0
                case 0
                    platFormCoords.radius=7.7;
                case 1 % use distribution
                    platFormCoords.radius=prctile(Rho,99);
                case 2 % use spread (sensitive to outliers)
                    platFormCoords.radius=std(Rho)*2;
                case 3
                    polar(Theta,Rho,'.')
                    axis ij
            end
        end
    case 0 % copy platform position from acquisition files
        load(fullfile('dataSets',filename_acq),'platFormCoords')
end



switch 1
    case 0
        annulusRadii=poolCoords.radius*[.42 .64 .85];
    case 1
        platForm2center=calc_dist([poolCoords.center platFormCoords.current]);
        centerAnnulus=platForm2center-platFormCoords.radius;
        platFormAnnulus=platForm2center+platFormCoords.radius;
        peripheryAnnulus=platForm2center+platFormCoords.radius*2.5;
        annulusRadii=[centerAnnulus platFormAnnulus peripheryAnnulus];
end

platFormCoords.targetZoneRadius=platFormCoords.radius*2.5;
poolCoords.annulusRadii=annulusRadii;

%%% overwrite parameters in the datafile
if overwrite==1
    %%
    save(loadName,'poolCoords','platFormCoords','-append')
    disp(['Pool and platform coordinates were saved to data file: ' loadName])
end


%%
if plotIt==1
    %N=20;
    N=length(X);
    %N=257;
    
    clf
    hold on
    plot(X(1:N),Y(1:N),'.-')
    plot(poolCoords.center(1),poolCoords.center(2),'m*','markerSize',10)
    circle(poolCoords.center,poolCoords.radius,1000,'k-',3);
    
    for index=1:length(annulusRadii)
        circle(poolCoords.center,annulusRadii(index),1000,'r:',2);
    end
    plot(endCoords(:,1),endCoords(:,2),'co')
    circle(platFormCoords.current,platFormCoords.radius,1000,'k-',3);
    circle(platFormCoords.current,platFormCoords.radius*2.5,1000,'r-',3);
    if isfield(platFormCoords,'previous')
        circle(platFormCoords.previous,platFormCoords.radius,1000,'k--',3);
        circle(platFormCoords.previous,platFormCoords.radius*2.5,1000,'r--',3);
    end
    %plot([poolCoords.center(1) poolCoords.center(1)],[0 154],'k-')
    %plot([0 207],[poolCoords.center(2) poolCoords.center(2)],'k-')
    plot([centerX centerX],[centerY-160 centerY+160],'k-')
    plot([centerX-160 centerX+160],[centerY centerY],'k-')
    
    if isfield(platFormCoords,'platformPositions')
        for index=1:platFormCoords.nPositions
            circle(platFormCoords.platformPositions(index,:),platFormCoords.radius,1000,'k-',3);
        end
    end
    hold off
    axis equal
    %axis([0 207 0 154])
    axis([centerX-100 centerX+100 centerY-100 centerY+100])
    axis ij
    box off
end

