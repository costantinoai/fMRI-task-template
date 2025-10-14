function [VBL, keyPressed, in, dbg] = showFixationPeriod(win, winRect, params, in, duration, logFile, inputDevs, debugMode, dbg)
% SHOWFIXATIONPERIOD Display fixation, flip, log, and capture input during period
%
%   Consolidates the common pattern of: fill background → display fixation →
%   optional debug overlay → flip → log → wait and capture input.
%
% Inputs:
%   win         - PTB window pointer
%   winRect     - Screen rectangle [x1 y1 x2 y2]
%   params      - Experiment parameters (eventNames, fixation settings)
%   in          - Session info (scriptStart, gray, colors, PPD)
%   duration    - Fixation duration in seconds
%   logFile     - Log file handle
%   inputDevs   - Input queue devices (trigger, response)
%   debugMode   - Enable debug features (logical)
%   dbg         - Debug options (overlay, slowMoFactor)
%
% Outputs:
%   VBL         - Flip timestamp (GetSecs)
%   keyPressed  - Key code if pressed during fixation, else []
%   in          - Updated session info
%   dbg         - Updated debug options (overlay may be toggled)
%
% Example:
%   [VBL, key, in, dbg] = showFixationPeriod(win, winRect, params, in, ...
%       1.5, logFile, inputDevs, false, dbg);
%
% See also: displayFixation, waitAndCaptureInput, logEvent
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Fill background and draw fixation
Screen('FillRect', win, in.gray);
displayFixation(win, winRect, params, in);

% Optional debug overlay
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Fixation (%.2fs)', duration * dbg.slowMoFactor), in);
end

% Flip and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', params.eventNames.fixation, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Wait and capture input during fixation period
[keyPressed, in, dbg] = waitAndCaptureInput(params, in, logFile, duration, inputDevs, debugMode, dbg);

end
