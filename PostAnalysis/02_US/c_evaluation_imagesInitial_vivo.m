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
picked1 = {};%'diffvar20','admss5'};
picked2 = {};%'diffvarPlus20','obnlm5', 'blf4'};
% methodGroups = {
%     '$\widehat\mathbf{p}$ (ours)', {'diffvar5', 'diffvar10', 'diffvar20'};
%     '$\mathbf{\widehat p^+}$ (ours)', {'diffvarPlus5','diffvarPlus10','diffvarPlus20'};
%     'OBNLM', {'obnlm1', 'obnlm3', 'obnlm5'};
%     'BLF', {'blf1', 'blf2', 'blf4'};
%     'ADMSS', {'admss1', 'admss3', 'admss5'}
% };
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


figure(Position=[97 487 330, 350]);
observColor = [0.5, 0.5, 0.5];
ax = gca;
axisPos = get(ax, 'Position');
scatterHandle = scatter(alpha.('observ'),smpi.('observ'), 70, "filled", MarkerFaceColor=observColor, MarkerEdgeColor=observColor); % 500*(gCNR.('observ')).^15
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
        scatter(alpha.(methodName), smpi.(methodName), 70, "filled", ...  %500*(gCNR.(methodName)).^10
        'MarkerFaceColor', groupColor, 'MarkerFaceAlpha', alpha_vals(methodIdx));
        if sum(strcmp(picked1,methodName))
            scatter(alpha.(methodName), smpi.(methodName), 250, 'LineWidth', 2, ...
            'MarkerFaceColor', 'none', 'MarkerEdgeColor', groupColor);
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
    scatter(alpha.(methodName), smpi.(methodName), 70, 'filled', ...
    'MarkerFaceColor',methodColor, 'MarkerFaceAlpha', 1);
    xCoord = alpha.(methodName);
    yCoord = smpi.(methodName);
    text(xCoord, yCoord, methodNameAnnos,'FontSize',11,'Color',methodColor, ...
        'BackgroundColor','none','EdgeColor', 'none', 'FontWeight', 'bold', ...
        'Interpreter', 'latex', 'FontName', 'Times New Roman'); %FontWeight='bold'
end

hold off;
xlabel('Resolution (\xi)'); ylabel('SMPI');
xlim([xl, xr]); ylim([yd, yu]);
