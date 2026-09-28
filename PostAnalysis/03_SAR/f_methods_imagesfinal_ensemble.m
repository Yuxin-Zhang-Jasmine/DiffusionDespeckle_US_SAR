clear
close all
clc

dataName = '14'; 

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
methodNames = {'nlm1','blf2','srad1','fans','scunet_color_real_gan','merlin', 'diffvar5','diffvar200','diffvarPlus200'};
methodNamesAnno = {'NLM','BLF','SRAD','FANS','SCUNet','MERLIN', '$\widehat\mathbf{p}$ (ours,  C=5)', '$\mathbf{\widehat p}$ (ours, C=200)','$\mathbf{\widehat p^+}$ (ours, C=200)'};
% 'nlm1','nlm2','nlm4','blf1','blf2','blf4',
type = 'Log';
load([observPath 'observ'  type '.mat']);
zs = 0.01;
scan = linear_scan(linspace(-0.018,0.018,256).', linspace(zs,0.036+zs,256).');


% -- showing the observation
h = figure(Position=[82 469 980/4*4.7 470]);
tiledlayout(2,5, "TileSpacing","none","Padding","none")
nexttile;
imagesc((scan.x_axis)*1e3,(scan.z_axis)*1e3, observ)
shading flat; colormap gray; caxis([0,1]);  hold on; 
axis equal manual;  axis off

% Add method name text to the upper-right corner
xlim = get(gca, 'XLim');
ylim = get(gca, 'YLim');
text(xlim(2)-1, ylim(1)+0.8, 'noisy', 'Color', 'k', 'FontWeight', 'bold', ...
    'FontSize', 12, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
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
    text(xlim(2)-1, ylim(1)+0.8, methodNameAnno, 'Color', 'k', 'FontWeight', 'bold', ...
        'FontSize', 12, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor','yellow', Interpreter='latex', FontName='Times New Roman');

    if strcmp(dataName, '388')
        if sum(i == [7, 8, 9])
        text(xlim(2)-30, ylim(1)+28, 'land', 'Color', 'red', 'FontWeight', 'bold', ...
        'FontSize', 14, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
        'BackgroundColor','none');

        text(xlim(2)-8, ylim(1)+33, 'sea', 'Color', 'red', 'FontWeight', 'bold', ...
        'FontSize', 14, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
        'BackgroundColor','none');

        end
    end
end

saveas(gcf, [resultPath, dataName '_picEnsemble.png'], 'png')
savefig(gcf, [resultPath, dataName '_figEnsemble.fig'])
set(gcf, 'Color', 'w');
export_fig([resultPath, dataName '_Ensemble'],"-pdf")
