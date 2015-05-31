clear all
clc

%%% Make a general preprocessing script fill gaps, makes coords positive,
%%% resamples to 5Hz according to options

header_script_MWM

saveIt=0;



try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end

load(loadName,'AllTracks','nTracks')

%%% Run the procedure
t0=clock;
count=0;
emptyFiles=[];
for iTrack=1:nTracks
    M=AllTracks(iTrack).data;
    if any(isnan(M(:)))
        tic
        M(:,data_cols(1))=fillTheGaps2(M(:,data_cols(1)));
        M(:,data_cols(2))=fillTheGaps2(M(:,data_cols(2)));
        toc
        count=count+1;
    end
    AllTracks(iTrack).data=M;
    progress(iTrack,nTracks,t0)
end

disp([num2str(count) ' track(s) fixed!'])
%%% Save the data
if saveIt==1
    %%
    save(loadName,'AllTracks','-append')
    disp('Data saved!')
end
