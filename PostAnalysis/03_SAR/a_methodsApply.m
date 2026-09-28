close all
clear
clc

% ------------parameter--------------
dataName = '14';   %[11, 12, 14, 50, 388]
%------------------------------------

% Project paths. Python SOTA methods at the end of this script are run
% automatically with the existing ddrm environment; no manual activation or
% terminal pauses are required.
scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
paperRepoRoot = fileparts(postAnalysisRoot);
srcRoot = fullfile(postAnalysisRoot, 'src');
diffusionRoot = fullfile(paperRepoRoot, 'DiffusionRestoration');
diffusionSarRoot = fullfile(diffusionRoot, '03_SAR');
sotaPythonRoot = fullfile(srcRoot, 'SOTApython');
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end
ddrmPython = '/home/mingze/.local/share/miniforge3/envs/ddrm/bin/python';

sarmode = 'spotlight';
observPath = [fullfile(diffusionSarRoot, 'observs', sarmode, dataName) filesep];
diffusionResultPath = fullfile(diffusionSarRoot, 'results', sarmode, dataName);
resultPath = [fullfile(scriptDir, 'results', sarmode, dataName) filesep];
scan = linear_scan(linspace(1,256*2,256).', linspace(1, 256*2,256).');
% load(['../9_empiricalModelAnalysis/mdls/Deconv08-exp4x/mdlDeconv08-exp4x_fx.mat'])

type = 'Log';
load([observPath 'observ'  type '.mat']);
imgLog(observ, scan, 'observ')

%----------------------- Diffusion 5, 10, 20, 50, 200 ---------------------
cvrange = 30;
for repeat = [5,10,20,50,200]
    Ireal = zeros(repeat, 256, 256);
    Iimag = zeros(repeat, 256, 256);
    for i = 1: repeat
        load(fullfile(diffusionResultPath, ['I' num2str(i) '_-1.mat'])) % load Ix
        load(fullfile(diffusionResultPath, ['Q' num2str(i) '_-1.mat'])) % load Qx
        Ireal(i,:,:) = squeeze(Ix); 
        Iimag(i,:,:) = squeeze(Qx);
    end
    meanreal = squeeze(mean(Ireal));
    meanimag = squeeze(mean(Iimag));
    varreal = squeeze(var(Ireal)); 
    varimag = squeeze(var(Iimag));
    
    %-- diffmean
    methodName = ['diffmean' num2str(repeat)];
    result = sqrt(meanreal.^2 + meanimag.^2);
    result = 20*log10(result ./ max(result(:)));
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    DiffMean = result;
    
    %-- diffvar p
    methodName = ['diffvar' num2str(repeat)];
    result = (varreal + varimag)./2;
    result = 20*log10(result ./ max(result(:)));
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    % --------correct the black hole caused by the ceiling effect.
    thereshold = 1;  %0.5
    correctMap = find(DiffMean-result>thereshold);
    result(correctMap) = DiffMean(correctMap);
    % ------------------------------------------------------------
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    imgLog(result, scan, methodName)
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);

    %-- diffvar p+
    methodName = ['diffvarPlus' num2str(repeat)];
    result = (varreal + varimag)./2;
    result = 20*log10(result ./ max(result(:)));
    result = result ./ 1.1;
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    % --------correct the black hole caused by the ceiling effect.
    thereshold = 1;  %0.5
    correctMap = find(DiffMean-result>thereshold);
    result(correctMap) = DiffMean(correctMap);
    % ------------------------------------------------------------
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    imgLog(result, scan, methodName)
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);

end
%--------------------------------------------------------------



%-- NLM BLF SRAD 1-5
NLMDOSes = [0.06, 0.08, 0.1, 0.18, 0.3];
BLFDOSes = [0.01, 0.05, 0.09, 0.2, 10];
BLFsigma = [1, 1, 1, 1.5, 2];
SRADDOSes = [0.01, 0.05, 0.1, 0.15, 0.2];
for index = [1,2,3,4,5]
    methodName = ['nlm' num2str(index)];
    result = normalization(imnlmfilt(observ, DegreeOfSmoothing=NLMDOSes(index))); 
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    methodName = ['blf' num2str(index)];
    result = normalization(imbilatfilt(observ, DegreeOfSmoothing=BLFDOSes(index),spatialSigma = BLFsigma(index))); 
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    methodName = ['srad' num2str(index)];
    result = normalization(specklefilt(observ, DegreeOfSmoothing=SRADDOSes(index), NumIterations=100)); 
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
end


%-- FANS (optional; excluded from the public repository)
fansRoot = fullfile(srcRoot, 'FANS');
if isfile(fullfile(fansRoot, 'FANS.m')) && exist('FANS', 'file') ~= 0
    try
        methodName = 'fans';
        L = 1;
        result = normalization(FANS(double(observ),L)); % single look
        imgLog(result, scan, methodName)
        if ~exist([resultPath methodName], 'dir')
            mkdir([resultPath methodName]);
        end
        save([resultPath methodName '/result.mat'], "result", '-mat');
        imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    catch fansError
        warning('methodsApply1:SkippingFANSFailure', ...
            'FANS could not run and will be skipped: %s', fansError.message);
    end
else
    warning('methodsApply1:SkippingFANS', ...
        ['Skipping FANS because this optional, noncommercial dependency ' ...
         'is not distributed with the public repository.']);
end

%-- SCUNet: automatically run with the ddrm Python environment
methodName = 'scunet_color_real_gan';  % 'scunet_gray_15', 'scunet_gray_25', 'scunet_gray_50', 
scunetRoot = fullfile(sotaPythonRoot, 'SCUNet-main');
result = runPythonSota(methodName, ddrmPython, ...
    fullfile(scunetRoot, 'scunet_us.py'), observPath, ...
    fullfile(resultPath, methodName), ...
    {'--model_name', methodName, '--model_zoo', fullfile(scunetRoot, 'model_zoo')});
imgLog(result, scan, methodName)
imwrite(result, [resultPath methodName '/pic_' methodName '.png']);


%-- MERLIN: automatically run with the ddrm Python environment
methodName = 'merlin'; 
deepdespecklingScript = fullfile(sotaPythonRoot, 'deepdespeckling', ...
    'deepdespeckling', 'test_deepdespeckling.py');
result = runPythonSota(methodName, ddrmPython, deepdespecklingScript, ...
    fullfile(observPath, 'merlin'), fullfile(resultPath, methodName), ...
    {'--model_name', sarmode});
imgLog(result, scan, methodName)
imwrite(result, [resultPath methodName '/pic_' methodName '.png']);


%-- SAR2SAR: automatically run with the ddrm Python environment
methodName = 'sar2sar'; 
result = runPythonSota(methodName, ddrmPython, deepdespecklingScript, ...
    fullfile(observPath, 'sar2sar'), fullfile(resultPath, methodName), ...
    {'--model_name', 'sar2sar'});
imgLog(result, scan, methodName)
imwrite(result, [resultPath methodName '/pic_' methodName '.png']);


function result = runPythonSota(methodName, pythonExecutable, scriptPath, ...
        inputDir, outputDir, extraArguments)
%RUNPYTHONSOTA Run one Python SOTA method and load its validated result.
    if ~isfile(pythonExecutable)
        error('methodsApply1:MissingPython', ...
            'ddrm Python executable not found: %s', pythonExecutable);
    end
    if ~isfile(scriptPath)
        error('methodsApply1:MissingPythonScript', ...
            '%s Python script not found: %s', methodName, scriptPath);
    end
    if ~isfolder(inputDir)
        error('methodsApply1:MissingPythonInput', ...
            '%s input directory not found: %s', methodName, inputDir);
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    commandParts = [{pythonExecutable, scriptPath}, extraArguments, ...
        {'--input_data', inputDir, '--output_data', outputDir}];
    for index = 1:numel(commandParts)
        commandParts{index} = shellQuote(commandParts{index});
    end

    % MATLAB prepends its own native libraries to LD_LIBRARY_PATH. Remove that
    % variable only for the child process so Conda/PyTorch load their own libs.
    command = ['env -u LD_LIBRARY_PATH ' strjoin(commandParts, ' ') ' 2>&1'];
    fprintf('\n===========================\n');
    fprintf('Running %s automatically with ddrm...\n', methodName);
    [status, commandOutput] = system(command);
    fprintf('%s', commandOutput);
    if status ~= 0
        error('methodsApply1:PythonFailed', ...
            '%s failed with exit code %d.\nCommand:\n%s\nOutput:\n%s', ...
            methodName, status, command, commandOutput);
    end

    resultFile = fullfile(outputDir, 'result.mat');
    if ~isfile(resultFile)
        error('methodsApply1:MissingPythonResult', ...
            '%s completed but did not create %s', methodName, resultFile);
    end
    loadedResult = load(resultFile, 'result');
    if ~isfield(loadedResult, 'result') || ~isnumeric(loadedResult.result) ...
            || isempty(loadedResult.result) || any(~isfinite(loadedResult.result(:)))
        error('methodsApply1:InvalidPythonResult', ...
            '%s produced an invalid result variable in %s', methodName, resultFile);
    end
    result = loadedResult.result;
    fprintf('%s completed: %s\n', methodName, resultFile);
end


function quoted = shellQuote(value)
%SHELLQUOTE Quote a trusted argument for the Linux shell.
    value = char(value);
    if contains(value, '''') || contains(value, newline) || contains(value, sprintf('\r'))
        error('methodsApply1:UnsupportedPath', ...
            'Shell argument contains an unsupported character: %s', value);
    end
    quoted = ['''' value ''''];
end
