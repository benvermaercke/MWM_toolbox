clear all
clc

header_script

save_it=0;

try
    loadName=fullfile('dataSets',databaseName)
catch
    loadName=fullfile('dataSets_17parameters',filename);
end

load(loadName,'AllTracks')
M=AllTracks.data;

tracks=unique(M(:,2));
nTracks=length(tracks);
die

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
if save_it==1
    %%
    mean(isnan(AllTracks.data(:,5)))
    AllTracks.data=M;
    mean(isnan(AllTracks.data(:,5)))
    save(loadName,'AllTracks','-append')
end
