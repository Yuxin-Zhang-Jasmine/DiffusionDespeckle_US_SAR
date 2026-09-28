clear
close all
clc

dataName = 'cross';

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
observPath = [fullfile(diffusionUsRoot, 'observs', nPW, dataName) filesep];
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];

methodNames = {'blf4', 'obnlm4', 'admss5', 'scunet_color_real_gan', 'gcf', 'dnnlambda', 'diffmean', 'diffvarPlus20'};
methodNamesAnno = {'BLF', 'OBNLM','ADMSS', 'SCUNet', 'GCF', 'DNNlbd', 'DRUSmean', '$\mathbf{\widehat p^+}$ (ours, C=20)'};

type = 'Log';
load([observPath 'observ'  type '.mat']);
zs = 0.005;
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');


% -- showing the observation (DAS)
h = figure(Position=[85 694 1800 215]);
tiledlayout(1, 9, "TileSpacing","none","Padding","none", InnerPosition=[0, 0, 1, 1])
nexttile;
imagesc((scan.x_axis)*1e3,(scan.z_axis)*1e3, observ)
shading flat; colormap gray; caxis([0,1]);  hold on; 
axis equal manual;  axis off

% Add method name text to the upper-right corner
xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');
text(xlim(2)-1, ylim(1)-1.2, 'noisy (DAS)', 'Color', 'k', 'FontWeight', 'bold', ...
    'FontSize', 15, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'BackgroundColor','yellow', Interpreter='latex', FontName='Times New Roman');

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
    text(xlim(2)-1, ylim(1)-1.2, methodNameAnno, 'Color', 'k', 'FontWeight', 'bold', ...
        'FontSize', 15, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor','yellow', Interpreter='latex', FontName='Times New Roman');
end


saveas(gcf, [resultPath, dataName '_picEnsemble.png'], 'png')
savefig(gcf, [resultPath, dataName '_figEnsemble.fig'])
set(gcf, 'Color', 'w');
export_fig([resultPath, dataName '_Ensemble'],"-pdf")
