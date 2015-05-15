clear all
clc

header_script

data_folder='/Users/benvermaercke/Dropbox (coxlab)/Disconnection SearchStrategies';
folder_names=getSubFolders(data_folder);

nFolders=length(folder_names);

%% Convert folder names to suitable format
curr_dir=pwd;
cd(data_folder)
for iFolder=1:nFolders
    folder_name=folder_names{iFolder};
    switch length(strfind(folder_name,' '))
        case 0
        case 1
            str=char(sscanf(folder_name,'%s D%*d'))';
            num=sscanf(folder_name,'%*s D%d');
        case 2
            str=char(sscanf(folder_name,'%s%c%s D%*d'))';
            num=sscanf(folder_name,'%*s %*s D%d');
        otherwise
            error('no format defined for folder name')
    end
    
    if strfind(folder_name,'_')
        %disp('Already converted')
    else
        new_folder_name=[strrep(str,' ','_') '_' sprintf('%03d',num)];
        movefile(folder_name,new_folder_name);
    end
end
cd(curr_dir)

