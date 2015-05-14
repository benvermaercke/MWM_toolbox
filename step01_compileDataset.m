%%% This file will take an folder as input and will parse all the *.csv
%%% files it find; keeping track of subfolder structure (different
%%% columns). An empty classification vector will be created. Track
%%% parameters can be extracted optionally.
%%% The user will also have the opportunity to enter data about the
%%% experiment (who ran it, when, what manipulations were done). It is also
%%% imperative that coordinates of the pool and platform are specified; two
%%% platforms positions in case of a reversal experiment.
%%% This major database file can then be used to create both heatplots and
%%% track classifications.

%%% Change log:
% 2012-04-18: added offset parameter to compensate for first lines missed
% in excel 2007 files. Based on difference between raw and data(shorter)

clear all
clc

saveIt=1;
MWMtype=2; % 1: old | 2: new |

%subFolderNames={'00_LAMAN_ERT_batch1eval1_acq','01_LAMAN_ERT_batch1eval1_probe','02_LAMAN_ERT_batch1eval2_acq','03_LAMAN_ERT_batch1eval2_probe','04_LAMAN_ERT_batch2eval1_acq','05_LAMAN_ERT_batch2eval1_probe'}';
%MWMtype_vector=[1 1 2 2 1 1];

%folder_index=6;
%dataFolder='E:\LeuvenData\Developement\MWMtoolbox\rawFiles\StijnS_2013-12-18_rawdata'; %
%dataFolder=fullfile(dataFolder,subFolderNames{folder_index});
%MWMtype=MWMtype_vector(folder_index);

if ispc
    dataFolder='E:\LeuvenData\Developement\MWMtoolbox\rawFiles\ACL_Reversal_acquisition_track';
    %P2X4_WT_acq
else
    dataFolder='/Volumes/TeraLacie/LeuvenData/Developement/MWMtoolbox/rawFiles/Disconnection_SearchStrategies';
    %dataFolder='/Volumes/TeraLacie/LeuvenData/Developement/MWMtoolbox/rawFiles/ACL_Amira/ACL_Amira_Rev';
end


A=strsplit(filesep,dataFolder);
databaseName=A{end};
databaseName(databaseName==' ')='_';
saveName=['dataSets/' databaseName '.mat'];
if exist(saveName,'file')
    error(['File ' saveName ' exists...'])
else
    savec(saveName)
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Extracting data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S=rdir([dataFolder filesep '**' filesep '**.csv']);
fileType=1;
if isempty(S)
    S=rdir([dataFolder filesep '**' filesep '**.xls']);
    fileType=2;
end
if isempty(S) % look for txt files
    %S=rdir([dataFolder '\**\**.txt']);
    S=rdir([dataFolder '/**/**.txt']);
    fileType=3;
end
if isempty(S)
    error(['No file found in folder: ' dataFolder])
else
    N=length(S);
    %disp([num2str(N) ' files found!'])
end

folderName='';
folderNum=0;
emptyFileNames=[];
count2=1;
%%
if ispc
    Excel = actxserver ('Excel.Application');
end
% strip ._ files from S
count=1;
for index=1:length(S)
    if strfind(S(index).name,'._')
    else
        S_new(count)=S(index);
        count=count+1;
    end
end
S=S_new;
N=length(S);

disp([num2str(N) ' files found!'])

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

%%

AllTracks.fieldNames={'folderNr','trackNr','sampleNr','time','X-pos','Y-pos'};
AllTracks.data=[];
count=1;
t0=clock;
for index=1:N
    progress(index,N,t0,count)
    filename=S(index).name;
    
    % Get current subfolder
    [fullPath, coreName]=fileparts(filename);
    A=strsplit(filesep,fullPath);
    currentFolder=A{end};
    if ~strcmpi(currentFolder,folderName)
        folderName=currentFolder;
        folderNum=folderNum+1;
        folderList{folderNum}=folderName;
    end
    
    if ispc
        %[data b raw]=xlsread(xlsName);
        Excel.Workbooks.Open(filename);
        [data, b, raw]=xlsread1(filename);
        Excel.Workbooks.Close;
    else
        if ispc
            switch fileType
                case 1
                    [data, b, raw]=xlsread(filename);
                case 2
                    [data, b, raw]=xlsread(filename,1);
                case 3
                    raw={};
                    count2=1;
                    
                    fid=fopen(filename);
                    tline = fgetl(fid);
                    while ischar(tline)
                        raw{count2,1}=tline;
                        count2=count2+1;
                        tline = fgetl(fid);
                        
                    end
                    fclose(fid);
            end
        else % on mac, just do raw file reading : no xls support...
            raw={};
            count2=1;
            
            fid=fopen(filename);
            tline = fgetl(fid);
            while ischar(tline)
                raw{count2,1}=tline;
                count2=count2+1;
                tline = fgetl(fid);
                
            end
            fclose(fid);
        end
    end
    
    startRow=1;
    endRow=length(raw);
    numFound=0;
    searching=1;
    switch fileType % excel 2003 format
        case 1
            while searching>0
                % First check whether first part is numeric
                row=raw{searching};
                parts=strsplit(',',row);
                
                if ~isnan(str2double(parts{1}))
                    numFound=1;
                end
                if numFound==0
                    if strcmpi(parts{1},'Sample no.')
                        %%% Headers found
                        info.headers=row;
                    elseif strcmpi(parts(1),' ')
                        %%% Skip row
                    else
                        %%% Parse parameter value pairs
                        if length(parts)>1
                            parameter=parts{1};
                            parameter(parameter==' ')='_';
                            parameter(parameter=='&')='';
                            parameter(parameter=='<')='';
                            parameter(parameter=='>')='';
                            parameter(parameter=='-')='_';
                            value=parts{2};
                            if ~isnan(str2double(value))
                                value=str2double(value);
                            end
                            eval(['info.' parameter '=value;'])
                        end
                    end
                    searching=searching+1;
                else % start of coords found
                    startRow=searching; % remember start row
                    searching=0;
                end
            end
            
            dataMatrix=zeros(endRow-startRow+1,4);
            for rowNr=startRow:endRow
                row=raw{rowNr};
                parts=strsplit(',',row);
                sampleNr=str2double(parts{1});
                dataMatrix(sampleNr,:)=[sampleNr str2double(parts{2}) str2double(parts{3}) str2double(parts{4})];
            end
            
        case 2 % excel 2007 format
            %%% Parse info from raw
            searching=1;
            corrupt=0;
            while searching>0
                if searching>size(raw,1)
                    corrupt=1;
                    break
                end
                parameter=raw{searching,1};
                value=raw{searching,2};
                if isnumeric(parameter)
                    numFound=1;
                end
                if numFound==0
                    if strcmpi(parameter,'Time')
                        %%% Headers found
                        info.headers=[raw{searching,1:end}];
                        dataCols=1:3;
                    elseif strcmpi(parameter,'Sample no.')
                        %%% Headers found
                        info.headers=[raw{searching,1:end}];
                        dataCols=2:4;
                    else
                        if isempty(parameter)&&~isempty(value)
                            %%% Skip row
                        elseif strcmpi(parameter,' ')
                            %%% Skip row
                        else
                            parameter(parameter==' ')='_';
                            parameter(parameter=='&')='';
                            parameter(parameter=='<')='';
                            parameter(parameter=='>')='';
                            parameter(parameter=='-')='_';
                            parameter(parameter=='.')='';
                            if ~isnan(str2double(value))
                                value=str2double(value);
                            end
                            eval(['info.' parameter '=value;'])
                        end
                    end
                    searching=searching+1;
                else
                    startRow=searching;
                    searching=0;
                end
            end
            if corrupt==0
                offset=size(raw,1)-size(data,1);
                dataMatrix=[(1:(endRow+1-startRow))' data(startRow-offset:endRow-offset,dataCols)];
            else
                dataMatrix=[];
            end
            
        case 3
            
            while searching>0
                if searching>length(raw)
                    break 
                end
                % First check whether first part is numeric
                row=raw{searching};
                switch 2
                    case 1
                        parts=strsplit(',',row);
                    case 2 % txt " and ;
                        row(row=='"')='';
                        parts=strsplit(';',row);
                end
                
                if ~isnan(str2double(parts{1}))
                    numFound=1;
                end
                if numFound==0
                    if strcmpi(parts{1},'Sample no.')
                        %%% Headers found
                        info.headers=row;
                    elseif strcmpi(parts(1),' ')
                        %%% Skip row
                    else
                        %%% Parse parameter value pairs
                        if length(parts)>1
                            parameter=parts{1};
                            parameter(parameter==' ')='_';
                            parameter(parameter=='&')='';
                            parameter(parameter=='<')='';
                            parameter(parameter=='>')='';
                            parameter(parameter=='-')='_';
                            value=parts{2};
                            if ~isnan(str2double(value))
                                value=str2double(value);
                            end
                            eval(['info.' parameter '=value;'])
                        end
                    end
                    searching=searching+1;
                else % start of coords found
                    startRow=searching; % remember start row
                    searching=0;
                end
            end
            
            dataMatrix=zeros(endRow-startRow+1,4);
            
            counter=1;
            for rowNr=startRow:endRow
                row=raw{rowNr};
                switch 2
                    case 1
                        parts=strsplit(',',row);
                    case 2 % txt " and ;
                        row(row=='"')='';
                        parts=strsplit(';',row);
                end
                sampleNr=str2double(parts{1});
                dataMatrix(counter,:)=[counter sampleNr str2double(parts{2}) str2double(parts{3})];
                counter=counter+1;
            end
    end
    
    
    if size(dataMatrix,2)>1
        if all(isnan(dataMatrix(:,3)))
            emptyFileNames{count2}=coreName;
            count2=count2+1;
        else
            
            nRows=size(dataMatrix,1);
            trackNames{count,1}=coreName;
            demographics=[folderNum count];
            AllTracks.data=vertcat(AllTracks.data,[repmat(demographics,nRows,1) dataMatrix]);
            TrackInfo{count,1}=info;
            
            count=count+1;
        end
    end
end

if ispc
    Excel.Quit
    Excel.delete
end


if saveIt==1
    %%
    nTracks=length(TrackInfo);
    trackClassification_vector=zeros(nTracks,1);
    save(saveName,'nTracks','folderList','trackNames','AllTracks','TrackInfo','trackClassification_vector','MWMtype')
end

