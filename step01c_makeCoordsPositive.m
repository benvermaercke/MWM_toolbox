clear all
clc

header_script_MWM

saveIt=1;

try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end

load(loadName,'AllTracks','nTracks','MWMtype')

if MWMtype==2
    M=cat(1,AllTracks.data);
    re_alignment_values=[-min(M(:,2))+5 -min(M(:,3))+5];
    for iTrack=1:nTracks
        M=AllTracks(iTrack).data;
        M(:,2)=M(:,2)+re_alignment_values(1);
        M(:,3)=M(:,3)+re_alignment_values(2);
        AllTracks(iTrack).data=M;        
    end
else
    M=AllTracks.data;
    SR=mean(1./diff(M(1:10,4)));
    if SR==25
        %re_alignment_values=[-min(M(:,5))+5 -min(M(:,6))+5];
        %M(:,5)=M(:,5)+re_alignment_values(1);
        %M(:,6)=M(:,6)+re_alignment_values(2);
    else
    end
end

%%% Sanity check
M=cat(1,AllTracks.data);
min(M)

if saveIt==1
    %%
    %AllTracks.data=M;
    save(loadName,'AllTracks','re_alignment_values','-append')
    disp('AllTracks overwritten')
end