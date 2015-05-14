clear all
clc

overwrite=1;

% filename='ACL_2013_12_presymp1.mat';
% subFolderNames={'00_LAMAN_ERT_batch1eval1_acq','01_LAMAN_ERT_batch1eval1_probe','02_LAMAN_ERT_batch1eval2_acq','03_LAMAN_ERT_batch1eval2_probe','04_LAMAN_ERT_batch2eval1_acq','05_LAMAN_ERT_batch2eval1_probe'};
% filename=subFolderNames{6}
%rootFolder=fileparts(mfilename('fullpath'))
%filename='ACL_Reference_memory_acquisition_track.mat';
filename='ACL_Reversal_acquisition_track.mat';
loadName=fullfile('dataSets',filename)
% loadName=fullfile('dataSets_17parameters',filename);

load(loadName,'AllTracks')
M=AllTracks.data;

tracks=unique(M(:,2));
nTracks=length(tracks);

%%% Run the procedure
t0=clock;
count=0;
emptyFiles=[];
for track_index=1:nTracks
    %if mod(track_index,50)==1        
    progress(track_index,nTracks,t0,[count mean(isnan(AllTracks.data(:,5)))])
    %end
    trackNr=tracks(track_index);
    check=M(M(:,2)==trackNr,5:6);
    if all(isnan(check(:)))
        check
        emptyFiles=[emptyFiles track_index]
    elseif any(isnan(check(:)))
        M(M(:,2)==trackNr,5)=fillTheGaps2(M(M(:,2)==trackNr,5));
        M(M(:,2)==trackNr,6)=fillTheGaps2(M(M(:,2)==trackNr,6));
        count=count+1;
    end
end

disp([num2str(count) ' track(s) fixed!'])
%%% Save the data
if overwrite==1
    %%
    mean(isnan(AllTracks.data(:,5)))
    AllTracks.data=M;
    mean(isnan(AllTracks.data(:,5)))
    save(loadName,'AllTracks','-append')
end
