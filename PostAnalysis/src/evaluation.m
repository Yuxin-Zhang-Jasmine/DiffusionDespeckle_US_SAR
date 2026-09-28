function [CNR, gCNR] = evaluation(path_phantom,image,flagDisplay)
    %-- Function used for the evaluation in ultrasound imaging
    
    %-- Authors: yuxin Zhang

    %-- $Date: 2024/Nov/22 $  

    %-- Initialization
    CNR = 0; gCNR = 0;

    %-- Read input data
    pht = us_phantom();
    pht.read_file(path_phantom);

    if pht.occlusionDiameter ~= 0
        %close all
        %-- Perform testing for CNR
        CNR = us_contrast();
        CNR.pht = pht;
        CNR.scan = image.scan;
        CNR.image = image;
        CNR.flagDisplay = flagDisplay;
        CNR.evaluate();
%         %--keep all of the values
%         [M, N] = size(CNR.score);
%         CNRres = cell(M,N);
%         for i = 1: M*N
%             CNRres{i} = CNR.score(i);
%         end
%         CNR = CNRres;
        %--keep only the average 
        CNR = mean(CNR.score(:));
        %--all values in a vector
        % CNR = CNR.score;


        %close all
        %-- Perform testing for gCNR
        gCNR = us_gcnr();
        gCNR.pht = pht;
        gCNR.scan = image.scan;
        gCNR.image = image;
        gCNR.flagDisplay = flagDisplay;
        gCNR.evaluate();
%         %--keep all of the values
%         [M, N] = size(gCNR.score);
%         gCNRres = cell(M,N);
%         for i = 1: M*N
%             gCNRres{i} = gCNR.score(i);
%         end
%         gCNR = gCNRres;
        %--keep only the average        
        gCNR = mean(gCNR.score(:));   
        %--all values in a vector
        % gCNR = gCNR.score;        
    end
    
end



    