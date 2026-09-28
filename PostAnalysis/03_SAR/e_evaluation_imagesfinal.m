close all
clear
clc

% ------------parameter--------------
dataName = '14';   %[11, 12, 14, 50, 388]
%------------------------------------
scriptDir = fileparts(mfilename('fullpath'));
postAnalysisRoot = fileparts(scriptDir);
srcRoot = fullfile(postAnalysisRoot, 'src');
addpath(genpath(srcRoot));
ustbRoot = fullfile(srcRoot, 'USTB-master');
if isfolder(ustbRoot)
    rmpath(genpath(ustbRoot));
end

sarmode = 'spotlight';
resultPath = [fullfile(scriptDir, 'results', sarmode, dataName) filesep];
load([resultPath, dataName '.mat'], "smpi", "ssi", "alpha");

% Method Names and Annotations
methodGroups = {
    '$\widehat\mathbf{p}$ (ours)', {'diffvar5', 'diffvar10', 'diffvar20', 'diffvar50', 'diffvar200'};
    '$\mathbf{\widehat p^+}$ (ours)', {'diffvarPlus5','diffvarPlus10','diffvarPlus20','diffvarPlus50','diffvarPlus200'};
    'NLM', {'nlm1', 'nlm2', 'nlm3', 'nlm4', 'nlm5'};
    'BLF', {'blf1', 'blf2', 'blf3', 'blf4', 'blf5'};
    'SRAD', {'srad1', 'srad2', 'srad3', 'srad4', 'srad5'};
};
picked = {'nlm1','blf2','srad1', 'diffvar5','diffvar200','diffvarPlus200'};

otherMethods = {'fans', 'scunet_color_real_gan', 'merlin'};
switch dataName
    case '50'
        xl = 0; xr = 2.6; yd = 0; yu = 2.2;
    case '388'
        xl = 0; xr = 1.3; yd = 0; yu = 4;
    case '11'
        xl = -0.15; xr = 0.9; yd = 0; yu = 5.8;
    case '12'
        xl = -0.05; xr = 0.51; yd = 0; yu = 8.5;
    case '14'
        xl = -0.05; xr = 1.27; yd = 0; yu = 3.55;
end

cmap = lines(size(methodGroups, 1) + size(otherMethods,2));


h = figure(Position=[97 487 380 380+30]);
observColor = [0.5, 0.5, 0.5];
ax = gca;
axisPos = get(ax, 'Position');
scatterHandle = scatter(alpha.('observ'),smpi.('observ'), 100, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor);
xlim([xl, xr]); ylim([yd, yu]); 
hold on

alpha_vals = linspace(0.3, 1, 5); % Transparency gradient

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
        scatter(alpha.(methodName), smpi.(methodName), 100, 'filled', ...
            'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        if sum(strcmp(picked,methodName))
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
    scatter(alpha.(methodName), smpi.(methodName), 100, 'filled', ...
        'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
end


hold off;
xlabel('$\xi$ (Resolution) $\downarrow$', Interpreter='latex', FontSize=13);
ylabel('SMPI (Smoothness) $\downarrow$', Interpreter='latex', FontSize=13);
xlim([xl, xr]); ylim([yd, yu]);

load([resultPath, dataName '_texts.mat'], 'textInfo')
[numTexts, ~] = size(textInfo);
for i = 1:numTexts
    text(textInfo{i,2}, textInfo{i,3}, textInfo{i,1}, ...
         'FontSize',11, 'Color',textInfo{i,4}, 'BackgroundColor', 'none', ...
         'EdgeColor', 'none', 'FontWeight', 'bold', ...
         'Interpreter', 'latex', 'FontName', 'Times New Roman'); 
    hold on
end
hold off


saveas(gcf, [resultPath, dataName '.png'], 'png')
savefig(gcf, [resultPath, dataName '.fig'])
set(gcf, 'Color', 'w');
export_fig([resultPath, dataName],"-pdf")
