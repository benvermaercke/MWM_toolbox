clear all
clc

loadName='dataSets\SVMtrainingSet_RS_34parameters.mat';
load(loadName)
TrackStatMatrix2038=TrackStatMatrix(TrackStatsExist==1,:);
trackClassification_vector2038=trackClassification_vector(TrackStatsExist==1,4);
nClasses=length(unique(trackClassification_vector2038));

%%
classes=trackClassification_vector2038;

N_vector=pivotTable2(classes,1,'length',1)';

class1=9;
class2=2;

A=TrackStatMatrix2038(trackClassification_vector2038==class1,:);
B=TrackStatMatrix2038(trackClassification_vector2038==class2,:);
B1=B(1:round(end/2),:);
B2=B(round(end/2)+1:end,:);

SVMmatrix1=vertcat(A,B1);
classes1=[zeros(size(A,1),1)+1 ; zeros(size(B1,1),1)+2];
SVMmatrix2=vertcat(A,B2);
classes2=[zeros(size(A,1),1)+1 ; zeros(size(B2,1),1)+2];
trainTest=mod(1:355,2)';

[PC1 svmStruct{1}]=SVM_classifier(SVMmatrix1,classes1,trainTest(1:length(classes1)));
[PC2 svmStruct{2}]=SVM_classifier(SVMmatrix2,classes2,trainTest(1:length(classes2)));

%% Combine SVM's to one

N=length(svmStruct);
SV=[];
alpha=[];
SupportVectorIndices=[];
GroupNames=[];
shifts=[];
scaleFactors=[];
for index=1:N
    S=svmStruct{index};
    
    %%% Adding part
    SV=vertcat(SV,S.SupportVectors);
    alpha=vertcat(alpha,S.Alpha);
    SupportVectorIndices=vertcat(SupportVectorIndices,S.SupportVectorIndices);
    GroupNames=vertcat(GroupNames,S.GroupNames);
    
    %%% Averagin part
    Biases(index)=S.Bias;
    shifts=vertcat(shifts,S.ScaleData.shift);
    scaleFactors=vertcat(scaleFactors,S.ScaleData.shift);
end
Bias=mean(Biases);
ScaleData.shift=mean(shifts,1);
ScaleData.scaleFactor=mean(scaleFactors,1);


newSVM.SupportVectors=SV;
newSVM.Alpha=alpha;
newSVM.Bias=Bias;
newSVM.KernelFunction=svmStruct{1}.KernelFunction;
newSVM.KernelFunctionArgs=svmStruct{1}.KernelFunctionArgs;
newSVM.GroupNames=GroupNames;
newSVM.SupportVectorIndices=SupportVectorIndices;
newSVM.ScaleData=ScaleData;
newSVM.FigureHandles=svmStruct{1}.FigureHandles;

[PC1 PC2 mean(svmclassify(newSVM,vertcat(A,B)))]
