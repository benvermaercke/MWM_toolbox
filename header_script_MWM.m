saveIt=1;
MWMtype=2; % 1: old | 2: new |

path_dir=fileparts(mfilename('fullpath'));
addpath(genpath(path_dir))

if ispc
    data_folder='E:\LeuvenData\Developement\MWMtoolbox\rawFiles\ACL_Reversal_acquisition_track';
else
    if ismac
        data_root='/Users/benvermaercke/Dropbox (Personal)';
        data_folder=fullfile(data_root,'Disconnection SearchStrategies');
    else % server
        [~, user_name] = system('whoami');user_name=user_name(1:end-1);
        %root_folder=fullfile('/home/',user_name,'/MWM_toolbox/'); % temp location
        root_folder=fullfile('/home/',user_name,'/Dropbox (coxlab)/'); % temp location
        data_folder=fullfile(root_folder,'Disconnection SearchStrategies');
    end
end

%%% select folder with GUI if not specified
if ~exist('data_folder','var')
    cd(data_root)
    data_folder=uigetdir(data_root);
    cd(path_dir)
end

%%% Construct databse name
A=strsplit(data_folder,filesep);
databaseName=A{end};
databaseName(databaseName==' ')='_';

im_size=[200 200];

fprintf('Working from %s\n',data_folder)

