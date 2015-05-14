function Latency=getLatencyProbe(swimTrack,platFormCoords)

X=swimTrack(:,2);
Y=swimTrack(:,3);

PF=platFormCoords.current;

[phi rho]=cart2pol(X-PF(1),Y-PF(2));

x=find(rho<platFormCoords.radius,1,'first');
if isempty(x)
    x=length(X);
end
Latency=swimTrack(x,1);