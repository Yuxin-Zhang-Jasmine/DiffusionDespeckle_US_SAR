close all
clear
clc

dataName = 'long';

scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
srcRoot = fullfile(postAnalysisRoot, 'src');
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end

nPW = '11pw';
resultPath = [fullfile(scriptDir, 'results', nPW, dataName) filesep];
load([resultPath, dataName '.mat'], "smpi" ,"ssi", "alpha");
methodGroups = {};
picked1 = {};
picked2 = {};
switch dataName
    case 'long'
        xl = 0; xr = 2.3; yd = 0; yu = 4.5;
    case 'cross'
        xl = 0; xr = 3.5; yd = 0; yu = 6.7;
end
otherMethods = {'diffvar20','diffvarPlus20','obnlm4', 'blf4', 'admss5', ...
    'dnnlambda', 'gcf', 'ebmv', 'diffmean', 'speckle2speckle', 'scunet_color_real_gan'};
otherMethodsAnnos = {'$\widehat\mathbf{p}$ (ours)', '$\mathbf{\widehat p^+}$ (ours)', ...
    'OBNLM', 'BLF','ADMSS','DNNlbd', 'GCF', 'EBMV', 'DRUSmean', 'S2S', 'SCUNet'};


h = figure(Position=[97 487 350 350]);
observColor = [0.5, 0.5, 0.5];
ax = gca;
axisPos = get(ax, 'Position');
scatterHandle = scatter(alpha.('observ'),smpi.('observ'), 70, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor); % 500*(gCNR.('observ')).^15
xlim([xl, xr]); ylim([yd, yu]); 

hold on
alpha_vals = linspace(0.3, 1, 3); % Transparency gradient
cmap = lines(size(methodGroups, 1) + size(otherMethods,2));

% Plot scatterers for grouped methods
for groupIdx = 1:size(methodGroups, 1)
    groupName = methodGroups{groupIdx, 1};
    groupMethods = methodGroups{groupIdx, 2};
    groupColor = cmap(groupIdx, :);

    % Gather coordinates for the group
    xGroup = [];
    yGroup = [];
    for methodIdx = 1:numel(groupMethods)
        methodName = groupMethods{methodIdx};
        scatter(alpha.(methodName), smpi.(methodName), 70, "filled", ...  %500*(gCNR.(methodName)).^10
        'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        if sum(strcmp(picked1,methodName))
            scatter(alpha.(methodName), smpi.(methodName), 250, 'LineWidth', 2, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', groupColor);
        end
        xGroup = [xGroup; alpha.(methodName)];
        yGroup = [yGroup; smpi.(methodName)];
    end

    % Draw a smooth line through the scatterers if there are multiple points
    if numel(xGroup) > 1
        % Sort the points by x-coordinates
        [sortedX, sortIdx] = sort(xGroup);
        sortedY = yGroup(sortIdx);
    
        % Handle duplicate x-values
        [uniqueX, ~, uniqueIdx] = unique(sortedX, 'stable');
        if numel(uniqueX) < numel(sortedX)
            % Average y-values for duplicate x-values
            averagedY = accumarray(uniqueIdx, sortedY, [], @mean);
            sortedX = uniqueX;
            sortedY = averagedY;
        end
        % Smooth line interpolation
        if numel(sortedX) > 1
            smoothX = linspace(min(sortedX), max(sortedX), 100);
            smoothY = interp1(sortedX, sortedY, smoothX, 'pchip');
            plot(smoothX, smoothY, '-', 'Color', groupColor, 'LineWidth', 1.5);
        end
    end
end

% Define a colormap for the other methods
otherColormap = cmap(size(methodGroups, 1)+1:end,:); % Generates a unique color for each method
for i = 1:numel(otherMethods)
    methodColor = otherColormap(i, :);
    methodName = otherMethods{i};
    methodNameAnnos = otherMethodsAnnos{i};
    scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
    'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
end

hold off;
xlabel('$\xi$ (Resolution) $\downarrow$', Interpreter='latex', FontSize=13);
ylabel('SMPI (Smoothness) $\downarrow$', Interpreter='latex', FontSize=13);
%grid on; title(dataName, Interpreter='latex', FontSize=13);

% Adding the texts
xlim([xl, xr]); ylim([yd, yu]);
load([resultPath, dataName '_texts.mat'], 'textInfo')
[numTexts, ~] = size(textInfo);
for i = 1:numTexts
    text(textInfo{i,2}, textInfo{i,3}, textInfo{i,1}, ...
         'FontSize',11, 'Color',textInfo{i,4}, 'BackgroundColor', 'none', ...
         'EdgeColor', 'none', 'FontWeight', 'bold', ...
         'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
    hold on
end
hold off


% Save
saveas(gcf, [resultPath, dataName '.png'], 'png')
savefig(gcf, [resultPath, dataName '.fig'])
set(gcf, 'Color', 'w');
export_fig([resultPath, dataName],"-pdf")
