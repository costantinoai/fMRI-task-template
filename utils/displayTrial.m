function displayTrial(params, in, runImMat, runTrials, i, win, winRect)
% DISPLAYTRIAL Renders the visual events of a prototypical trial
%
%   displayTrial(runImMat, i, win, in, logFile) contains the elements of 
%   any given trial in your experiment. Adjust the content of this script 
%   as you need it. 
%
%   INPUTS:
%       runImMat: A structure containing trial images.
%       i: Index indicating the current trial.
%       win: Screen window handle for displaying stimuli.
%       in: Structure containing parameters for display.
%
%   OUTPUT:
%       None
%
%   TYPICAL STRUCTURE:
%       - Fills the screen with gray to reset the background.
%       - Retrieves the image for the current trial from the preloaded image matrix.
%       - If the trial contains a fixation, shows a fixation element
%       - Otherwise creates a texture from the image for rendering.
% 
%   Author
%   Tim Maniquet [27/3/24]


% Fill the screen with gray to reset the background
Screen('FillRect', win, in.gray);

% If preloaded, retrieve the image for the current trial
if ~isempty(runImMat)
    imStim = runImMat(i).im;
else
    % On-demand: determine from trial definition
    file = runTrials(i).stimuli;
    if strcmp(file,'fixation')
        imStim = 'fixation';
    else
        imStim = imread(file);
        if params.resize == true
            imStim = resizeStim(imStim, params);
        end
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
