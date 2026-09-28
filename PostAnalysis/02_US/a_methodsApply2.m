%% Beamforming with the USTB toolbox
scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
srcRoot = fullfile(postAnalysisRoot, 'src');
ustbRoot = fullfile(srcRoot, 'USTB-master');
if ~isfolder(ustbRoot)
    error('USTB root not found: %s', ustbRoot);
end
% USTB requires its repository root on the MATLAB path. Adding the
% whole tree with genpath can shadow the project's own +tools package.
addpath(ustbRoot, '-begin');

% Data location. Missing datasets are downloaded to dataPath.
url = tools.zenodo_dataset_files_base();

% ------------parameter--------------
dataName = 'ER';  % cross | long | EC | SC | ER
%------------------------------------
if strcmp(dataName, 'EC')
    filename='PICMUS_experiment_contrast_speckle.uff'; 
    zs = 0.01; tgcFactor = 6;
elseif strcmp(dataName, 'SC')
    filename='PICMUS_simulation_contrast_speckle.uff'; 
    zs = 0.01; tgcFactor = 4;
elseif strcmp(dataName, 'ER')
    filename='PICMUS_experiment_resolution_distortion.uff'; 
    zs = 0.01; tgcFactor = 6;
else
    filename=['PICMUS_carotid_' dataName '.uff'];     
    zs = 0.005; tgcFactor = 0;
end

nPW = '11pw';
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];

% checks if the data is in your data path, and downloads it otherwise.
% The defaults data path is under USTB's folder, but you can change this
% by setting an environment variable with setenv('DATA_PATH','your_path').
dataPath = data_path();
uffFile = fullfile(dataPath, filename);
tools.download(filename, url, dataPath);
display=true;
content = uff.index(uffFile, '/', display);

b_data=uff.read_object(uffFile, '/beamformed_data');
b_data.plot();

channel_data=uff.read_object(uffFile, '/channel_data');
scan=uff.read_object(uffFile, '/scan');

% Set up processing pipeline / Delay the channel data
pw_indices = round(linspace(1,75,11));
scan.x_axis = linspace(-0.018,0.018,256).';
scan.z_axis = linspace(zs,0.036+zs,256).';
dataset_pw = uff.channel_data();
dataset_pw.sampling_frequency = channel_data.sampling_frequency;
dataset_pw.initial_time = channel_data.initial_time;
dataset_pw.sound_speed = channel_data.sound_speed;
dataset_pw.modulation_frequency = channel_data.modulation_frequency;
dataset_pw.sequence = channel_data.sequence(1,pw_indices);      
dataset_pw.probe = channel_data.probe;
dataset_pw.data = channel_data.data(:,:,pw_indices);          
dataset_pw.PRF = channel_data.PRF;
dataset_pw.N_active_elements = channel_data.N_active_elements;
dataset_pw.name = channel_data.name;
dataset_pw.reference = channel_data.reference;
dataset_pw.author = channel_data.author;
dataset_pw.version = channel_data.version;
dataset_pw.info = channel_data.info;

% The PICMUS UFF files used here do not contain pulse metadata. EBMV uses
% the center frequency to convert K_in_lambda into a temporal sample window.
dataset_pw.pulse = uff.pulse();
dataset_pw.pulse.center_frequency = 5.208e6;

% TGC
time_vector = dataset_pw.initial_time+(0:(dataset_pw.N_samples-1))/dataset_pw.sampling_frequency;
tgc = time_vector'./max(time_vector);
tgc = exp(tgcFactor*tgc);            % simu_reso=4.5, simu_cont=expe_reso=expe_cont=4
tgc(1:150*4) = tgc(150*4);   %  RF's fs is four times of the IQ's, so times 4 here
dataset_pw.data = dataset_pw.data .* tgc;

% Delaying
mid=midprocess.das();
% The bundled CPU MEX needs libtbb.so.12, which is not currently available.
% Use USTB's portable MATLAB implementation until that dependency is set up.
mid.code = code.matlab;
mid.dimension = dimension.transmit;
mid.channel_data=dataset_pw;
mid.scan=scan;
mid.transmit_apodization.window=uff.window.none;
mid.receive_apodization.window=uff.window.tukey50;
delayed_data = mid.go();

% DAS
das = postprocess.coherent_compounding();
das.input = delayed_data;
das_image = das.go();
% gCF
gCF_beamformer = postprocess.generalized_coherence_factor();
gCF_beamformer.input = delayed_data;
gcf_image = gCF_beamformer.go();
% PCF
PCF_beamformer = postprocess.phase_coherence_factor();
PCF_beamformer.input = delayed_data;
pcf_image = PCF_beamformer.go();
% EBMV
EBMV_beamformer = postprocess.eigenspace_based_minimum_variance();
EBMV_beamformer.scan = scan;
EBMV_beamformer.channel_data = dataset_pw;
EBMV_beamformer.K_in_lambda = 1.5;                            % temporal averaging window [wavelengths]
EBMV_beamformer.gamma = 0.5;                                  % signal-subspace threshold
EBMV_beamformer.L_elements = floor(dataset_pw.N_elements/2);  % subarray size
EBMV_beamformer.transmit_apodization = mid.transmit_apodization;
EBMV_beamformer.receive_apodization = mid.receive_apodization;
EBMV_beamformer.regCoef = 0.001;                              % regularization factor
EBMV_beamformer.doForwardBackward = 0;                        % forward backward averaging
EBMV_beamformer.dimension = dimension.receive;                % dimension class that specifies whether the process will run only on transmit, receive, or both.
EBMV_beamformer.input = delayed_data;
ebmv_image = EBMV_beamformer.go();

figure;
das_image.plot(subplot(1,4,1),'das');
gcf_image.plot(subplot(1,4,2),'gcf');
pcf_image.plot(subplot(1,4,3),'pcf');
ebmv_image.plot(subplot(1,4,4),'ebmv');
set(gcf,'Position',[100   100   1800   420])


for methodName = {'gcf', 'pcf', 'ebmv'}
    methodName = methodName{1};
    result = abs(eval([methodName, '_image.data']));
    result = 20*log10(result ./ max(result));
    result = (result + 60) ./ 60;
    result(result<0) = 0;
    result = reshape(result, 256,256);
    methodResultPath = fullfile(resultPath, methodName);
    if ~exist(methodResultPath, 'dir')
        mkdir(methodResultPath);
    end
    save(fullfile(methodResultPath, 'result.mat'), "result", '-mat');
    imwrite(result, fullfile(methodResultPath, ['pic_' methodName '.png']));
end
