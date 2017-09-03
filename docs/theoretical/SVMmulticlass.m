clear all
clc

load fisheriris

SVMmatrix=meas;
class_vector=species;

[train test]=crossvalind('holdout',species,.5);
SVMmatrix_train=SVMmatrix(train,:);
classes_train=class_vector(train);

SVMmatrix_test=SVMmatrix(test,:);
classes_test=class_vector(test);

classes=unique(class_vector);
pairs=possibleComparisons2(length(classes),3);
%pairs=possibleComparisons2(length(classes));
nPairs=size(pairs,1);

for pair_index=1:nPairs
    class1=classes(pairs(pair_index,1));
    class2=classes(pairs(pair_index,2));
    
    selection=ismember(classes_train,[class1 class2]);
    target=ismember(classes_train(selection),class1);
    SVMmatrix=SVMmatrix_train(selection,:);
    SVMmodels{pair_index}=svmtrain(SVMmatrix,double(target),'showplot',false);
end

%% Test cycle
nTest=size(SVMmatrix_test,1);
decisionMatrix=zeros(3,nTest);
increment=1;
for pair_index=1:nPairs
    class1=pairs(pair_index,1);
    class2=pairs(pair_index,2);
    output=svmclassify(SVMmodels{pair_index},SVMmatrix_test,'showplot',false);
    decisionMatrix(class1,output==1)=decisionMatrix(class1,output==1)+1;
    decisionMatrix(class2,output~=1)=decisionMatrix(class2,output~=1)+1;
end
[m decisions]=max(decisionMatrix);

mean(strcmpi(classes_test,classes(decisions)))

%% test cycle old method

for index=1:nTest
    classProbs_all=zeros(3);
    for pair_index=1:nPairs
        class1=pairs(pair_index,1);
        class2=pairs(pair_index,2);        
        output=svmclassify(SVMmodels{pair_index},SVMmatrix_test(index,:),'showplot',false);
        classProbs_all(class1,class2)=output;
    end
    classProbs=mean(classProbs_all,3);
    D=mean(classProbs,2);
    E=max(mean(classProbs,1))-mean(classProbs,1)';
    D=D+E;
    decision=find(D==max(D),1,'first');
    decisions2(index)=decision;
end

[decisions' decisions2']

[mean(strcmpi(classes_test,classes(decisions))) mean(strcmpi(classes_test,classes(decisions2)))]