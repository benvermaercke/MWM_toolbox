clearvars
clc

%%% this script will set up the GUI the exposes critical features from the
%%% trajectory_class object
% needs:
% - data folder : do we include older file types?

% - data columns needed : this varies for different generations of the data
% - config file containing following parameters (xml - json - xlsx - plain - table)
% - reversal or not : needs two locations
% - probe trial or not
% - arena definition file :
%   - pool center XY , radius
%   - platform 1 center XY , radius
%   - platform 2 center XY , radius (optional)
% - model file?

% - button for set folder : load example file and check data columns
% - button for set config file : graph for showing arena cartoon
% - button for loading data : progress bar + create cache file
% - button for running analysis : progress bar
% - button for exporting data : print file location
% - need output box

%% initialize class
dataset=classes.trajectory_class();

%% draw GUI
figure(1)
clf
dataset.draw_GUI()

if 0
    %% dependency report
    [fList,pList] = matlab.codetools.requiredFilesAndProducts('MWM_GUI.m');
    fList'
end

if 0
    %% plot data from many tracks - e.g. before running Process data
    figure(2)
    %%
    dataset.plot_track(1:20)
end

if 0
    %% plot individual track data with classification
    figure(3)
    %%
    dataset.plot_track(1)
end

