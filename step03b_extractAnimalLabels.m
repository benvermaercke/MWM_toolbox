clear all
clc

header_script_MWM

saveIt=0;

%%% Load dataset
loadName=fullfile('dataSets',databaseName);
% loadName=fullfile('dataSets_17parameters',filename);
load(loadName)

%% Construct list of unique subjects
group_list=cell(nTracks,1);
dayNr_vector=zeros(nTracks,1);
ID_list=cell(nTracks,1);

for index=1:nTracks
    if isfield(TrackInfo{index},'group')
        group_list{index}=TrackInfo{index}.group;
    else
        group_list{index}='';
    end
    
    if isfield(TrackInfo{index},'GENOTYPE')
        group_list{index}=TrackInfo{index}.GENOTYPE;
    else
        group_list{index}='';
    end
    
    if isfield(TrackInfo{index},'conditie')
        group_list{index}=TrackInfo{index}.conditie;
    else
        group_list{index}='';
    end
    
    if isfield(TrackInfo{index},'Day')
        day=TrackInfo{index}.Day;
        if isnumeric(day)
            dayNr_vector(index)=day;
        else
            %day='ab';
            A=sscanf(day,'%d%s');
            if ~isempty(A)
                dayNr_vector(index)=A(1);
            end
        end
    end
    
    if isfield(TrackInfo{index},'day')
        day=TrackInfo{index}.day;
        if isnumeric(day)
            dayNr_vector(index)=day;
        else
            %day='ab';
            A=sscanf(day,'%d%s');
            if ~isempty(A)
                dayNr_vector(index)=A(1);
            end
        end
    end
    
    if isfield(TrackInfo{index},'Trial_block')
        dayNr_vector(index)=TrackInfo{index}.Trial_block;
    end
    if isfield(TrackInfo{index},'TRIAL_NUMBER')
        dayNr_vector(index)=TrackInfo{index}.TRIAL_NUMBER;
    end
    
    if isfield(TrackInfo{index},'Probe')
        %dayNr_vector(index)=TrackInfo{index}.Probe;
    end
    
    if isfield(TrackInfo{index},'Subject_name')
        mouseID=TrackInfo{index}.Subject_name;
    else        
        if isfield(TrackInfo{index},'Mouse_ID')
            mouseID=TrackInfo{index}.Mouse_ID;
        elseif isfield(TrackInfo{index},'mouse_ID')
            mouseID=TrackInfo{index}.mouse_ID;
        elseif isfield(TrackInfo{index},'mouseID')
            mouseID=TrackInfo{index}.mouseID;
        else
            mouseID=0;
        end
    end
    if isempty(mouseID)
        ID_list{index}='';
    else
        if isnumeric(mouseID)
            mouseID=num2str(mouseID);
        end
        ID_list{index}=mouseID;
    end
    
end
groupList=unique(group_list);
subjectList=unique(ID_list);

%% Assign each track to a unique number
subjectGroupMapping_vector=zeros(nTracks,1);
for index=1:nTracks
    [a place]=ismember(group_list{index},groupList);
    subjectGroupMapping_vector(index)=place;
end

subjectTrackMapping_vector=zeros(nTracks,1);
for index=1:nTracks
    [a place]=ismember(ID_list{index},subjectList);
    subjectTrackMapping_vector(index)=place;
end

TrialAllocation.fieldNames={'FolderNum','TrackNr','GroupNr','DayNr','SubjectNr','TrackClassification'};
%TrialAllocation.data=[unique(AllTracks.data(:,[1 2]),'rows') subjectGroupMapping_vector dayNr_vector subjectTrackMapping_vector trackClassification_vector_oldModel];
TrialAllocation.data=[unique(AllTracks.data(:,[1 2]),'rows') subjectGroupMapping_vector dayNr_vector subjectTrackMapping_vector trackClassification_vector];

unique(pivotTable2(TrialAllocation.data,4:5,'length',1))

if overwrite==1    
    %%    
    %save(loadName,'AllTracks','TrackInfo','poolCoords','platFormCoords','nTracks','folderList','trackNames','trackClassification_vector','TrackStatsExist','TrackStatistics','TrackStatMatrix','subjectList','TrialAllocation','ID_list')
    save(loadName,'groupList','subjectList','TrialAllocation','group_list','ID_list','-append')
    %save(loadName,'ID_list','-append')
end



