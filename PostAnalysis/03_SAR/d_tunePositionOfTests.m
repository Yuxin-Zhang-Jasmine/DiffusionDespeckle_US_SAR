%% tune the position of the texts and run this script to save these Positions

% Find all text objects in the figure
textHandles = findobj(gcf, 'Type', 'text');

% Initialize a cell array to store positions and strings
numTexts = numel(textHandles);
textInfo = cell(numTexts, 4); % Columns: [Text String, X, Y, Z]

% Loop through each text object and extract its properties
for i = 1:numTexts
    textObj = textHandles(i);
    textInfo{i, 1} = textObj.String;          % Text string
    textInfo{i, 2} = textObj.Position(1);     % X coordinate
    textInfo{i, 3} = textObj.Position(2);     % Y coordinate
    textInfo{i, 4} = textObj.Color;           % color
end
save([resultPath, dataName '_texts.mat'], 'textInfo')
