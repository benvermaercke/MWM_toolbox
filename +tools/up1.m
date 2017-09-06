function out=up1(folder)

parts=tools.strsplit(folder,filesep);
out=tools.strjoin(parts(1:end-1),filesep);