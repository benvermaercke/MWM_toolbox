clear all
clc

header_script_MWM

plot_it=1;
saveIt=0;
TH_it=0;
TH=2.7;

kernelSize=10; % was 35
nPerm=0; % Determines number of random distributions to base population on (usually 10)
rescaleFactor=6; % improves the resolution of the resulting eps image

try
    loadName=fullfile('dataSets',databaseName);
catch
    loadName=fullfile('dataSets_17parameters',filename);
end
load(loadName,'AllTracks','TrackInfo','demographics','arenaCoords')

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
for iFolder=1:nFolders
    folder_name=folder_names{iFolder};
    folder_name_disp=strrep(folder_name,'_',' ');
    sel=folders==folder_vector(iFolder);
    if sum(sel)>0
        track_nr_vector=find(sel);
        nTracks=length(track_nr_vector);
        
        %%% create real heatplot
        M=cat(1,AllTracks(sel).data_corrected);
        HP_actual=makeHeatplot(M(:,data_cols)*rescaleFactor,kernelSize*rescaleFactor,arenaCoords(1).im_size*rescaleFactor,[0 0]);
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
            HP_random=makeHeatplot(tracks_random,kernelSize,arenaCoords.im_size,[1 0]);
            MU_vector(iPerm)=mean(HP_random(:));
            SIGMA_vector(iPerm)=std(HP_random(:));
            
            progress(iPerm,nPerm,t0)
        end
        %%
        if isempty(MU_vector)
            MU=mean(HP_actual(:));
            SIGMA=std(HP_actual(:));
        else
            MU=mean(MU_vector);
            SIGMA=mean(SIGMA_vector);
        end
        heatplot_norm=(HP_actual-MU)/SIGMA;
        
        if 0
            %%
            subplot(211)
            imshow(HP_actual,[-4 4]*1500)
            
            subplot(212)
            imshow(HP_random,[-4 4]*1500)
            colormap parula
        end
        
        %%%
        coords=[3 3 30 30]*rescaleFactor;
        %coords=[0 0 20 20]*rescaleFactor;
        line_width=5;
        mask=drawRect((arenaCoords(1).im_size)*rescaleFactor,coords+[1 1 0 0]);
        
        heatplot_show=imresize(heatplot_norm,rescaleFactor);
        if saveIt==0
            nCols=round(sqrt(nFolders));
            nRows=round(nFolders/nCols);
            subplot(nRows,nCols,iFolder)
        else
            subplot(111)
        end        
        
        if TH_it==1
            heatplot_show_TH=heatplot_show>TH;
            RP=regionprops(heatplot_show_TH);
            RP.Area
            
            IL = bwlabel(heatplot_show_TH);
            R = regionprops(heatplot_show_TH,'Area');
            ind = find([R.Area] >= 3000 );
            Iout = ismember(IL,ind);
            
            im=imshow(Iout ,[0 1]);
        else
            im=imshow(heatplot_show,[-1 1]*4);
        end
        
        set(im,'AlphaData',imresize(mask,rescaleFactor,'nearest'))
        hold on
        
        plot(coords([2 2])*rescaleFactor,coords([1 3])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([2 4])*rescaleFactor,coords([1 1])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([2 4])*rescaleFactor,coords([3 3])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([4 4])*rescaleFactor,coords([1 3])*rescaleFactor,'k-','lineWidth',line_width)
        hold off
        
        significant_pixels=mean(heatplot_norm(:)>TH)*100;
        
        title_str=sprintf([folder_name_disp '(N=%d, sign=%3.2f%%)'],[sum(sel) significant_pixels])
        T=title(title_str);
        
        
        set(T,'FontName','Courier New','fontSize',6)
        axis([coords(1) coords(3) coords(2) coords(4)]*rescaleFactor)
        
        colormap parula
        drawnow
        
        if saveIt==1
            %%            
            if TH_it==1
                saveName=fullfile('output',databaseName,[folder_name '_TH']);
            else
                saveName=fullfile('output',databaseName,folder_name);
            end
            savec(saveName)
            print(gcf,'-dpng','-r300',saveName)
            print(gcf,saveName,'-depsc')
        end
        
        %%
        
    end
end

