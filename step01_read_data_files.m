clear all
clc

header_script_MWM

saveIt=0;

%%% Create database file
saveName=['dataSets/' databaseName '.mat'];
if saveIt==1&&exist(saveName,'file')
    error(['File ' saveName ' exists...'])
else
    savec(saveName)
end

%%% Find files
S=rdir([data_folder filesep '**' filesep '**.csv']);
fileType=1;
if isempty(S)
    S=rdir([data_folder filesep '**' filesep '**.xls']);
    fileType=2;
end
if isempty(S) % look for txt files
    S=rdir([data_folder filesep '**' filesep '**.txt']);
    fileType=3;
end
if isempty(S)
    error(['No files found in folder: ' data_folder])
else
    nFiles=length(S);
    %disp([num2str(N) ' files found!'])
end

folderName='';
folderNum=0;
emptyFileNames=[];
count2=1;

% strip ._ files from S
count=1;
for iFile=1:nFiles
    if strfind(S(iFile).name,'._')
    else
        S_new(count)=S(iFile);
        count=count+1;
    end
end
S=S_new;
nFiles=length(S);
disp([num2str(nFiles) ' files found!'])

%% Read files
initXLSreader

t0=clock;
trackNames=cell(nFiles,1);
dataMatrix_all=struct('data',[],'fieldNames','');
trackInfo_all=struct('Start_time','','Video_file',[],'Tracking_source','','Duration','','Reference_time','','Trial_ID',[],'Arena_index',[],'Object_index',[],'Arena_settings','','Trial_name','','Arena_name','','Subject_name','','Track','','Trial_status','','Acquisition_status','','Track_status','','Recording_after','','Recording_duration','','Video_start_time',[],'Detection_settings','','Trial_control_settings','','Video_file_status','','Sync_status','','Reference_duration','','Sof_file',[],'mouse_ID','','trial',[],'Day',[],'treatment',[],'Lesion','','folderRoot','','folderName','','file_nr',[]);
for iFile=1:nFiles
    %%% Get track name
    track_name=S(iFile).name;
    trackNames{iFile}=track_name;
    
    %%% Create folderName
    folderName=getFolderName(track_name);
    folderName=strrep(folderName,' ','_');
    
    %%% Read data from file
    [dataMatrix, trackInfo]=readXLSdata(track_name,3);    
    
    %%% Fix trackInfo which has to match over all files
    if isfield(trackInfo,'User_defined_1')
        trackInfo=rmfield(trackInfo,'User_defined_1');
    end
    if ~isfield(trackInfo,'Lesion')
        trackInfo.Lesion='';
    end
    
    %%% Build up trackInfo
    trackInfo.folderRoot=folderName(1:end-4);
    trackInfo.folderName=folderName;
    trackInfo.file_nr=iFile;
    
    %%% join data
    dataMatrix_all(iFile)=dataMatrix;
    trackInfo_all(iFile)=trackInfo;
    progress(iFile,nFiles,t0)
    %if mod(iFile,2)==1
    %    fprintf('%c','.') 
    %end
end

%% Post processing
group_mapping=getMapping({trackInfo_all.folderRoot});
folder_mapping=getMapping({trackInfo_all.folderName});
day_mapping=cat(1,trackInfo_all.Day);
ID_mapping=getMapping({trackInfo_all.mouse_ID});
trial_mapping=cat(1,trackInfo_all.trial);

demographics=[folder_mapping group_mapping day_mapping ID_mapping trial_mapping];
TrackInfo=trackInfo_all;
AllTracks=dataMatrix_all;

%%
if saveIt==1
    nTracks=length(TrackInfo);
    trackClassification_vector=zeros(nTracks,1);
    save(saveName,'nTracks','demographics','trackNames','AllTracks','TrackInfo','trackClassification_vector','MWMtype')
end

