clear all
clc

header_script

saveIt=0;

A=strsplit(filesep,data_folder);
databaseName=A{end};
databaseName(databaseName==' ')='_';
saveName=['dataSets/' databaseName '.mat'];
if exist(saveName,'file')
    error(['File ' saveName ' exists...'])
else
    savec(saveName)
end

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

%% Convert folder names to suitable format
folder_names=cell(length(S),1);
for iFile=1:length(S)
    [f,fn,ext]=fileparts(S(iFile).name);
    parts=strsplit(filesep,f);
    folder_name=parts{end};
    switch length(strfind(folder_name,' '))
        case 1
            str=char(sscanf(folder_name,'%s D%*d'))';
            num=sscanf(folder_name,'%*s D%d');
        case 2
            str=char(sscanf(folder_name,'%s%c%s D%*d'))';
            num=sscanf(folder_name,'%*s %*s D%d');
        otherwise
            error('no format defined for folder name')
    end
    new_folder_name=[strrep(str,' ','_') '_' sprintf('%03d',num)];
    folder_names{iFile}=new_folder_name;
end
folder_list=unique(folder_names);

%% Read files
initXLSreader

t0=clock;
for iFile=1:30%nFiles
    [dataMatrix, trackInfo]=readXLSdata(S(iFile).name,3);
    folderName=getFolderName(S(iFile).name);
    folderName=strrep(folderName,' ','_');
    
    %%% Append to trackInfo
    trackInfo.file_nr=iFile;
    trackInfo.folderName=folderName;     
    
    %%% join data    
    dataMatrix_all(iFile)=dataMatrix;
    trackInfo_all(iFile)=trackInfo;
    progress(iFile,nFiles,t0)
end

%% Post processing
folderNames=cat(1,trackInfo_all.folderName);
mapping=getMapping(folderNames)



%%
if save_it==1
    nTracks=length(TrackInfo);
    trackClassification_vector=zeros(nTracks,1);
    save(saveName,'nTracks','folderList','trackNames','AllTracks','TrackInfo','trackClassification_vector','MWMtype') 
end