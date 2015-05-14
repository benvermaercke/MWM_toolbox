clear all
clc

% Q: how many pixels for 1 cm? => data are in cm!
% A: find diameter of pool and divide 150 by that number
% poolCoords.radius*2 = 149.0739


data_file_name='..\datasets_17parameters\ACL_MAGL_week1.mat';
if exist(data_file_name,'file')
    load(data_file_name)
    
    %% Get conversion from pixels to cm
    diameter_in_pixels=poolCoords.radius*2;
    diameter_in_cm=diameter_in_pixels;
    
    pixels_to_cm_conversion_factor=diameter_in_cm/diameter_in_pixels;
    
    track_allocation_vector=AllTracks.data(:,2);
    track_nr_vector=unique(track_allocation_vector);
    nTracks=length(track_nr_vector);
    
    threshold=5;
    max_X=120;
    
    data_matrix=NaN(nTracks,11);
    t0=clock;
    for iTrack=1:nTracks
        progress(iTrack,nTracks,t0)
        track_nr=track_nr_vector(iTrack);
        sel=track_allocation_vector==track_nr;
        track_data=AllTracks.data(sel,4:6);
        
        time_axis=track_data(:,1);
        latency=max(time_axis);
        
        velocity_data=calc_velocity(track_data);
        velocity_data_cm=velocity_data*pixels_to_cm_conversion_factor;
        
        block_size=15;
        nBlocks=ceil(latency/15);
        floating_per_block=NaN(1,nBlocks);
        for iBlock=1:nBlocks
            sel=between(time_axis(1:end-1),[(iBlock-1)*block_size+1 iBlock*block_size]);
            floating_per_block(iBlock)=mean(velocity_data_cm(sel)<threshold)*100;
        end
        
        data_matrix(iTrack,1:3+nBlocks)=[iTrack track_nr latency floating_per_block];
        
        plotIt=0;
        if plotIt==1
            plot(track_data(1:end-1,1),velocity_data_cm,'b')
            line([0 max_X],[threshold threshold],'color','r')
            line([0:15:max(time_axis) ; 0:15:max(time_axis)],[0 50])
            xlabel('Time (seconds)')
            ylabel('Velocity (cm/second)')
            box off
            axis([0 max_X 0 50])
        end
        
    end    
end

data_matrix

