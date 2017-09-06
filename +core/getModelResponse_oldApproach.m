function decision = getModelResponse_oldApproach(SVMmodel,SVMmatrix)

nClasses=9;

nTest=size(SVMmatrix,1);
pairs=possibleComparisons2(nClasses);
nPairs=size(pairs,1);
nIter=size(SVMmodel,3);

%%% Get model response for all selected test tracks
increment=1;
decisionMatrix=zeros(nClasses,nTest,nIter);
t0=clock;
for pair_index=1:nPairs    
    %progress(pair_index,nPairs,t0)
    pair_index
        
    class1=pairs(pair_index,1);
    class2=pairs(pair_index,2);
    
    for iter=1:nIter
        output=svmclassify(SVMmodel{class1,class2,iter},SVMmatrix,'showplot',false)';
        decisionMatrix(class1,output==1,iter)=decisionMatrix(class1,output==1,iter)+increment;
        decisionMatrix(class2,output~=1,iter)=decisionMatrix(class2,output~=1,iter)+increment;
    end
end

decision=zeros(nTest,1);
for track_index=1:nTest
    classProb=decisionMatrix(:,track_index,:);
    classProb=squeeze(mean(classProb,3));
    decision(track_index,1)=find(classProb==max(classProb),1,'first');
end