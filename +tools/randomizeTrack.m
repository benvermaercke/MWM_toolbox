function randomtrack = randomizeTrack(track,poolCoords)

nStep=size(track,1);

% get angels and stepsizes of this track
M=[track vertcat(track(1,:),track(1:end-1,:))];
[angles_actual, stepSize_actual]=cart2pol(diff(M(:,[1 3]),[],2),diff(M(:,[2 4]),[],2));
angles_actual=(unwrap(angles_actual));

%%% Parameters can be set here, or alternatively, estimated from actual
%%% track, or from average taken from an example group of tracks.

curStep=stepSize_actual(1);
stepSigma=std(diff(stepSize_actual)); % 0 fixed step size, as used in bovet&henhamou 1988
stepBias=.1; % don't let stepSize become negative!
angleBias=0;

%%% Set starting values
curPos=track(1,:);
curAngle=pi-angles_actual(2);

dataMatrix=zeros(nStep,7);
for step=1:nStep
    % select stepSize procedure
    switch 1
        case 1 % use actual stepSize
            curStep=stepSize_actual(step);
            if curStep==0
                curStep=.01;
            end
            
            step_change=0;
        case 2 % use random stepSize
            step_change=randn*stepSigma;
            curStep=curStep+step_change;
            curStep(curStep<stepBias)=stepBias;
    end
    
    % choose angle from conditional distribution (larger stepSize,
    % smaller change in heading!)
    %angleSigma_est=curStep*-.1593+1.0415; % based on fit values
    %angleSigma_est=curStep*-.2171+1.1948; % based on second fit values
    p=[0.0574 -0.5638 1.6127]; % based on quadratic fit values
    angleSigma_est=polyval(p,curStep); % based on second fit values
    
    angle_change=randn*angleSigma_est+angleBias;
    curAngle=curAngle+angle_change;
    
    [xShift, yShift]=pol2cart(curAngle,curStep);    
    [TH, R]=cart2pol(curPos(1)+xShift-poolCoords.center(1),curPos(2)+yShift-poolCoords.center(2));
        
    tic
    %replace by inpolygon implementation
    if isfield(poolCoords,'radius')
        while R>poolCoords.radius % choose random angle from [-pi/4 pi/4] range when wall is hit
            angle_change=rand*pi/2-pi/4;
            %angle_change=randn*pi/4;
            curAngle=curAngle+angle_change;
            [xShift, yShift]=pol2cart(curAngle,curStep);
            [TH, R]=cart2pol(curPos(1)+xShift-poolCoords.center(1),curPos(2)+yShift-poolCoords.center(2));
            %disp([curStep curAngle TH R])
            if toc>.2
                %die
                curStep=curStep+.01;
            elseif toc>2
                die
            end
        end
    elseif isfield(poolCoords,'poly_rect')
        while ~inpolygon(curPos(1)+xShift,curPos(2)+yShift,poolCoords.poly_rect(1,:),poolCoords.poly_rect(2,:))
            angle_change=rand*pi/2-pi/4;
            curAngle=curAngle+angle_change;
            [xShift, yShift]=pol2cart(curAngle,curStep);
            
            if toc>.2
                %die
                disp('changing step size')
                curStep=curStep+.01;
            elseif toc>2
                die
            end
        end
    else
        die
    end
    curPos=curPos+[xShift yShift];
    dataMatrix(step,:)=[step curPos curStep step_change curAngle angle_change];
end

randomtrack=dataMatrix(:,2:3);