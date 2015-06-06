clear all
clc

header_script_MWM

plot_it=1;
saveIt=0;

kernel_size=10; % was 35
nPerm=0; % Determines number of random distributions to base population on (usually 10)
rescaleFactor=10; % improves the resolution of the resulting eps image

try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end
load(loadName,'AllTracks','TrackInfo','demographics','arenaCoords')

die
folders=demographics(:,1);
folder_vector=unique(folders);
nFolders=length(folder_vector);


[folder_mapping,folder_names]=getMapping({TrackInfo.folderName});
arena_mapping=demographics(:,6);

if 0
    %%
    iFolder=10
    folder_name=folder_names{iFolder};
    sel=folders==folder_vector(iFolder);
end


%%

%% small mod to get individual heatplots, without saving all randomized versions.
nAnimals_max=10;

for iAnimal=1:nAnimals_max
    
    Heatplots=struct;
    for iFolder=1:nFolders
        folder_name=folder_names{iFolder};
        folder_name_disp=strrep(folder_name,'_',' ');
        sel=folders==folder_vector(iFolder);
        track_nr_vector=find(sel);
        if length(track_nr_vector)<iAnimal
            fprintf('No animal %d in this group',iAnimal)
        else
            track_nr_vector=track_nr_vector(iAnimal);
            nTracks=length(track_nr_vector);
            
            if nTracks>0
                %%% create real heatplot
                M=cat(1,AllTracks(track_nr_vector).data_corrected);
                HP_actual=makeHeatplot(M(:,data_cols)*rescaleFactor,kernel_size*rescaleFactor,arenaCoords(1).im_size*rescaleFactor,[0 0]);
                
                %%
                %%% create permutations to find MU and SIGMA
                MU_vector=zeros(nPerm,1);
                SIGMA_vector=ones(nPerm,1);
                t0=clock;
                for iPerm=1:nPerm
                    %%
                    tracks_random=[];
                    for iTrack=1:nTracks
                        track_nr=track_nr_vector(iTrack);
                        arena_nr=arena_mapping(track_nr);
                        track_data=AllTracks(track_nr).data(:,data_cols);
                        R_track=randomizeTrack(track_data,arenaCoords(arena_nr+1));
                        tracks_random=cat(1,tracks_random,R_track);
                        
                        if 0
                            %%
                            subplot(211)
                            plot(track_data(:,1),track_data(:,2))
                            axis([0 60 0 60])
                            axis equal
                            subplot(212)
                            plot(R_track(:,1),R_track(:,2))
                            axis([0 60 0 60])
                            axis equal
                        end
                    end
                    HP_random=makeHeatplot(tracks_random,kernel_size,arenaCoords.im_size,[1 0]);
                    MU_vector(iPerm)=mean(HP_random(:));
                    SIGMA_vector(iPerm)=std(HP_random(:));
                    
                    progress(iPerm,nPerm,t0)
                end
                
                %%% analyse results
                if isempty(MU_vector)
                    MU=mean(HP_actual(:));
                    SIGMA=std(HP_actual(:));
                else
                    MU=mean(MU_vector);
                    SIGMA=mean(SIGMA_vector);
                end
                heatplot_norm=(HP_actual-MU)/SIGMA;
                
                Heatplots(iFolder).folder_name=folder_name;
                Heatplots(iFolder).folder_name_disp=folder_name_disp;
                Heatplots(iFolder).nTracks=nTracks;
                Heatplots(iFolder).HP_actual=HP_actual;
                Heatplots(iFolder).nPerm=nPerm;
                Heatplots(iFolder).rescaleFactor=rescaleFactor;
                Heatplots(iFolder).kernel_size=kernel_size;
                Heatplots(iFolder).MU_vector=MU_vector;
                Heatplots(iFolder).MU=MU;
                Heatplots(iFolder).SIGMA_vector=SIGMA_vector;
                Heatplots(iFolder).SIGMA=SIGMA;
                Heatplots(iFolder).heatplot_norm=heatplot_norm;
                
                %%% Save results after every folder
                if saveIt==1
                    disp('Saved heatplot information')
                    saveName=sprintf([loadName '_M%03d'],iAnimal)
                    save(saveName,'Heatplots','-append')
                end
            end
        end
    end
end
