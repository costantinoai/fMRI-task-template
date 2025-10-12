function drawDebugOverlay(win, text, in)
% DRAWDEBUGOVERLAY Draw debug overlay text in top-left corner.
%
%   Draws small debug text overlay for development/testing. Only draws
%   if text is provided (pass empty string to skip).
%
% Inputs:
%   win  - PTB window pointer
%   text - Text to display (empty string = no overlay)
%   in   - Session info (must include 'black' field for text color)
%
% Example:
%   drawDebugOverlay(win, sprintf('Trial %d | %s', i, stimName), in);
%   drawDebugOverlay(win, '', in);  % No overlay
%
% Author: fMRI Task Template Team
% Last updated: 2025

if isempty(text)
    return;
end

Screen('TextSize', win, 16);
DrawFormattedText(win, text, 15, 15, in.black);

end
