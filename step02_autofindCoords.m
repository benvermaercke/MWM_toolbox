clear all
%clc

header_script_MWM

plotIt=1;
%saveIt=0;

loadName=fullfile('dataSets',databaseName);
% loadName=fullfile('dataSets_17parameters',filename);
load(loadName,'AllTracks','nTracks','demographics')

M=cat(1,AllTracks.data);
X=M(:,2);
Y=M(:,3);

%%% find center of points
switch 2
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
switch 1
    case 1
        %radius=max(abs(dist_vector));
        radius=prctile(abs(dist_vector),99.6);
    case 2
        radiusX=max(X)-centerX;
        radiusY=max(Y)-centerY;
        radius=max([radiusX radiusY]);
end
poolCoords.radius=radius;

%% find all last points of each successful track
% does not take into account the existence of probe trials.
endCoords=zeros(nTracks,4);
for iTrack=1:nTracks
    track_data=AllTracks(iTrack).data;
    endCoords(iTrack,:)=[iTrack size(track_data,1) track_data(end,2:3)];
end
failure_trials=endCoords(:,2)==max(endCoords(:,2));
endCoords(failure_trials==1,:)=[];

%%% Test how many possible platform positions were used
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

%%% Find most reasonable number of clusters
nClust=find(vector<5,1,'first');
mapping=kmeans(endCoords(:,3:4),nClust);
if nClust==2
    if mapping(1)==nClust
        mapping=nClust+1-mapping;
    end
end

%% For each cluster (=platform position), find center and radius
platFormCoords=struct;
for iClust=1:nClust
    sel=mapping==iClust;
    platFormCoords.coords(iClust).center=median(endCoords(sel,3:4));
    platFormCoords.coords(iClust).radius=mean([mean(endCoords(sel,3:4))-prctile(endCoords(sel,3:4),1) prctile(endCoords(sel,3:4),99)-mean(endCoords(sel,3:4))]);    
    platFormCoords.coords(iClust).targetZoneRadius=platFormCoords.coords(iClust).radius*2.5;
end

%% Assign a platform location to each track, on a by folder basis. Using the known end positions of successful tracks
% could be an issue if no animal finds the platform...
PF_allocation=NaN(nTracks,1);
PF_allocation(failure_trials==0)=mapping;

PF_matrix=[demographics PF_allocation(:)];

nFolders=length(unique(PF_matrix(:,1)));

for iFolder=1:nFolders
    sel=PF_matrix(:,1)==iFolder;
    PF_matrix(sel,6)=fillTheGaps2(PF_matrix(sel,6));
end

platFormCoords.PF_matrix=PF_matrix;

%%% Set annulus radii
PF_pos01=platFormCoords.coords(1);
platForm2center=calc_dist([poolCoords.center PF_pos01.center]);
centerAnnulus=platForm2center-PF_pos01.radius;
platFormAnnulus=platForm2center+PF_pos01.radius;
peripheryAnnulus=platForm2center+PF_pos01.radius*2.5;
poolCoords.annulusRadii=[centerAnnulus platFormAnnulus peripheryAnnulus];

%%% overwrite parameters in the datafile
if saveIt==1
    %%
    save(loadName,'poolCoords','platFormCoords','-append')
    disp(['Pool and platform coordinates were saved to data file: ' loadName])
end


%%
if plotIt==1
    %%
    %N=20;
    N=length(X);
    %N=257;
    
    clf
    hold on
    plot(X(1:N),Y(1:N),'.-')
    plot(poolCoords.center(1),poolCoords.center(2),'m*','markerSize',10)
    circle(poolCoords.center,poolCoords.radius,1000,'k-',3);
    
    for index=1:length(poolCoords.annulusRadii)
        circle(poolCoords.center,poolCoords.annulusRadii(index),1000,'r:',2);
    end
    plot(endCoords(:,3),endCoords(:,4),'co')
    for iPF=1:length(platFormCoords.coords)
        circle(platFormCoords.coords(iPF).center,platFormCoords.coords(iPF).radius,1000,'k-',3);
        circle(platFormCoords.coords(iPF).center,platFormCoords.coords(iPF).radius*2.5,1000,'r-',3);
    end
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
    axis equal
    box off
end

