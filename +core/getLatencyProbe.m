function Latency=getLatencyProbe(swimTrack,platFormCoords)

X=swimTrack(:,2);
Y=swimTrack(:,3);

PF=platFormCoords.current;

[phi, rho]=cart2pol(X-PF(1),Y-PF(2));

x=find(rho<platFormCoords.radius,1,'first');
if isempty(x)
    x=length(X);
end
Latency=swimTrack(x,1);

if 0
    %%
    subplot(121)
    plot(X,Y,'b')
    hold on
    plot(PF(1),PF(2),'m*')
    hold off
    subplot(122)
    plot(rho)
    hold on
    plot([0 length(rho)],[platFormCoords.radius platFormCoords.radius],'r-')
    hold off
end