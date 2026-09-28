clear
close all
clc

dataName = 'ER';

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
addpath(scriptDir);

nPW = '11pw';
observPath = [fullfile(diffusionUsRoot, 'observs', nPW, dataName) filesep];
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];
methodNames = {'blf4','obnlm5', 'admss5','speckle2speckle','diffmean','ebmv', 'gcf','dnnlambda','scunet_color_real_gan',  'diffvar20', 'diffvarPlus20'};
methodNamesAnno = {'BLF', 'OBNLM','ADMSS', 'S2S', 'DRUSmean', 'EBMV', 'GCF', 'DNNlbd', 'SCUNet',  '$\mathbf{\widehat p}$ (ours, C=20)', '$\mathbf{\widehat p^+}$ (ours, C=20)'};
% 'speckle2speckle', 'ebmv', 'blf', 
type = 'Log';
load([observPath 'observ'  type '.mat']);
zs = 0.01;
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');


% -- showing the observation (DAS)
h = figure(Position=[82 469 980/4*6 493]);
tiledlayout(2,6, "TileSpacing","none","Padding","none", InnerPosition=[0, 0, 1, 1])
nexttile;
imagesc((scan.x_axis)*1e3,(scan.z_axis)*1e3, observ)
shading flat; colormap gray; caxis([0,1]);  hold on; 
axis equal manual;  axis off

% delineate the evaluation area
path_phantom = fullfile(srcRoot, 'phantoms', 'picmus_phantom_3.hdf5');
phantom = us_phantom();
phantom.read_file(path_phantom);
ROIplot_contrast(scan,phantom)

% Add method name text to the upper-right corner
xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');
text(xlim(2)-1, ylim(1)+0.8, 'noisy (DAS)', 'Color', 'k', 'FontWeight', 'bold', ...
    'FontSize', 16, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'BackgroundColor','yellow', Interpreter='latex', FontName='Times New Roman');
% Add gCNR value to the upper-right corner
load([resultPath, dataName '.mat'], "gCNR");
text(xlim(2)-12, ylim(1)+31, [num2str(gCNR.('observ'), '%.2f')  ' (\textbf{gCNR}$\mathbf{\uparrow)}$'], 'Color', 'k', ...
    'FontSize', 17, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'BackgroundColor','white', Interpreter='latex', FontName='Times New Roman');

% -- showing the result of other algo.
for i = 1: length(methodNames)
    methodName = methodNames{i};
    methodNameAnno = methodNamesAnno{i};
    load([resultPath, methodName '/result.mat']);
    nexttile;
    imagesc((scan.x_axis)*1e3,(scan.z_axis)*1e3,result); 
    shading flat; colormap gray; caxis([0,1]);  hold on; 
    axis equal manual;  axis off
    % Add method name text to the upper-right corner
    xlim = get(gca, 'XLim');
    ylim = get(gca, 'YLim');
    text(xlim(2)-1, ylim(1)+0.8, methodNameAnno, 'Color', 'k', 'FontWeight', 'bold', ...
        'FontSize', 16, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor','yellow', Interpreter='latex', FontName='Times New Roman');
    % Add gCNR value to the upper-right corner
    load([resultPath, dataName '.mat'], "gCNR");
    text(xlim(2)-28, ylim(1)+31, [num2str(gCNR.(methodName), '%.2f')], 'Color', 'k', ...
        'FontSize', 17, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor','white', Interpreter='latex', FontName='Times New Roman');
end


% saveas(gcf, [resultPath, dataName '_picEnsemble.png'], 'png')
% savefig(gcf, [resultPath, dataName '_figEnsemble.fig'])
% set(gcf, 'Color', 'w');
% export_fig([resultPath, dataName '_Ensemble'],"-pdf")

% set(gcf, 'Color', 'w');
% export_fig([resultPath, dataName '_Ensemble_new'],"-pdf")
