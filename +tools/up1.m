function out=up1(folder)

parts=strsplit(folder,filesep);
out=strjoin(parts(1:end-1),filesep);