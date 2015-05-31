clear all
clc

header_script_MWM

%saveIt=0;

try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end

load(loadName,'AllTracks','demographics')

%%% Check if different arenas were used
arena_IDs=demographics(:,6);
arena_ID_vector=unique(arena_IDs);
nArena=length(arena_ID_vector);
arenaCoords=struct;

%%% Do correction per arena
for arena_selector=1:nArena
    sel=arena_IDs==arena_ID_vector(arena_selector);
        
    % Find general properties: range of coords
    M=cat(1,AllTracks(sel).data);
    sampling_rate=mean(1./diff(M(1:10,2)));
    re_alignment_values=[-min(M(:,data_cols(1)))+border_size(1) -min(M(:,data_cols(2)))+border_size(2)];
    
    % Only apply to selected tracks
    track_nr_vector=find(sel);
    nTracks=length(track_nr_vector);
    for iTrack=1:nTracks
        track_nr=track_nr_vector(iTrack);
        M=AllTracks(track_nr).data;
        M(:,data_cols(1))=M(:,data_cols(1))+re_alignment_values(1);
        M(:,data_cols(2))=M(:,data_cols(2))+re_alignment_values(2);
        AllTracks(track_nr).data=M;
    end
end

%%% Sanity check
M=cat(1,AllTracks.data);
min(M)

if saveIt==1
    %%
    save(loadName,'AllTracks','re_alignment_values','sampling_rate','-append')
    disp('AllTracks overwritten')
end