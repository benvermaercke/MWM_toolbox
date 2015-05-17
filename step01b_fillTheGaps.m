clear all
clc

header_script

%saveIt=0;

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
        M(:,2)=fillTheGaps2(M(:,2));
        M(:,3)=fillTheGaps2(M(:,3));
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
