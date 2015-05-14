clear all
clc


filename='StijnS_ProbeData_sorted.mat';
loadName=fullfile('datasets',filename);
% loadName=fullfile('dataSets_17parameters',filename);
load(loadName)

%% Prepare arena
clf
plot(poolCoords.center(1),poolCoords.center(2),'m*','markerSize',10)
hold on
circle(poolCoords.center,poolCoords.radius,1000,'k-',3);

for index=1:length(poolCoords.annulusRadii)
    circle(poolCoords.center,poolCoords.annulusRadii(index),1000,'r:',2);
end
%plot(endCoords(:,1),endCoords(:,2),'co')
circle(platFormCoords.current,platFormCoords.radius,1000,'k-',3);
circle(platFormCoords.current,platFormCoords.radius*2.5,1000,'r-',3);
if isfield(platFormCoords,'previous')
    circle(platFormCoords.previous,platFormCoords.radius,1000,'k--',3);
    circle(platFormCoords.previous,platFormCoords.radius*2.5,1000,'r--',3);
end
plot([poolCoords.center(1) poolCoords.center(1)],[0 154],'k-')
plot([0 207],[poolCoords.center(2) poolCoords.center(2)],'k-')

if isfield(platFormCoords,'platformPositions')
    for index=1:platFormCoords.nPositions
        circle(platFormCoords.platformPositions(index,:),platFormCoords.radius,1000,'k-',3);
    end
end

axis equal
%axis([0 207 0 154])
axis ij
box off

%%% Play track
trackNr=21;
sel=AllTracks.data(:,2)==trackNr;
X=AllTracks.data(sel,5);
Y=AllTracks.data(sel,6);
N=length(X);
Latency=getLatencyProbe(AllTracks.data(sel,4:6),platFormCoords);
plot(X(1:N),Y(1:N),'.-')
plot(X(1:Latency),Y(1:Latency),'r-','lineWidth',2)
hold off

