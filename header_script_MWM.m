%%% General information common to all scripts goes here
path_dir=fileparts(mfilename('fullpath'));
addpath(genpath(path_dir))

if ispc
    %data_folder='E:\LeuvenData\Developement\MWMtoolbox\rawFiles\ACL_Reversal_acquisition_track';
    data_folder='C:\Users\u0056003\Documents\MWM_tracks_Iris\Track data_CT_stress';
else
    %folder_name='Disconnection SearchStrategies';
    %folder_name='tau85_ymaze';
    folder_name=''

    if ismac
        %data_root='/Users/benvermaercke/Dropbox (Personal)';
        data_root='/Users/benvermaercke/Dropbox (coxlab)';
        %data_folder=fullfile(data_root,'heatplots tau58');
        data_folder=fullfile(data_root,folder_name);
    else % server
        [~, user_name] = system('whoami');user_name=user_name(1:end-1);
        %root_folder=fullfile('/home/',user_name,'/MWM_toolbox/'); % temp location
        root_folder=fullfile('/home/',user_name,'/Dropbox (coxlab)/'); % temp location
        %data_folder=fullfile(root_folder,'heatplots tau58');
        data_folder=fullfile(root_folder,folder_name);
    end
end

%%% select folder with GUI if not specified
if ~exist('data_folder','var')
    cd(data_root)
    data_folder=uigetdir(data_root);
    cd(path_dir)
end

if isdir(data_folder)
    
    %%% Construct databse name
    if ispc
        A=strsplit(filesep,data_folder);
    else
        A=strsplit(data_folder,filesep);
    end
    databaseName=A{end};
    databaseName(databaseName==' ')='_';
    
    saveIt=1;
    MWMtype=2; % 1: old MWM | 2: new MWM | 3: open field | 4: y-maze
    switch MWMtype
        case 1
            data_cols=[2 3]; % Leuven
            im_size=[200 200];
            rescaleFactor=2; % improves the resolution of the resulting eps image
            kernel_size=35;
            correction_method=1;
            
        case 2
            data_cols=[2 3]; % Leuven
            im_size=[200 200];
            rescaleFactor=2; % improves the resolution of the resulting eps image
            kernel_size=35;
            correction_method=1;
        case 3
            data_cols=[3 4]; % Brisbane
            im_size=[40 40];
            rescaleFactor=10; % improves the resolution of the resulting eps image
            kernel_size=10;
            correction_method=3;
        case 4
            data_cols=[3 4]; % Brisbane
            im_size=[450 450];
            kernel_size=40;
            rescaleFactor=2; % improves the resolution of the resulting eps image
            correction_method=3;
        otherwise
    end
    border_size=[5 5];
    use_data_field='data';
    
    fprintf('Working from %s\n',data_folder)
else
    fprintf('Specified folder %s not found...\n',data_folder)
end
