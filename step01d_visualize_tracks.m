clear all
clc

header_script_MWM

try
    loadName=fullfile(data_folder,'dataSets',databaseName);
catch
    loadName=fullfile(data_folder,'dataSets_17parameters',databaseName);
end
load(loadName,'AllTracks','demographics')


%% Get general properties of the dataset
M_all=cat(1,AllTracks.(use_data_field));
X_range=[min(M_all(:,data_cols(1))) max(M_all(:,data_cols(1)))];
Y_range=[min(M_all(:,data_cols(2))) max(M_all(:,data_cols(2)))];

%%
iTrack=1;
arena_id=demographics(iTrack,6);

M=AllTracks(iTrack).data;

plot(M(:,data_cols(1)),M(:,data_cols(2)),'b.')
title(arena_id)
axis([X_range Y_range])

%% per arena
arena_id=0;
sel=demographics(:,6)==arena_id;
track_nr_vector=find(sel);
nTracks=length(track_nr_vector);
M=cat(1,AllTracks(sel).data);

M_corrected=[];
for iTrack=1:nTracks 
    track_nr=track_nr_vector(iTrack);
    track=AllTracks(track_nr).data;
    track_corrected=track;
    track_corrected(:,data_cols)=[track(:,data_cols(1))-min(track(:,data_cols(1))) track(:,data_cols(2))-min(track(:,data_cols(2)))];
    M_corrected=cat(1,M_corrected,track_corrected);
end

% uncorrected
subplot(211)
plot(M(:,data_cols(1)),M(:,data_cols(2)),'b.')
axis([0 35 0 35])
axis equal

% corrected
subplot(212)
plot(M_corrected(:,data_cols(1)),M_corrected(:,data_cols(2)),'b.')
axis([0 35 0 35])
axis equal


%% per folder
folder_id=1;
sel=demographics(:,1)==folder_id;
track_nr_vector=find(sel);
nTracks=length(track_nr_vector);
M=cat(1,AllTracks(sel).data);

M_corrected=[];
for iTrack=1:nTracks 
    track_nr=track_nr_vector(iTrack);
    track=AllTracks(track_nr).data;
    track_corrected=track;
    track_corrected(:,data_cols)=[track(:,data_cols(1))-min(track(:,data_cols(1)))+1 track(:,data_cols(2))-min(track(:,data_cols(2)))+1];
    M_corrected=cat(1,M_corrected,track_corrected);
end

% uncorrected
subplot(211)
plot(M(:,data_cols(1)),M(:,data_cols(2)),'b.')
axis([0 35 0 35])
axis equal
axis tight
% corrected
subplot(212)
plot(M_corrected(:,data_cols(1)),M_corrected(:,data_cols(2)),'b.')
axis([0 35 0 35])
axis equal
axis tight
%%

kernelSize=15;
HP=makeHeatplot(M(:,data_cols),kernelSize,im_size,[0 0]);
HP_corrected=makeHeatplot(M_corrected(:,data_cols),kernelSize,im_size,[0 0]);


subplot(211)

imshow(HP,[])

subplot(212)
imshow(HP_corrected,[])

colormap parula