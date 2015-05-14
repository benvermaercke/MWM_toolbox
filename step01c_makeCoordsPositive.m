clear all
clc

overwrite=0;

filename='01_TineV_Acq';

loadName=fullfile('datasets',filename);
% loadName=fullfile('dataSets_17parameters',filename);

load(loadName,'AllTracks','MWMtype')
if MWMtype==2
    M=AllTracks.data;
    re_alignment_values=[-min(M(:,5))+5 -min(M(:,6))+5];
    M(:,5)=M(:,5)+re_alignment_values(1);
    M(:,6)=M(:,6)+re_alignment_values(2);
else
    M=AllTracks.data;
    SR=mean(1./diff(M(1:10,4)));
    if SR==25
        %re_alignment_values=[-min(M(:,5))+5 -min(M(:,6))+5];
        %M(:,5)=M(:,5)+re_alignment_values(1);
        %M(:,6)=M(:,6)+re_alignment_values(2);
    else
    end
end
if overwrite==1
    %%
    AllTracks.data=M;
    save(loadName,'AllTracks','re_alignment_values','-append')
    disp('AllTracks overwritten')
end