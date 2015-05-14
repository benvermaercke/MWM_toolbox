% We need a new function that takes as input the swimTrack + coordinates of
% the pool (center&radius&platform location). It should return a struct
% containing all possible measures ever conceived:
% - latency
% - path length
% - velocity
% - cum search error
% - abs heading error
% - %time in goal corridor
% - %time in goal zone
% - %time in wallzone/target/center annulus
% - %surface coverage
% - mean turning angle
% - std turning angle
% - sinuosity
% - ...
%
% These can be calculated for each track and will be used in the training
% procedure for an number of SVM's!

clear all
clc


%% Be careful to only load the model once!
nIter=200;
modelName=['models/SVMclassifierMWMdata_nIter_' num2str(nIter) '_oldModel.mat'];
%load(modelName,'classificationStrings')
%die
load(modelName,'SVMmodels','perfMatrix','classificationStrings','COMP','nComp','class_vector')

%%
%filename='ACL_Reference_memory_acquisition_track.mat';
filename='ACL_Reversal_acquisition_track.mat';

%file_index=6;
%subFolderNames={'00_LAMAN_ERT_batch1eval1_acq','01_LAMAN_ERT_batch1eval1_probe','02_LAMAN_ERT_batch1eval2_acq','03_LAMAN_ERT_batch1eval2_probe','04_LAMAN_ERT_batch2eval1_acq','05_LAMAN_ERT_batch2eval1_probe'};
%filename=subFolderNames{file_index}


plotIt=0;
probeData=0; % treat data as probe trial or not
windowType=0; % if >0 => probeData=0
before_or_after=1;

saveIt=1;
writeExcel=1;

saveName=fullfile('dataSets_17parameters',filename);
load(saveName)
allTracks=AllTracks.data;

tracks=unique(allTracks(:,2));
nTracks=length(tracks);

if exist('poolCoords','var')
    centerCoords=poolCoords.center;
    radius=poolCoords.radius;
else
    centerCoords=[109 76];
    radius=75;
    platformCoords=[138 103];
    platformRadius=7;
end

%%% Build SvM matrix by extracting all parameters from every single track
nVars=17;
SVMmatrix=NaN(nTracks,nVars);
class_vector=zeros(nTracks,1);

nTotal=100;
switch windowType
    case 0 % fixed window
        timePoints=[1 500];
        windowTypeName=['fixedWindow_' padZeros(timePoints(1),3) '-' padZeros(timePoints(2),3)];
    case 1 % adjacent windows
        windowSize=20;
        nOverlap=0;
        timePoints=makeSlidingWindows(nTotal,windowSize,nOverlap);
        windowTypeName='adjacentWindows';
    case 2 % sliding windows
        windowSize=25;
        nOverlap=12.5;
        timePoints=makeSlidingWindows(nTotal,windowSize,nOverlap);
        windowTypeName='slidingWindows';
    case 3 % growing window
        stepSize=125; % grows every x/5 seconds
        endPoints=0:stepSize:nTotal;
        timePoints=[zeros(length(endPoints),1) endPoints'];
        windowTypeName='growingWindows';
end
nWindows=size(timePoints,1);

timePoints

%%%
trackAllocation_vector=zeros(nTracks,1);
Latency_vector=zeros(nTracks,1);
samplesUsePerTrack=trackAllocation_vector;
t0=clock;
count=1;
for track_index=1:nTracks
    progress(track_index,nTracks,t0)
    trackNr=tracks(track_index);
    swimTrack=allTracks(ismember(allTracks(:,2),trackNr),4:6);
    for index=1:size(timePoints,1)
        if probeData==0
            timeSelection=between(swimTrack(:,1),timePoints(index,:)-[1 0]);
        else
            Latency=getLatencyProbe(swimTrack,platFormCoords);
            Latency_vector(track_index)=Latency;
            switch before_or_after
                case 1
                    timeSelection=swimTrack(:,1)<=Latency;
                    windowTypeName='a_probeBeforePFcrossing';
                case 2
                    timeSelection=swimTrack(:,1)>Latency;
                    windowTypeName='b_probeAfterPFcrossing';
                case 3 % 20 seconds na
                    timeSelection=swimTrack(:,1)>Latency; %
                    windowTypeName='probeAfterPFcrossing';
                otherwise
                    error('invalide value for ''before_or_after''')
            end
            
            %between(swimTrack(:,1),timePoints(index,:)-[1 0]);
        end
        if sum(timeSelection)>5
            data=swimTrack(timeSelection,:);
            
            samplingRate=round(1/min(diff(data(:,1))));
            if samplingRate>5
                %% Resample data to 5Hz data
                switch 2
                    case 1 % used until 12/09/2013
                        data=myResample(data,samplingRate/5);
                    case 2 % faster
                        target_sampling_rate=5;
                        add_extra_points=100;
                        data_exp=cat(1,repmat(data(1,:),add_extra_points,1),data,repmat(data(end,:),add_extra_points,1));
                        X_resampled=resample(data_exp,target_sampling_rate,samplingRate);
                        data_cut=X_resampled(add_extra_points*target_sampling_rate/samplingRate:end-add_extra_points*target_sampling_rate/samplingRate,:);
                        data=data_cut;
                end
                
                if plotIt==1
                    %%
                    clf
                    line(data(:,2),data(:,3),'lineWidth',2)
                    line(data_cut(:,2),data_cut(:,3),'color','r','marker','.')
                    axis([-154 154 -154 154])
                    axis ij
                end
                
                
            end
            
            if std(data(:,2))<.001
                disp('Data shows no variation')
            else
                %groupNr=platFormCoords.platformAllocation(trackNr);
                platFormCoords_thisTrack=platFormCoords;
                %platFormCoords_thisTrack.current=platFormCoords_thisTrack.platformPositions(groupNr,:);
                [trackProps vector]=getTrackStats_used(data,poolCoords,[],platFormCoords_thisTrack);
                
                %plot(data(:,2),data(:,3))
                %box off
                %title(sci(vector(end)))
                trackAllocation_vector(track_index)=track_index;
                count=count+1;
                
                SVMmatrix(track_index,:)=vector;
                samplesUsePerTrack(track_index)=mean(timeSelection);
            end
        end
    end
end


%%% Design a decision procedure to determine to which class a certain track belongs
decisions=getModelResponse_oldApproach(SVMmodels,SVMmatrix);

%%% Remove track-scorings for empty parts
decisions(trackAllocation_vector==0)=NaN;

%%% histogram
hist(decisions,1:9)
box off
axis square

% %%% find missing tracks
% for iTrack=1:length(trackNames)
%     trackNum_vector(iTrack)=sscanf(trackNames{iTrack},'%*s %*s %04d');
% end
% trackNum_vector([diff(trackNum_vector) 0]==2)+1;

%%% Save results
switch windowType
    case 0
        if saveIt==1
            %% Update Decision in mat-file
            TrialAllocation.data(:,6)=decisions;
            save(saveName,'TrialAllocation','-append')
            disp('Mat file updated!!!')
        end
        
        if writeExcel==1
            
                %% => copy to excel
                folder_vector=TrialAllocation.data(:,1);
                % A=TrialAllocation.data(:,1:2)
                % A=folderList(folder_vector)'
                % trackNames
                % decisions
                blank=NaN(nTracks,1);
                output=[folder_vector blank blank decisions];
                
                folderNames=folderList(folder_vector)';
                folderNumberList={'1';'2'};
                folderNumbers=folderNumberList(folder_vector);
               
                %trackNames;
                
                % [T L]=pivotTable2(output,1,'unique',4);
                % [L T]
                
                templateName='templates/templateOutput.xlsx';
                [a core ext]=fileparts(filename);
                
                %xlsName=['output\' core '_searchStrategies.xlsx'];
                xlsName=['output/' core '_searchStrategies_' windowTypeName '.xlsx'];
                
                % Use template as base for the output file
                copyfile(templateName,xlsName);
                
                % Create placeholder matrix
                excelMatrix=[folder_vector blank blank TrialAllocation.data(:,4:5) blank decisions];
                
                if ispc
                    %%% Write individual track results
                    switch 2
                        case 1
                            xlswrite(xlsName,output,'Sheet1',['A3:D' num2str(nTracks+2)]);
                            xlswrite(xlsName,folderNames,'Sheet1',['B3:B' num2str(nTracks+2)]);
                            xlswrite(xlsName,trackNames,'Sheet1',['C3:C' num2str(nTracks+2)]);
                        case 2
                            %%
                            xlswrite(xlsName,excelMatrix,'Sheet1',['A3:G' num2str(nTracks+2)]);
                            xlswrite(xlsName,folderNames','Sheet1',['B3:B' num2str(nTracks+2)]);
                            xlswrite(xlsName,trackNames,'Sheet1',['C3:C' num2str(nTracks+2)]);
                            xlswrite(xlsName,ID_list,'Sheet1',['F3:F' num2str(nTracks+2)]);
                    end
                    
                    %%% Write results per folder
                    sumData=pivotTable2(output,1,'hist',4,'1:9',1);
                    nFolders=length(folderList);
                    xlswrite(xlsName,folderList','Sheet2',['A2:A' num2str(nFolders+1)]);
                    xlswrite(xlsName,sumData,'Sheet2',['B2:J' num2str(nFolders+1)]);
                else % mac code using xlwrite/java workaround
                    %% add java code to path
                    xlPath=fileparts(which('xlwrite'));
                    javaaddpath(fullfile(xlPath,'poi_library/poi-3.8-20120326.jar'));
                    javaaddpath(fullfile(xlPath,'poi_library/poi-ooxml-3.8-20120326.jar'));
                    javaaddpath(fullfile(xlPath,'poi_library/poi-ooxml-schemas-3.8-20120326.jar'));
                    javaaddpath(fullfile(xlPath,'poi_library/xmlbeans-2.3.0.jar'));
                    javaaddpath(fullfile(xlPath,'poi_library/dom4j-1.6.1.jar'));
                    javaaddpath(fullfile(xlPath,'poi_library/stax-api-1.0.1.jar'));
                    
                    % Create cell array containing all data
                    excelMatrix=[arrayfun(@mean, folder_vector, 'unif', 0) folderNames trackNames arrayfun(@mean, TrialAllocation.data(:,4), 'unif', 0) arrayfun(@mean, TrialAllocation.data(:,5), 'unif', 0) ID_list arrayfun(@mean, decisions, 'unif', 0)];
                    
                    % write individual track data
                    xlwrite(xlsName,excelMatrix,'Sheet1','A3');
                    
                    % write summary data
                    sumData=pivotTable2(output,1,'hist',4,'1:9',1);
                    nFolders=length(folderList);
                    summaryData=[folderList' arrayfun(@mean, sumData, 'unif', 0)];
                    xlwrite(xlsName,summaryData,'Sheet2','A2');
                    %xlswrite(xlsName,folderList','Sheet2',['A2:A' num2str(nFolders+1)]);
                    %xlswrite(xlsName,sumData,'Sheet2',['B2:J' num2str(nFolders+1)]);
                    
                end
                
                disp(['file saved: ' xlsName])
        end
    case 1 % no output written yet
        folder_vector=TrialAllocation.data(:,1);
        %folderNames=folderList(folder_vector)';
        %trackNames
        
        D=[trackAllocation_vector decisions];
        
        output_matrix=[folder_vector pivotTable(D,1,'unique',1) pivotTable(D,1,'',2)];
        
        test=output_matrix;
        test(:,3:end)=ceil(test(:,3:end)/3)
        
        output_allWindows=[];
        for iWindow=1:nWindows
            A=output_matrix;
            A(:,3:end)=ceil(A(:,3:end)/3);
            A=pivotTable2(A,1,'hist',2+iWindow,'1:3',1);
            B=A./repmat(sum(A,2),1,3);
            folderNum=pivotTable(output_matrix,1,'unique',1);
            if all(round(sum(B,2)))==1
                disp('Conversion passed')
            else
                error('Conversion not successful')
            end
            
            output_allWindows=cat(1,output_allWindows,cat(2,repmat(iWindow,size(B,1),1),folderNum,B));
        end
        output_allWindows
end

%
%
%
% %%
% D=[trackAllocation_vector decisions];
% %
% windows=pivotTable2(D,1,'',2,[],1);
% %bar(windows(21,:))
%
% folder_vector=TrialAllocation.data(:,1);
% group_vector=TrialAllocation.data(:,3);
% trial_vector=rem(folder_vector-1,12)+1;
%
% intervals=1:16;
% %intervals=linspace(1,16,4);
% nIntervals=length(intervals);
%
% %D=[group_vector trial_vector ceil(windows(:,[1 6 11 16])/3)];
% D=[group_vector trial_vector ceil(windows(:,intervals)/3)];
% %D=[group_vector trial_vector ceil(windows/3)];
% %
% switch 1
%     case 1
%         nRows=4;
%         nCols=ceil(nIntervals/nRows);
%     case 2
%         nCols=5;
%         nRows=ceil(nIntervals/nCols);
%     case 3
%         nRows=2;
%         nCols=ceil(nIntervals/nRows);
% end
%
% for interval_index=1:nIntervals
%     intervalNr=intervals(interval_index);
%     M=pivotTable2(D,1:2,'mean',interval_index+2,[],1);
%     E=pivotTable2(D,1:2,'ste',interval_index+2,[],1);
%     subplot(nRows,nCols,interval_index)
%     b=errorbar(M',E','.-');
%     box off
%     axis([0 13 .5 3.5])
%     title(['Interval nr: ' num2str(intervalNr)])
%     set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
%     set(gca,'xTick',floor(linspace(0,12,5)),'xGrid','on','yTick',[1 2 3],'yGrid','on')
% end
% legend(b,groupList,'location','best')
%
% %%
%
% for interval=1:16
%     data(:,interval)=pivotTable2(D,1:2,'mean',2+interval)';
%     errors(:,interval)=pivotTable2(D,1:2,'ste',2+interval)';
% end
%
% clf
% for day=1:12
%     subplot(3,4,day)
%     hold on
%     b(1)=errorbar(data(day,:),errors(day,:),'r.-');
%     b(2)=errorbar(data(day+12,:),errors(day+12,:),'g.-');
%     b(3)=errorbar(data(day+24,:),errors(day+24,:),'b.-');
%     hold off
%     box off
%     axis([0 17 .5 3.5])
%     title(['Day ' num2str(day)])
%     legend(b,groupList,'location','best')
%     set(gca,'ButtonDownFcn',{@switchFcn,get(gca,'position')})
%     set(gca,'xTick',linspace(1,16,4),'xGrid','on','yTick',[1 2 3],'yGrid','on')
% end
%
% % => now make excel file containing track and folder names and track
% % classifications
%
% % trackClassification_vector_oldModel=decisions;
% % startegiesPerTrack=pivotTable2(decisions,1,'hist',1,'1:9',1);
% %
% % overwrite=0;
% % if overwrite==1
% %     trackClassification_rankMatrix=dataMatrix;
% %     save(saveName,'trackClassification_vector_oldModel','trackClassification_rankMatrix','SVMmatrix','timePoints','startegiesPerTrack','-append')
% % end
%
%
