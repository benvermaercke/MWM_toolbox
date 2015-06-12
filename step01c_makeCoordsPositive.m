clear all
clc

header_script_MWM

%saveIt=0;

try
    loadName=fullfile(data_folder,'dataSets',databaseName);
catch
    loadName=fullfile(data_folder,'dataSets_17parameters',databaseName);
end

load(loadName,'AllTracks','demographics')

%%% Check if different arenas were used
arena_IDs=demographics(:,6);
arena_ID_vector=unique(arena_IDs);
nArena=length(arena_ID_vector);
arenaCoords=struct;

M=cat(1,AllTracks(1).data);
sampling_rate=mean(1./diff(M(1:10,2)));

if isfield(AllTracks,'data_corrected')
    AllTracks=rmfield(AllTracks,'data_corrected');
end
    
switch correction_method
    case 0 % Do nothing
    case 1 % Do correction per arena
        for arena_selector=1:nArena
            sel=arena_IDs==arena_ID_vector(arena_selector);
            
            % Find general properties: range of coords
            M=cat(1,AllTracks(sel).data);
            re_alignment_values=[-min(M(:,data_cols(1)))+border_size(1) -min(M(:,data_cols(2)))+border_size(2)];
            
            % Only apply to selected tracks
            track_nr_vector=find(sel);
            nTracks=length(track_nr_vector);
            for iTrack=1:nTracks
                track_nr=track_nr_vector(iTrack);
                M=AllTracks(track_nr).data;
                M(:,data_cols(1))=M(:,data_cols(1))+re_alignment_values(1);
                M(:,data_cols(2))=M(:,data_cols(2))+re_alignment_values(2);
                AllTracks(track_nr).(use_data_field)=M;
            end
        end
        
    case 2 % Do correction per folder
        
    case 3 % Do correction per track (risky! in case animal does not enter the origin)
        re_alignment_values=border_size;
        nTracks=length(AllTracks);
        for iTrack=1:nTracks
            track=AllTracks(iTrack).data;
            track_corrected=track;
            track_corrected(:,data_cols)=[track(:,data_cols(1))-min(track(:,data_cols(1)))+re_alignment_values(1) track(:,data_cols(2))-min(track(:,data_cols(2)))+re_alignment_values(2)];
            %X=track(:,data_cols(1));
            %Y=track(:,data_cols(2));
            %track_corrected(:,data_cols)=[X-min(M(:,data_cols(1))) Y-min(M(:,data_cols(2)))];
            AllTracks(iTrack).(use_data_field)=track_corrected;
        end
end

%%

%% Sanity check
subplot(211)
M=cat(1,AllTracks.data);
min(M)
plot(M(:,data_cols(1)),M(:,data_cols(2)),'.')
%axis([-100 200 -100 200])
axis square

subplot(212)
M=cat(1,AllTracks.(use_data_field));
min(M)
plot(M(:,data_cols(1)),M(:,data_cols(2)),'.')
%axis([-100 200 -100 200])
axis square

%%

if saveIt==1
    %%
    save(loadName,'AllTracks','re_alignment_values','sampling_rate','-append')
    disp('AllTracks overwritten')
end