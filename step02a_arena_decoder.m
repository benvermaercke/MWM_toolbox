clear all
%clc

header_script_MWM

plotIt=1;
%saveIt=0;

loadName=fullfile('dataSets',databaseName);
% loadName=fullfile('dataSets_17parameters',filename);
load(loadName,'AllTracks','nTracks','demographics')

arena_IDs=demographics(:,6);
arena_ID_vector=unique(arena_IDs);
nArena=length(arena_ID_vector);
arenaCoords=struct;
for arena_selector=1:nArena
    sel=arena_IDs==arena_ID_vector(arena_selector);
    if sum(sel)>0
        M=cat(1,AllTracks(sel).data);
        X=M(:,data_cols(1));
        Y=M(:,data_cols(2));
        
        switch 1
            case 1
                centerX=mean([min(X) max(X)]);
                centerY=mean([min(Y) max(Y)]);
        end
        
        arenaCoords(arena_selector).center=[centerX centerY];
        arenaCoords(arena_selector).top=[centerX min(Y)];
        arenaCoords(arena_selector).bottom=[centerX max(Y)];
        arenaCoords(arena_selector).left=[min(X) centerY];
        arenaCoords(arena_selector).right=[max(X) centerY];
        arenaCoords(arena_selector).im_size=round([max(X)+border_size(1) max(Y)+border_size(2)]);
        arenaCoords(arena_selector).poly_rect=[min(X) min(X) max(X) max(X) min(X); min(Y) max(Y) max(Y) min(Y) min(Y)];
        %arenaCoords(arena_selector).mask=H_TH;
        
    else
        arena_selector
        disp('no tracks')
    end
end


%%% overwrite parameters in the datafile
if saveIt==1
    %%
    save(loadName,'arenaCoords','-append')
    disp(['ArenaCoords coordinates were saved to data file: ' loadName])
end

