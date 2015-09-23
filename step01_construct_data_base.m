clear all
clc

header_script_MWM

%%% Instantiate database class based on data_folder, which can come from
%%% uitgetfolder
dataset=trajectory_class(data_folder);

%% Check for files types, number and location
dataset.file_scanner()
dataset.file_parser()

%% Load example file to delineate which data have to be read in...
dataset.sample_data(3)

%% Select columns to read, can be GUI
dataset.set_cols2read(1,4)

%% Read in the data, given filter defined above
dataset.read_data()

%% Select headers to use for grouping
%dataset.select_headers()

%% Select folder levels to use for grouping
% dataset.select_folderLevels()

%% Add ground truth, from file or manual, if needed
% just do analysis

%% Add arena coordinates, if known
% else, they will be extracted from the data =less precise

%% Save data to file
dataset.save_data()

%%
die
% parse up the data

initXLSreader

t0=clock;
trackNames=cell(nFiles,1);
adjust_trackInfo_fields=0;
if adjust_trackInfo_fields==1
    trackInfo_all=struct('Start_time','','Video_file',[],'Tracking_source','','Duration','','Reference_time','','Trial_ID',[],'Arena_index',[],'Object_index',[],'Arena_settings','','Trial_name','','Arena_name','','Subject_name','','Track','','Trial_status','','Acquisition_status','','Track_status','','Recording_after','','Recording_duration','','Video_start_time',[],'Detection_settings','','Trial_control_settings','','Video_file_status','','Sync_status','','Reference_duration','','Sof_file',[],'mouse_ID','','trial',[],'Day',[],'treatment',[],'Lesion','','folderRoot','','folderName','','file_nr',[]);
else
    dataMatrix_all=struct('data',[],'fieldNames','');
end
file_counter=0;
for iFile=1:nFiles
    %%% Get track name
    track_name=S(iFile).name;
    trackNames{iFile}=track_name;
    
    %%% Create folderName
    switch 2
        case 1
            folderName=getFolderName(track_name);
            folderName=strrep(folderName,' ','_');
            folderRoot=folderName(1:end-4);
        case 2 % find all folders separating this folder from data folder
            %%
            parts2=strsplit(data_folder,filesep);
            parts1=strsplit(track_name,filesep);
            parts=parts1(length(parts2)+1:end-1);
            folderName=strrep(strjoin(parts,'_'),' ','_');
            %folderRoot=folderName(1:end-3);
            
            parts_root=strsplit(folderName,'_');
            folderRoot=strjoin(parts_root(1:end-1),'_');
    end
    
    %%% Read data from file
    [dataMatrix_sheets, trackInfo_sheets]=readXLSdata(track_name,max(data_cols));
    
    for iSheet=1:length(dataMatrix_sheets)
        dataMatrix=dataMatrix_sheets(iSheet);
        trackInfo=trackInfo_sheets(iSheet);
        
        % Check for empty data
        %if ~any(dataMatrix.data(1,:))
        %    die
        %end
        
        %%% Fix trackInfo which has to match over all files
        if adjust_trackInfo_fields==1
            if isfield(trackInfo,'User_defined_1')
                trackInfo=rmfield(trackInfo,'User_defined_1');
            end
            if ~isfield(trackInfo,'Lesion')
                trackInfo.Lesion='';
            end
        else
            if ~isfield(trackInfo,'Baited_arm')
                trackInfo.Baited_arm=[];
            else
            end
        end
        %%% Build up trackInfo
        file_counter=file_counter+1;
        trackInfo.folderRoot=folderRoot;
        trackInfo.folderName=folderName;
        trackInfo.file_nr=file_counter;
        
        %%% join data
        dataMatrix_all(file_counter)=dataMatrix;
        
        %% Perform checks
        if file_counter>1
            A=fieldnames(trackInfo_all);
            B=fieldnames(trackInfo);
            if length(A)~=length(B)
                C=intersect(A,B);
                A_unique=~ismember(A,C);
                if any(A_unique)
                    disp('New struct is missing field(s):')
                    disp(A(A_unique))
                end
                B_unique=~ismember(B,C);
                if any(B_unique)
                    disp('New struct has additional field(s):')
                    disp(B(B_unique))
                end
            end
        end
        trackInfo_all(file_counter)=trackInfo;
    end
    progress(iFile,nFiles,t0)
end

%% Post processing
no_mapping=zeros(length(trackInfo_all),1);

[group_mapping,groups]=getMapping({trackInfo_all.folderRoot});
[folder_mapping,labels]=getMapping({trackInfo_all.folderName});

if isfield(trackInfo_all,'Day')
    day_mapping=cat(1,trackInfo_all.Day);
else
    day_mapping=no_mapping;
end

if isfield(trackInfo_all,'mouse_ID')
    ID_mapping=getMapping({trackInfo_all.mouse_ID});
elseif isfield(trackInfo_all,'Animal_ID')
    %ID_mapping=getMapping({trackInfo_all.Animal_ID});
    ID_mapping=cat(1,trackInfo_all.Animal_ID);
else
    ID_mapping=no_mapping;
end

if isfield(trackInfo_all,'trial')
    trial_mapping=cat(1,trackInfo_all.trial);
elseif isfield(trackInfo_all,'Trial_ID')
    trial_mapping=cat(1,trackInfo_all.Trial_ID);
else
    trial_mapping=no_mapping;
end

if isfield(trackInfo_all,'Arena_ID')
    arena_mapping=cat(1,trackInfo_all.Arena_ID);
else
    arena_mapping=no_mapping;
end


demographics=[folder_mapping group_mapping day_mapping ID_mapping trial_mapping arena_mapping];
TrackInfo=trackInfo_all;
AllTracks=dataMatrix_all;

%%
if saveIt==1
    %%
    nTracks=length(TrackInfo);
    trackClassification_vector=zeros(nTracks,1);
    save(saveName,'nTracks','demographics','trackNames','AllTracks','TrackInfo','trackClassification_vector','MWMtype')
end

