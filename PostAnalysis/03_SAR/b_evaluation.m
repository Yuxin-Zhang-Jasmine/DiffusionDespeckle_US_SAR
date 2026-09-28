close all
clear
clc

% ------------parameter--------------
dataName = '14';   %[11, 12, 14, 50, 388]
%------------------------------------

scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
paperRepoRoot = fileparts(postAnalysisRoot);
srcRoot = fullfile(postAnalysisRoot, 'src');
diffusionSarRoot = fullfile(paperRepoRoot, 'DiffusionRestoration', '03_SAR');
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end

sarmode = 'spotlight';
observPath = [fullfile(diffusionSarRoot, 'observs', sarmode, dataName) filesep];
resultPath = [fullfile(scriptDir, 'results', sarmode, dataName) filesep];
zs = 0.005;
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');

type = 'Log';
load([observPath 'observ'  type '.mat']);
imgLog(observ, scan, 'observ')

alpha.('observ') = alphaResolution(observ);
[ssi.('observ'), smpi.('observ')]  = speckleSmoothing(observ, observ);

methodNames = {'diffvar5','diffvar10','diffvar20','diffvar50','diffvar200', ...
    'diffvarPlus5','diffvarPlus10','diffvarPlus20','diffvarPlus50','diffvarPlus200', ...
    'nlm1','nlm2','nlm3','nlm4','nlm5','blf1','blf2','blf3','blf4','blf5', ...
    'srad1','srad2','srad3','srad4','srad5','fans','scunet_color_real_gan','merlin'};
for i = 1:length(methodNames)
    methodName = methodNames{i};
    resultFile = fullfile(resultPath, methodName, 'result.mat');
    if ~isfile(resultFile)
        warning('evaluation:SkippingMissingMethod', ...
            'Skipping %s because its result is unavailable: %s', ...
            methodName, resultFile);
        continue
    end
    loadedResult = load(resultFile, 'result');
    result = loadedResult.result;
    alpha.(methodName) = alphaResolution(result);
    [ssi.(methodName), smpi.(methodName)]  = speckleSmoothing(observ, result);
end
save([resultPath, dataName '.mat'], "smpi" ,"ssi", "alpha");
