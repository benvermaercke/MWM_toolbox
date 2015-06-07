clear all
%clc

header_script_MWM

plotIt=1;
%saveIt=1;

im_size=[200 200];

try
    loadName=fullfile(data_folder,'dataSets',databaseName);
catch
    loadName=fullfile(data_folder,'dataSets_17parameters',databaseName);
end
load(loadName,'AllTracks','nTracks','demographics')


%arena_IDs=demographics(:,6);
%arena_ID_vector=unique(arena_IDs);
%nArena=length(arena_ID_vector);
%arena_selector=1:nArena

M=cat(1,AllTracks.(use_data_field));
X=M(:,data_cols(1));
Y=M(:,data_cols(2));

%%% find center of points
switch 3
    case 1
        centerX=mean([min(X) max(X)]);
        centerY=mean([min(Y) max(Y)]);
    case 2
        centerX=mean([prctile(X,.4) prctile(X,99.6)]);
        centerY=mean([prctile(Y,.4) prctile(Y,99.6)]);
    case 3
        %%        
        H=makeHeatplot([X Y],15,im_size,[0 0]);
        TH=prctile(H(:),65);
        H_TH=H>TH;
        H_TH=imfill(H_TH,'holes');
        imshow(H_TH,[])
        H_shrink=imerode(H_TH,[0 1 0; 1 1 1;0 1 0]);
        H_edge=H_TH-H_shrink;
        [edge_X,edge_Y]=find(H_edge==1);
        ellipse_t=fit_ellipse(edge_X,edge_Y);
        centerX=ellipse_t.X0_in;%+min(X);
        centerY=ellipse_t.Y0_in;%+min(Y);
    case 4
        H=makeHeatplot([X Y],15,im_size,[1 0]);
        TH=prctile(H(:),65);
        H_TH=H>TH;
        H_TH=imfill(H_TH,'holes');
                
        centerX=mean([prctile(X,.4) prctile(X,99.6)]);
        centerY=mean([prctile(Y,.4) prctile(Y,99.6)]);
        imshow(H_TH,[])
        hold on
        plot(centerX,centerY,'m*')
        hold off
end
arenaCoords.center=[centerX centerY];
arenaCoords.top=[centerX min(Y)];
arenaCoords.bottom=[centerX max(Y)];
arenaCoords.left=[min(X) centerY];
arenaCoords.right=[max(X) centerY];
%poolCoords.imSize=[154 207];
arenaCoords.im_size=im_size;
arenaCoords.mask=H_TH;

%% calculate optimal radius of pool in pixels
[angles, dist_vector]=cart2pol(X-centerX,Y-centerY);
switch 3
    case 1
        %radius=max(abs(dist_vector));
        radius=prctile(abs(dist_vector),99.6);
    case 2
        radiusX=max(X)-centerX;
        radiusY=max(Y)-centerY;
        radius=max([radiusX radiusY]);
    case 3
        radius=mean([ellipse_t.long_axis ellipse_t.short_axis])/2;
end
%poolCoords.center=[ellipse_t.X0 ellipse_t.Y0];
arenaCoords.radius=radius;

%% find all last points of each successful track
% does not take into account the existence of probe trials.
endCoords=zeros(nTracks,4);
for iTrack=1:nTracks
    track_data=AllTracks(iTrack).(use_data_field);
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
targetCoords=struct;
for iClust=1:nClust
    sel=mapping==iClust;
    switch 2
        case 1
            targetCoords.coords(iClust).center=median(endCoords(sel,3:4));
            targetCoords.coords(iClust).radius=mean([mean(endCoords(sel,3:4))-prctile(endCoords(sel,3:4),1) prctile(endCoords(sel,3:4),99)-mean(endCoords(sel,3:4))]);
            targetCoords.coords(iClust).targetZoneRadius=targetCoords.coords(iClust).radius*2.5;
        case 2
            %%            
%             H=makeHeatplot(endCoords(sel,3:4),2);
%             TH=prctile(H(:),10);
%             H_TH=H>TH;
%             
%             H_shrink=imerode(H_TH,[0 1 0; 1 1 1;0 1 0]);
%             H_edge=H_TH-H_shrink;
%             [edge_X,edge_Y]=find(H_edge==1);
%             ellipse_t=fit_ellipse(edge_X,edge_Y);
%             platFormCoords.coords(iClust).center=[ellipse_t.X0_in+min(endCoords(sel,3)) ellipse_t.Y0_in+min(endCoords(sel,4))];
            ellipse_t=fit_ellipse(endCoords(sel,3),endCoords(sel,4));
            imshow(H_edge,[])
            
            targetCoords.coords(iClust).center=[ellipse_t.X0_in ellipse_t.Y0_in];
            targetCoords.coords(iClust).radius=mean([ellipse_t.long_axis ellipse_t.short_axis])/2;
            targetCoords.coords(iClust).targetZoneRadius=targetCoords.coords(iClust).radius*2.5;
        case 3 % bivariate normal fit
            %%
            M=endCoords(:,3:4);
            tic
            F=fitgmdist(M,2);
            targetCoords.coords(iClust).center=F.mu(iClust,:);
            targetCoords.coords(iClust).radius=F.Sigma(1,1,iClust)/2;
            targetCoords.coords(iClust).targetZoneRadius=targetCoords.coords(iClust).radius*2.5;
            toc
    end
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

targetCoords.PF_matrix=PF_matrix;

%%% Set annulus radii
PF_pos01=targetCoords.coords(1);
platForm2center=calc_dist([arenaCoords.center PF_pos01.center]);
centerAnnulus=platForm2center-PF_pos01.radius;
platFormAnnulus=platForm2center+PF_pos01.radius;
peripheryAnnulus=platForm2center+PF_pos01.radius*2.5;
arenaCoords.annulusRadii=[centerAnnulus platFormAnnulus peripheryAnnulus];

%%% overwrite parameters in the datafile
if saveIt==1
    %%
    save(loadName,'arenaCoords','targetCoords','-append')
    disp(['Arena and target coordinates were saved to data file: ' loadName])
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
    plot(arenaCoords.center(1),arenaCoords.center(2),'m*','markerSize',10)
    circle(arenaCoords.center,arenaCoords.radius,1000,'k-',3);
    
    for index=1:length(arenaCoords.annulusRadii)
        circle(arenaCoords.center,arenaCoords.annulusRadii(index),1000,'r:',2);
    end
    plot(endCoords(:,3),endCoords(:,4),'co')
    for iPF=1:length(targetCoords.coords)
        circle(targetCoords.coords(iPF).center,targetCoords.coords(iPF).radius,1000,'k-',3);
        circle(targetCoords.coords(iPF).center,targetCoords.coords(iPF).radius*2.5,1000,'r-',3);
    end
    if isfield(targetCoords,'previous')
        circle(targetCoords.previous,targetCoords.radius,1000,'k--',3);
        circle(targetCoords.previous,targetCoords.radius*2.5,1000,'r--',3);
    end
    %plot([poolCoords.center(1) poolCoords.center(1)],[0 154],'k-')
    %plot([0 207],[poolCoords.center(2) poolCoords.center(2)],'k-')
    plot([centerX centerX],[centerY-160 centerY+160],'k-')
    plot([centerX-160 centerX+160],[centerY centerY],'k-')
    
    if isfield(targetCoords,'platformPositions')
        for index=1:targetCoords.nPositions
            circle(targetCoords.platformPositions(index,:),targetCoords.radius,1000,'k-',3);
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


