function [trackProps vector]= getTrackStats_used(varargin)

if nargin>=1
    track=varargin{1};
end

if nargin>=2
    %centerCoords=varargin{2};
    poolCoords=varargin{2};
    centerCoords=poolCoords.center;
    radius=poolCoords.radius;
end

if nargin>=3
    %radius=varargin{3};
end

if nargin>=4
    platformCoords=varargin{4};    
    %platformCoords=platformCoords.current;
end

% Get timeline
T=track(:,1);

% Get sampling rate
samplingRate=round(1/mean(diff(T)));

% get starting position
startPosition=track(1,2:3);

% get angels and stepsizes of this track
M=[track(:,2:3) vertcat(startPosition,track(1:end-1,2:3))];
[angles_actual stepSize_actual]=cart2pol(diff(M(:,[1 3]),[],2),diff(M(:,[2 4]),[],2));
angles_actual_unwrap=(unwrap(angles_actual));

% get initial heading
startHeading=angles_actual_unwrap(2);

% convert to polar coordinates relative to starting position
[PHI_start RHO_start]=cart2pol(track(:,2)-startPosition(1),track(:,3)-startPosition(2));
[PHI_start2platform RHO_start2platform]=cart2pol(platformCoords.current(1)-startPosition(1),platformCoords.current(2)-startPosition(2));

% convert to centralized polar coordinates to simplify circular measures
[PHI_center RHO_center]=cart2pol(track(:,2)-centerCoords(1),track(:,3)-centerCoords(2));

% convert to polar coordinates relative to platform
[PHI_platform RHO_platform]=cart2pol(track(:,2)-platformCoords.current(1),track(:,3)-platformCoords.current(2));

% convert to polar coordinates relative to swim path centroid
centroid=mean(track(:,2:3));
[PHI_centroid RHO_centroid]=cart2pol(track(:,2)-centroid(1),track(:,3)-centroid(2));


% pathlength
pathlength=sum(stepSize_actual);

% latency
latency=T(end);

% velocity
velocity=pathlength/(latency*samplingRate);

% construct ideal swimTrack
idealLatency=RHO_platform(1)/(velocity*samplingRate); % time needed to get to platform at average speed

% cumulative search error
newStartpoint=round(idealLatency*samplingRate);
if newStartpoint>0
    avgMatrix=[round(T(newStartpoint:end)) RHO_platform(newStartpoint:end)];
    avgDistances=pivotTable(avgMatrix,1,'mean',2);
    cumSearchError=sum(avgDistances);
else
    cumSearchError=0;
end

% abs heading error
absHeadingError=sum(abs(diff([angles_actual PHI_platform],[],2)));

% mean dist to swim path centroid
meanDistCentroid=mean(RHO_centroid);

% mean dist to target
meanDistTarget=mean(RHO_platform);

% mean dist to pool center
meanDistPoolCenter=mean(RHO_center);

% %time in goal corridor
timeInTargetCorridor=mean(abs(PHI_start-PHI_start2platform)<0.3491*2)*100;

% %time in zone around target
%timeInTargetZone=mean(RHO_platform<20)*100;
timeInTargetZone=mean(RHO_platform<platformCoords.targetZoneRadius)*100;


% %time in zones around center
if ~isfield(poolCoords,'annulusRadii')
    timeInOuterWallZone=mean(RHO_center>radius*.85)*100; % >.85
    timeInCloserWallZone=mean(between(RHO_center,[radius*.64 radius*.85]))*100; % .64-.85
    timeInTargetAnnulus=mean(between(RHO_center,[radius*.42 radius*.64]))*100; % .42-.64
    timeInCenterZone=mean(RHO_center<radius*.42)*100; % <.42
else
    annulusRadii=poolCoords.annulusRadii;
    timeInCenterZone=mean(RHO_center<=annulusRadii(1))*100;
    timeInTargetAnnulus=mean(between(RHO_center,annulusRadii(1:2)))*100;
    timeInCloserWallZone=mean(between(RHO_center,annulusRadii(2:3)))*100;
    timeInOuterWallZone=mean(RHO_center>=annulusRadii(3))*100;
end

% mean heading => turning bias
meanHeading=mean(diff(angles_actual_unwrap));

% amount of heading => turning crazy
turningAmount=sum(abs(diff(angles_actual_unwrap)));

% amount of turning (sigma alpha)
stdHeading=std(diff(angles_actual_unwrap));

%diff(angles_actual_unwrap)
% sinuosity
%sinuosity=stdHeading/mean(std(stepSize_actual));
sinuosity=stdHeading/sqrt(mean(stepSize_actual)); % S=sigma/sqrt(stepLength)

%%% Collect variables
trackProps.pathlength=pathlength;
trackProps.latency=latency;
trackProps.velocity=velocity;
trackProps.startPosition=startPosition;
trackProps.startHeading=startHeading;
trackProps.idealLatency=idealLatency;
trackProps.cumSearchError=cumSearchError;
trackProps.absHeadingError=absHeadingError;
trackProps.meanDistCentroid=meanDistCentroid;
trackProps.meanDistTarget=meanDistTarget;
trackProps.meanDistPoolCenter=meanDistPoolCenter;
trackProps.timeInTargetCorridor=timeInTargetCorridor;
trackProps.timeInTargetZone=timeInTargetZone;
trackProps.timeInOuterWallZone=timeInOuterWallZone;
trackProps.timeInCloserWallZone=timeInCloserWallZone;
trackProps.timeInTargetAnnulus=timeInTargetAnnulus;
trackProps.timeInCenterZone=timeInCenterZone;
trackProps.meanHeading=meanHeading;
trackProps.turningAmount=turningAmount;
trackProps.stdHeading=stdHeading;
trackProps.sinuosity=sinuosity;

vector=[pathlength latency velocity cumSearchError absHeadingError meanDistCentroid meanDistTarget meanDistPoolCenter timeInTargetCorridor timeInTargetZone timeInOuterWallZone timeInCloserWallZone timeInTargetAnnulus timeInCenterZone turningAmount stdHeading sinuosity];

