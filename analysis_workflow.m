clearvars
clc

header_script_MWM

%%% Instantiate database class based on data_folder, which can come from
%%% uitgetfolder
dataset=classes.trajectory_class();
stop

%% set 
dataset.set_prior(PriorKnowledge)

%% Check for files types, number and location
dataset.file_scanner()
dataset.file_parser()

%% Load example file to delineate which data have to be read in...
dataset.sample_data(3)

%% Select columns to read, can be GUI
dataset.set_cols2read(1,1:4)

%% Read in the data, given filter defined above
dataset.read_data()

%% Save data to file
dataset.save_data()

%% process track data
% fill the gaps
dataset.fill_the_gaps()

%% resample to 5Hz if needed
dataset.resample_data()

%% if probe trial, cut trial up to 1st platform crossing
if probe_trial==true
    dataset.get_latency_firstCrossing()
    dataset.track_selector()
end

%% extract parameters
% old line: [trackProps, vector]=getTrackStats_used(data,poolCoords,[],platFormCoords_thisTrack);
dataset.extract_parameters()

%% get track classification
dataset.classify_track()

%% Save data to file
dataset.save_data()

%% save output file
dataset.create_output()

%% 
dataset.plot_track(60)

