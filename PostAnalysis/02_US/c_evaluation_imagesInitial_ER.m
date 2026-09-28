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
otherMethods = {'dnnlambda', 'gcf', 'ebmv', 'diffmean', 'speckle2speckle', 'scunet_color_real_gan'};
otherMethodsAnnos = {'DNNlbd', 'GCF', 'EBMV', 'DRUSmean', 'S2S', 'SCUNet'};
switch dataName
    case 'long'
        xl = 0; xr = 2.3; yd = 0; yu = 4.5;
    case 'cross'
        xl = 0; xr = 3.5; yd = 0; yu = 6.7;
    case 'EC'
        xl = -0.1; xr = 4; yd = -0.4; yu = 4;
    case 'SC'
        xl = 0; xr = 1.65; yd = 0; yu = 5;
    case 'ER'
        xl = 0; xr = 4; yd = -0.4; yu = 5.3;
end

figure(Position=[97 487 450 417]);
observColor = [0.5, 0.5, 0.5];
ax = gca;
axisPos = get(ax, 'Position');
if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
    scatterHandle = scatter(alpha.('observ'),smpi.('observ'), 70, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor);
else    
    scatterHandle = scatter(alpha.('observ'),smpi.('observ'), 70, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor); % 500*(gCNR.('observ')).^15
end
xlim([xl, xr]); ylim([yd, yu]); 
xCoord = alpha.('observ');
yCoord = smpi.('observ');
text(xCoord, yCoord, 'noisy (DAS)', 'FontSize', 11, 'Color', observColor, ...
    'BackgroundColor', 'none', 'EdgeColor', 'none', 'FontWeight', 'bold', ...
    'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'


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
        if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
            scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
            'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        else
            scatter(alpha.(methodName), smpi.(methodName), 70, "filled", ...  %500*(gCNR.(methodName)).^10
            'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        end
        xGroup = [xGroup; alpha.(methodName)];
        yGroup = [yGroup; smpi.(methodName)];
    end
    xCoord = alpha.(methodName);
    yCoord = smpi.(methodName);
    text(xCoord, yCoord, groupName,'FontSize',11,'Color',groupColor, ...
        'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
        'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'

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
    if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
        scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
        'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
    else
        scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
        'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
    end
    xCoord = alpha.(methodName);
    yCoord = smpi.(methodName);
    text(xCoord, yCoord, methodNameAnnos,'FontSize',11,'Color',methodColor, ...
        'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
        'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
end

hold off;
xlabel('Resolution (\xi)'); ylabel('SMPI');
xlim([xl, xr]); ylim([yd, yu]);

% for i = 1:length(methodNames)
%     methodName = methodNames{i};
%     methodNameAnno = methodNamesAnno{i};
%         scatterHandle = scatter(alpha.(methodName), smpi.(methodName), 100, "filled");
%     else 
%         scatterHandle = scatter(alpha.(methodName), smpi.(methodName), ...
%         500*(gCNR.(methodName)).^10, "filled");
%     end
%     scatterColor = scatterHandle.CData; % Extracts the color used for this scatter point
%     xlim([xl, xr]); ylim([yd, yu]); 
%     xCoord = alpha.(methodName);
%     yCoord = smpi.(methodName);
%     text(xCoord, yCoord, methodNameAnno,'FontSize',11,'Color',scatterColor, ...
%         'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
%         'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
%     hold on
% end
% hold off
% xlabel('Resolution(\alpha)'); ylabel('SMPI'); 
%title(dataName)

% Highlight zoomed-in region
hold on;
zoomRegion = [2.86, 3.9]; % Define x-limits for zoomed region
patch([zoomRegion(1), zoomRegion(2), zoomRegion(2), zoomRegion(1)], ...
      [-0.2,  -0.2, 1.26, 1.26],'cyan', 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Highlight zoom region
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
        if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
            scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
            'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        else
            scatter(alpha.(methodName), smpi.(methodName), 70, "filled", ...  %500*(gCNR.(methodName)).^10
            'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        end
        xGroup = [xGroup; alpha.(methodName)];
        yGroup = [yGroup; smpi.(methodName)];
    end
    xCoord = alpha.(methodName);
    yCoord = smpi.(methodName);
    text(xCoord, yCoord, groupName,'FontSize',11,'Color',groupColor, ...
        'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
        'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'

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
    if strcmp(dataName, 'long') || strcmp(dataName, 'cross')
        scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
        'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
    else
        scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
        'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
    end
    xCoord = alpha.(methodName);
    yCoord = smpi.(methodName);
    text(xCoord, yCoord, methodNameAnnos,'FontSize',11,'Color',methodColor, ...
        'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
        'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
end

hold off;
xlim([2.86, 3.7])
ylim([-0.1, 1.3])
% xticks([2.86, 3.7])
% yticks([-0.1, 1.3])
% xticks([2.05, 2.1]);   % X-axis ticks
% yticks([0.18, 0.23]); % Y-axis ticks
grid on;

% Back to the main axes
axes(gca);
hold off;

