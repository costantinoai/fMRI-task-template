function displayTrial(params, in, image, trial, ~, win, winRect)
% DISPLAYTRIAL Renders a single trial's stimulus.
%
%   Uses preloaded images (loaded during setup). Automatically handles
%   fixation trials.
%
% Inputs:
%   params  - Experiment parameters
%   in      - Session info (gray, colors)
%   image   - Preloaded image struct/matrix
%   trial   - Current trial struct (must have 'stimuli' field)
%   ~       - Unused legacy parameter
%   win     - PTB window pointer
%   winRect - Screen rectangle [x1 y1 x2 y2]
%
% Behavior:
%   - Uses preloaded image (from runImMat)
%   - If stimuli == 'fixation': Display fixation cross instead
%
% Example:
%   displayTrial(params, in, runImMat(i), runTrials(i), 1, win, winRect);
%
% See also: displayFixation, loadImages
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Fill screen with gray background
Screen('FillRect', win, in.gray);

% Extract image matrix from struct or use directly
if ~isempty(image) && isstruct(image) && isfield(image, 'im')
    imStim = image.im;
elseif ~isempty(image)
    imStim = image;
else
    % Check if this is a fixation trial
    if isfield(trial, 'stimuli') && strcmp(trial.stimuli, 'fixation')
        imStim = 'fixation';
    else
        error('DisplayTrial:NoImage', 'No image provided for trial. Images must be preloaded.');
    end
end

% Render fixation or stimulus
if ischar(imStim) && strcmp(imStim, 'fixation')
    displayFixation(win, winRect, params, in);
else
    % Create texture, draw, and immediately close to free memory
    imTexture = Screen('MakeTexture', win, imStim);
    Screen('DrawTexture', win, imTexture);
    Screen('Close', imTexture);
end

% Uncomment the line below if you wish to show the fixation element on top
% of your stimulus
% displayFixation(win, winRect, in);


end
