function displayTrial(params, in, image, trial, ~, win, winRect)
% DISPLAYTRIAL Renders a single trial's stimulus.
%
%   Supports both preloaded images and lazy loading with intelligent caching.
%   Automatically handles fixation trials and image resizing.
%
% Inputs:
%   params - Experiment parameters (resize, visualUnits, etc.)
%   in     - Session info (gray, PPD, colors)
%   image  - Preloaded image struct/matrix OR [] for lazy loading
%   trial  - Current trial struct (must have 'stimuli' field)
%   ~      - Unused legacy parameter (kept for backward compatibility)
%   win    - PTB window pointer
%   winRect - Screen rectangle [x1 y1 x2 y2]
%
% Behavior:
%   - If image is provided (not empty): Use preloaded image
%   - If image is []: Load on-demand using loadImageOnDemand (with cache)
%   - If stimuli == 'fixation': Display fixation cross instead
%
% Performance:
%   - Preloaded: ~2ms per trial
%   - Lazy (cached): ~2ms per trial
%   - Lazy (cache miss): ~100ms first time per unique image
%
% Example:
%   % Preloaded mode:
%   displayTrial(params, in, runImMat(i), runTrials(i), 1, win, winRect);
%
%   % Lazy loading mode:
%   displayTrial(params, in, [], runTrials(i), 1, win, winRect);
%
% See also: loadImageOnDemand, resizeStim, displayFixation
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Fill screen with gray background
Screen('FillRect', win, in.gray);

% Determine image source
if ~isempty(image) && isstruct(image) && isfield(image, 'im')
    % Preloaded image (struct with 'im' field)
    imStim = image.im;
elseif ~isempty(image) && ~isstruct(image)
    % Preloaded image (direct matrix)
    imStim = image;
else
    % Lazy loading: load on-demand with caching
    stimPath = trial.stimuli;

    if strcmp(stimPath, 'fixation')
        imStim = 'fixation';
    else
        imStim = loadImageOnDemand(stimPath, params, in);
    end
end

% If the trial contains a fixation
if strcmp(imStim, 'fixation')
    % Display a fixation element instead of an image
    displayFixation(win, winRect, params, in);

else
    % Create a texture from the image for rendering
    [imTexture] = Screen('MakeTexture', win, imStim);
    
    % Draw the texture on the screen
    Screen('DrawTexture', win, imTexture);
    % Close the texture to free memory (safe after draw, before flip)
    Screen('Close', imTexture);
end

% Uncomment the line below if you wish to show the fixation element on top
% of your stimulus
% displayFixation(win, winRect, in);


end
