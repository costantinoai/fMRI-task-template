function [VBL, in] = showInstructions(win, params, in, logFile, respInst1, respInst2, inputDevs, dbg)
% SHOWINSTRUCTIONS Display instructions, flip, log, and wait for key press.
%
%   Complete orchestrator for instruction phase: draws text with response
%   mappings, adds debug overlay, flips to screen, logs event, and waits
%   for participant to press any key to continue.
%
% Inputs:
%   win       - PTB window pointer
%   params    - Must include: instructionsText* fields, textSize, textFont
%   in        - Session info (black, subNum, runNum, scriptStart)
%   logFile   - Log file handle
%   respInst1 - First response instruction label (e.g., 'left/green')
%   respInst2 - Second response instruction label (e.g., 'right/red')
%   inputDevs - Input queue devices (trigger, response)
%   dbg       - Debug options (overlay, slowMoFactor)
%
% Outputs:
%   VBL - VBL timestamp of instruction screen flip
%   in  - Updated session info
%
% Example:
%   [VBL, in] = showInstructions(win, params, in, logFile, 'left', 'right', inputDevs, dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2025

%% Validate inputs
% Check if the required fields are present in the 'params' structure
requiredFields = {'textSize', 'textFont', 'instructionsText1'};
missingFields = setdiff(requiredFields, fieldnames(params));
if ~isempty(missingFields)
    error('displayInstructions:paramsMissing', 'Required field(s) %s missing in the params structure.', strjoin(missingFields, ', '));
end

% Check if the required fields are present in the 'in' structure
requiredFields = {'black'};
missingFields = setdiff(requiredFields, fieldnames(in));
if ~isempty(missingFields)
    error('displayInstructions:paramsMissing', 'Required field(s) %s missing in the in structure.', strjoin(missingFields, ', '));
end

%% Extract and merge instruction text
% Configure text size and font parameters
Screen('TextSize', win, params.textSize);
Screen('TextFont', win, params.textFont);

% Get field names of params structure
paramFieldnames = fieldnames(params);

% Initialize cell array to store fields containing 'instructions'
instructionTexts = {};

% Iterate through each field name to find instruction text fields
for i = 1:numel(paramFieldnames)
    fieldName = paramFieldnames{i};
    if contains(fieldName, 'instructionsText')
        instructionTexts{end+1} = params.(fieldName);
    end
end

% Merge the instruction sentences into a single paragraph
instructionParagraph = '';
for i = 1:numel(instructionTexts)
    instructionParagraph = [instructionParagraph instructionTexts{i} '\n\n'];
end

%% Replace placeholders with response instructions
% Find the occurrences of the placeholder '()'
idx = strfind(instructionParagraph, '()');

% Enforce exactly two placeholders for clarity and consistency
if numel(idx) ~= 2
    error('Instructions:PlaceholderCount', ['Instructions must contain exactly two placeholders ''()'' ', ...
        'to label the left/right responses. Edit your instructionsText* fields in src/config.m.']);
end

% Make an array of response instructions to index from
respInst = {respInst1, respInst2};

% Loop through the place holder positions and replace them
for i = 1:numel(idx)
    % Convert the cell content to a string
    respStr = char(respInst{i});

    % Replace the placeholder with the corresponding value from respStr
    instructionParagraph = [instructionParagraph(1:idx(i)-1), respStr, instructionParagraph(idx(i)+2:end)];

    % Update the next index in case the paragraph changed size
    idx(i+1:end) = strfind(instructionParagraph, '()');
end

%% Draw instructions
% Draw the instruction paragraph in black, centered on the screen
DrawFormattedText(win, instructionParagraph, 'center', 'center', in.black);

% Add debug overlay if enabled
if isfield(dbg, 'overlay') && dbg.overlay
    overlayText = sprintf('DEBUG: Instructions | sub-%02d run-%02d', in.subNum, in.runNum);
    Screen('TextSize', win, 16);
    DrawFormattedText(win, overlayText, 15, 15, in.black);
end

% Flip and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', 'Instr', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Wait for any key press to continue
conditionFunc = @(x) true; % Accept any key
[~, in] = logKeyPressDual(params, in, logFile, false, true, conditionFunc, inputDevs);

% Handle debug overlay toggle (if user pressed special key)
if isfield(in, 'toggleOverlay') && in.toggleOverlay
    if isfield(dbg, 'overlay')
        dbg.overlay = ~dbg.overlay;
    else
        dbg.overlay = true;
    end
    in = rmfield(in, 'toggleOverlay');
end

end
