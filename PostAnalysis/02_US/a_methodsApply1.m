close all
clear
clc

% ------------parameter--------------
dataName = 'ER';
%------------------------------------

scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
paperRepoRoot = fileparts(postAnalysisRoot);
srcRoot = fullfile(postAnalysisRoot, 'src');
diffusionUsRoot = fullfile(paperRepoRoot, 'DiffusionRestoration', '02_US');
sotaPythonRoot = fullfile(srcRoot, 'SOTApython');
ddrmPython = '/home/mingze/.local/share/miniforge3/envs/ddrm/bin/python';
pythonAvailable = isfile(ddrmPython);
if ~pythonAvailable
    warning('methodsApply1:MissingPython', ...
        ['ddrm Python interpreter not found: %s. Python-based methods ' ...
         'will be skipped. Update ddrmPython near the top of this script.'], ...
        ddrmPython);
end
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end

nPW = '11pw';
zs = 0.01;
observPath = [fullfile(diffusionUsRoot, 'observs', nPW, dataName) filesep];
diffusionResultPath = fullfile(diffusionUsRoot, 'results', nPW, dataName);
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];

load(fullfile(paperRepoRoot, 'mdls', 'Deconv12-exp4x', ...
    'mdlDeconv12-exp4x_fx.mat'))
if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
    mdl_fx.f = 1;
    zs = 0.005;
end

scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');
type = 'Log';
load([observPath 'observ'  type '.mat']);
imgLog(observ, scan, 'observ')

%----------------------- Diffusion 5, 10, 20, -----------------------------
cvrange = 60;
for repeat = [5, 10, 20]
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
    methodName = 'diffmean';
    result = sqrt(meanreal.^2 + meanimag.^2);
    result = 20*log10(result ./ max(result(:)));
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    imgLog(result, scan, methodName)
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    DiffMean = result;
    
    %-- diffvar p
    methodName = ['diffvar', num2str(repeat)];
    result = (varreal + varimag)./2;
    result = 20*log10(result ./ max(result(:)));
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    % --------correct the black hole caused by the ceiling effect.
    % thereshold = 1;
    % correctMap = find(DiffMean-result>thereshold);
    % result(correctMap) = DiffMean(correctMap);
    % ------------------------------------------------------------
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    imgLog(result, scan, methodName)
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    
    %-- diffvar p+
    methodName = ['diffvarPlus', num2str(repeat)];
    result = (varreal + varimag)./2;
    result = 20*log10(result ./ max(result(:)));
    result = result ./ mdl_fx.f; 
    result = (result + cvrange)./cvrange;
    result(result<0) = 0;
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    imgLog(result, scan, methodName)
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
end
%--------------------------------------------------------------

%-- OBNLM 1-5 (optional; excluded from the public repository)
OBNLMpara = [0.1, 0.3, 0.5, 0.7, 1];
obnlmBinary = fullfile(srcRoot, 'OBNLM', ['bnlm2D.' mexext]);
if isfile(obnlmBinary)
    for index = 1:5
        methodName = ['obnlm' num2str(index)];
        M = 7;    % search area size (2*M + 1)^2
        alp = 3;  % patch size (2*alp + 1)^2
        h = OBNLMpara(index);  % smoothing parameter [0-infinite]. to tune
        offset = 100; % avoid division by zero
        s = size(observ);
        imgd = double(observ); % double is necessary; single does not work
        mini = min(imgd(:));
        imgd = imgd - mini;
        maxi = max(imgd(:));
        imgd = (imgd / maxi) * 255;
        imgd = imgd + offset;
        imgd = padarray(imgd, [alp alp], 'symmetric');
        result = bnlm2D(imgd, M, alp, h);
        result = result - offset;
        result = result(alp+1:s(1)+alp, alp+1:s(2)+alp);
        result = result - min(result(:));
        result = result ./ max(result(:));
        imgLog(result, scan, methodName)
        if ~exist([resultPath methodName], 'dir')
            mkdir([resultPath methodName]);
        end
        save([resultPath methodName '/result.mat'], "result", '-mat');
        imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    end
else
    warning('methodsApply1:SkippingOBNLM', ...
        'Skipping OBNLM because its optional binary is unavailable: %s', ...
        obnlmBinary);
end

%-- BLF and ADMSS 1-5
BLFDOSes = [0.001, 0.005, 0.01, 0.05, 0.09];
BLFsigma = [1, 1, 1, 1, 1];
ADMSSpara =[0.01, 0.1, 0.3, 0.6, 1];

for index = 1:5
    methodName = ['blf' num2str(index)];
    result = normalization(imbilatfilt(observ, DegreeOfSmoothing=BLFDOSes(index),spatialSigma = BLFsigma(index))); 
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
    methodName = ['admss' num2str(index)];
    AD_param.sigma=4;
    AD_param.rho=4;
    AD_param.nitmax=31; %31
    AD_param.n_memory=9;
    AD_param.delta_t=ADMSSpara(index);
    AD_param.estim='Gamma';
    mask = ones(scan.Nz, scan.Nx);
    result = normalization(ADMSS_2D(observ,mask,AD_param));
    imgLog(result, scan, methodName)
    if ~exist([resultPath methodName], 'dir')
        mkdir([resultPath methodName]);
    end
    save([resultPath methodName '/result.mat'], "result", '-mat');
    imwrite(result, [resultPath methodName '/pic_' methodName '.png']);
end

%-- speckle2Speckle
methodName = 'speckle2speckle';
speckle2SpeckleRoot = fullfile(sotaPythonRoot, 'Speckle2Speckle');
speckle2SpeckleScript = fullfile(speckle2SpeckleRoot, 'src', 'apply.py');
speckle2SpeckleCheckpoint = fullfile(speckle2SpeckleRoot, 'data', 'network.pt');
if pythonAvailable && isfile(speckle2SpeckleScript) && ...
        isfile(speckle2SpeckleCheckpoint)
    methodResultPath = fullfile(resultPath, methodName);
    if ~exist(methodResultPath, 'dir')
        mkdir(methodResultPath);
    end
    disp('===========================')
    pythonCommand = sprintf('"%s" "%s" --input-data "%s" --output-data "%s" --load-ckpt "%s" --cuda', ...
        ddrmPython, speckle2SpeckleScript, observPath, ...
        [methodResultPath filesep], speckle2SpeckleCheckpoint);
    resultFile = fullfile(methodResultPath, 'result.mat');
    runPythonMethod(pythonCommand, methodName, resultFile);
    result = loadPythonResult(resultFile, methodName);
    imgLog(result, scan, methodName)
    imwrite(result, fullfile(methodResultPath, ['pic_' methodName '.png']));
else
    warning('methodsApply1:SkippingSpeckle2Speckle', ...
        ['Skipping Speckle2Speckle. Check ddrmPython, %s, and the separately ' ...
         'downloaded checkpoint %s.'], ...
        speckle2SpeckleScript, speckle2SpeckleCheckpoint);
end


%-- scunet_color_real_gan
methodName = 'scunet_color_real_gan';  % 'scunet_gray_15', 'scunet_gray_25', 'scunet_gray_50', 
scunetRoot = fullfile(sotaPythonRoot, 'SCUNet-main');
scunetScript = fullfile(scunetRoot, 'scunet_us.py');
scunetCheckpoint = fullfile(scunetRoot, 'model_zoo', [methodName '.pth']);
if pythonAvailable && isfile(scunetScript) && isfile(scunetCheckpoint)
    methodResultPath = fullfile(resultPath, methodName);
    if ~exist(methodResultPath, 'dir')
        mkdir(methodResultPath);
    end
    disp('===========================')
    pythonCommand = sprintf('"%s" "%s" --model_name "%s" --model_zoo "%s" --input_data "%s" --output_data "%s"', ...
        ddrmPython, scunetScript, methodName, ...
        fullfile(scunetRoot, 'model_zoo'), observPath, [methodResultPath filesep]);
    resultFile = fullfile(methodResultPath, 'result.mat');
    runPythonMethod(pythonCommand, methodName, resultFile);
    result = loadPythonResult(resultFile, methodName);
    imgLog(result, scan, methodName)
    imwrite(result, fullfile(methodResultPath, ['pic_' methodName '.png']));
else
    warning('methodsApply1:SkippingSCUNet', ...
        'Skipping SCUNet because its Python environment, script, or checkpoint is missing.');
end


%-- dnnlambda
methodName = 'dnnlambda'; 
dnnLambdaRoot = fullfile(sotaPythonRoot, 'DNN-lambda');
dnnLambdaScript = fullfile(dnnLambdaRoot, 'NN_75_Generate.py');
if pythonAvailable && isfile(dnnLambdaScript)
    methodResultPath = fullfile(resultPath, methodName);
    if ~exist(methodResultPath, 'dir')
        mkdir(methodResultPath);
    end
    disp('===========================')
    pythonCommand = sprintf('"%s" "%s" --input_data "%s" --output_data "%s" --zs %.17g', ...
        ddrmPython, dnnLambdaScript, ...
        [fullfile(observPath, 'DNNinputs') filesep], ...
        [methodResultPath filesep], zs);
    resultFile = fullfile(methodResultPath, 'result.mat');
    runPythonMethod(pythonCommand, methodName, resultFile);
    result = loadPythonResult(resultFile, methodName);
    imgLog(result, scan, methodName)
    imwrite(result, fullfile(methodResultPath, ['pic_' methodName '.png']));
else
    warning('methodsApply1:SkippingDNNLambda', ...
        ['Skipping DNN-lambda because it is an optional dependency that is ' ...
         'not distributed with the public repository.']);
end


function runPythonMethod(command, methodName, resultFile)
%RUNPYTHONMETHOD Run one Python inference and validate its MATLAB output.
fprintf('\n%s: starting Python inference...\n', methodName);
startTime = datetime('now');
[status, commandOutput] = system(command, '-echo');
if status ~= 0
    error('methodsApply1:PythonFailure', ...
        '%s failed with exit code %d.\nCommand: %s\nOutput:\n%s', ...
        methodName, status, command, commandOutput);
end
if ~isfile(resultFile)
    error('methodsApply1:MissingPythonResult', ...
        '%s completed but did not create %s', methodName, resultFile);
end
resultInfo = dir(resultFile);
resultTime = datetime(resultInfo.datenum, 'ConvertFrom', 'datenum');
if resultTime < startTime - seconds(2)
    error('methodsApply1:StalePythonResult', ...
        '%s completed but did not update %s', methodName, resultFile);
end
fprintf('%s: Python inference completed.\n', methodName);
end


function result = loadPythonResult(resultFile, methodName)
%LOADPYTHONRESULT Load and validate a Python-generated restoration image.
contents = load(resultFile, 'result');
if ~isfield(contents, 'result')
    error('methodsApply1:InvalidPythonResult', ...
        '%s output does not contain a variable named result: %s', ...
        methodName, resultFile);
end
result = contents.result;
if ~isnumeric(result) || ~isreal(result) || ...
        ~isequal(size(result), [256, 256]) || any(~isfinite(result(:)))
    error('methodsApply1:InvalidPythonResult', ...
        '%s output must be a finite real 256-by-256 numeric array: %s', ...
        methodName, resultFile);
end
end
