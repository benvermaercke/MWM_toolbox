function folder_name=getFolderName(filename)
f=fileparts(filename);
parts=strsplit(filesep,f);
folder_name=parts{end};