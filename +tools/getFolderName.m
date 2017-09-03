function folder_name=getFolderName(filename)
f=fileparts(filename);
parts=strsplit(f,filesep);
folder_name=parts{end};