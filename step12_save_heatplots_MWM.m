clear all
clc

header_script_MWM

plot_it=1;
%saveIt=0;
TH_it=0;
TH=2.7;

rescaleFactor=6; % improves the resolution of the resulting eps image

try
    loadName=fullfile(data_folder,'dataSets',databaseName);
catch
    loadName=fullfile(data_folder,'dataSets_17parameters',databaseName);
end
load(loadName,'Heatplots','TrackInfo','demographics','arenaCoords')

folders=demographics(:,1);
folder_vector=unique(folders);
nFolders=length(folder_vector);
[folder_mapping,folder_names]=getMapping({TrackInfo.folderName});

%%
for iFolder=1:nFolders
    folder_name=folder_names{iFolder};
    folder_name_disp=strrep(folder_name,'_',' ');
    sel=folders==folder_vector(iFolder);
    track_nr_vector=find(sel);
    track_nr_vector=track_nr_vector(1);
    nTracks=length(track_nr_vector);
    
    if nTracks>0                
   
        HP=Heatplots(iFolder);
        heatplot_norm=(HP.HP_actual-HP.MU)/HP.SIGMA;
        rescaleFactor=HP.rescaleFactor;
        
        %%%
        coords=[3 3 30 30]*HP.rescaleFactor;
        line_width=5;
        mask=drawRect((arenaCoords(1).im_size)*rescaleFactor,coords+[1 1 0 0]);
        
        %%
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

            %im=imshow(heatplot_show_TH,[0 1]);
            im=imshow(Iout,[0 1]);
            %im=imshow(heatplot_show_TH+Iout,[0 2]);
        else
            im=imshow(heatplot_show,[]);
        end
        
        set(im,'AlphaData',imresize(mask,rescaleFactor,'nearest'))
        hold on
        
        plot(coords([2 2])*rescaleFactor,coords([1 3])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([2 4])*rescaleFactor,coords([1 1])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([2 4])*rescaleFactor,coords([3 3])*rescaleFactor,'k-','lineWidth',line_width)
        plot(coords([4 4])*rescaleFactor,coords([1 3])*rescaleFactor,'k-','lineWidth',line_width)
        hold off
        
        significant_pixels=mean(heatplot_norm(:)>TH)*100;
        
        title_str=sprintf([folder_name_disp ' (N=%d, sign=%3.2f%%)'],[nTracks significant_pixels]);
        fprintf([folder_name_disp ' (N=%d)\n'],nTracks);
        T=title(title_str);
        
        
        set(T,'FontName','Courier New','fontSize',6)
        axis([coords(1) coords(3) coords(2) coords(4)]*rescaleFactor)
        
        colormap jet%parula
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

