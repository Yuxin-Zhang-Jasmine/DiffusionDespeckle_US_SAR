close all
clear
clc

dataName = 'ER';

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
load([resultPath, dataName '.mat'], "smpi" ,"ssi", "alpha", "gCNR");
methodGroups = {
    '$\widehat\mathbf{p}$ (ours)', {'diffvar5', 'diffvar10', 'diffvar20'};
    '$\mathbf{\widehat p^+}$ (ours)', {'diffvarPlus5','diffvarPlus10','diffvarPlus20'};
    'OBNLM', {'obnlm1', 'obnlm3', 'obnlm5'};
    'BLF', {'blf1', 'blf2', 'blf4'};
    'ADMSS', {'admss1', 'admss3', 'admss5'}
};
picked1 = {'diffvar20','admss5'};
picked2 = {'diffvarPlus20','obnlm5', 'blf4'};

otherMethods = {'dnnlambda', 'gcf', 'ebmv', 'diffmean', 'speckle2speckle', 'scunet_color_real_gan'};
otherMethodsAnnos = {'DNNlbd', 'GCF', 'EBMV', 'DRUSmean', 'S2S', 'SCUNet'};
xl = 0; xr = 4; yd = -0.2; yu = 5.3;


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
for i = 7:numTexts
    text(textInfo{i,2}, textInfo{i,3}, textInfo{i,1}, ...
         'FontSize',11, 'Color',textInfo{i,4}, 'BackgroundColor', 'none', ...
         'EdgeColor', 'none', 'FontWeight', 'bold', ...
         'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
    hold on
end
hold off


% Highlight zoomed-in region
hold on;
zoomRegion = [2.86, 3.9]; % Define x-limits for zoomed region
patch([zoomRegion(1), zoomRegion(2), zoomRegion(2), zoomRegion(1)], ...
      [-0.1,  -0.1, 1.26, 1.26],'cyan', 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Highlight zoom region
% Create inset axes
insetAxes = axes('Position', [0.45, 0.5, 0.45, 0.4]); % Adjust position and size
box on;
% Plot the zoomed-in data in the inset
hold on;
scatter(alpha.('observ'),smpi.('observ'), 70, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor);

for groupIdx = 2:size(methodGroups, 1)-1
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
        if sum(strcmp(picked2,methodName))
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
for i = numel(otherMethods)-1:numel(otherMethods)
    methodColor = otherColormap(i, :);
    methodName = otherMethods{i};
    methodNameAnnos = otherMethodsAnnos{i};
    scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
    'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
end

hold off;
xlim([2.86, 3.7])
ylim([-0.1, 1.3])
% xticks([2.86, 3.7])
% yticks([-0.1, 1.3])
grid on;

% Back to the main axes (seem useless, even with it, it's still in the sub-axes)
axes(gca);
hold off;

% Adding the texts
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

% Adding two lines
annotation(h,'line',[0.453333333333333 0.686666666666667],...
    [0.500199040767385 0.314148681055155],'LineStyle','--'); %'LineWidth',1,
annotation(h,'line',[0.904444444444444 0.875555555555555],...
    [0.509791366906474 0.3189448441247],'LineStyle','--');

% Save
% saveas(gcf, [resultPath, dataName '.png'], 'png')
% savefig(gcf, [resultPath, dataName '.fig'])
% set(gcf, 'Color', 'w');
% export_fig([resultPath, dataName],"-pdf")
