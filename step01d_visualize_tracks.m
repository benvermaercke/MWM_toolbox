clear all
clc

header_script_MWM

try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end
load(loadName,'AllTracks','demographics')


%% Get general properties of the dataset
M_all=cat(1,AllTracks.data);
X_range=[min(M_all(:,data_cols(1))) max(M_all(:,data_cols(1)))];
Y_range=[min(M_all(:,data_cols(2))) max(M_all(:,data_cols(2)))];

%%
iTrack=94;
demographics(iTrack,6)

M=AllTracks(iTrack).data;

plot(M(:,data_cols(1)),M(:,data_cols(2)),'b.')
axis([X_range Y_range])

