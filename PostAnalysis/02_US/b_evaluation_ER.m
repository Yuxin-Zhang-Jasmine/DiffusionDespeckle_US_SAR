close all
clear
clc

scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
paperRepoRoot = fileparts(postAnalysisRoot);
srcRoot = fullfile(postAnalysisRoot, 'src');
diffusionUsRoot = fullfile(paperRepoRoot, 'DiffusionRestoration', '02_US');
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end

nPW = '11pw';
dataName = 'ER';
observPath = [fullfile(diffusionUsRoot, 'observs', nPW, dataName) filesep];
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];
zs = 0.01;
if strcmp(dataName, 'SC')
    path_phantom = fullfile(srcRoot, 'phantoms', 'picmus_phantom_2.hdf5');
elseif strcmp(dataName, 'ER')
    path_phantom = fullfile(srcRoot, 'phantoms', 'picmus_phantom_3.hdf5');
elseif strcmp(dataName, 'EC') 
    path_phantom = fullfile(srcRoot, 'phantoms', 'picmus_phantom_4.hdf5');
end
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');

ImageSet = us_image();
ImageSet.scan = scan;
ImageSet.number_plane_waves=11;
ImageSet.postenv = 0;
flag_display = 0;

type = 'Log';
load([observPath 'observ'  type '.mat']);
imgLog(observ, scan, 'observ')

ImageSet.data = observ; 
[CNR.('observ'), gCNR.('observ')] = evaluation(path_phantom, ImageSet, flag_display);

alpha.('observ') = alphaResolution(observ);
[ssi.('observ'), smpi.('observ')]  = speckleSmoothing(observ, observ);

methodNames = {'dnnlambda', 'gcf', 'ebmv', 'diffmean', ...
               'obnlm1', 'blf1', 'admss1', 'obnlm2', 'blf2', 'admss2', ...
               'obnlm3', 'blf3', 'admss3', 'obnlm4', 'blf4', 'admss4', ...
               'obnlm5', 'blf5', 'admss5', ...
               'speckle2speckle', 'scunet_color_real_gan', ...
               'diffvar5', 'diffvarPlus5', 'diffvar10', 'diffvarPlus10', 'diffvar20', 'diffvarPlus20'};
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

    ImageSet.data = result; 
    [CNR.(methodName), gCNR.(methodName)] = evaluation(path_phantom, ImageSet, flag_display);
    
    alpha.(methodName) = alphaResolution(result);
    [ssi.(methodName), smpi.(methodName)]  = speckleSmoothing(observ, result);
end
save([resultPath, dataName '.mat'], "smpi" ,"ssi", "alpha", "gCNR");
