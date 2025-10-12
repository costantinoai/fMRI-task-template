function [keyPressed, in, dbg] = waitAndCaptureInput(params, in, logFile, durationSec, inputDevs, debugMode, dbg)
% WAITANDCAPTUREINPUT Wait for duration while capturing and logging all input.
%
%   Polls input queues for specified duration, logs all key presses,
%   and handles debug overlay toggle. This is the standard pattern for
%   fixation periods and post-stimulus delays.
%
% Inputs:
%   params      - Experiment parameters (for key code mapping)
%   in          - Session info (updated with key press data)
%   logFile     - Log file handle
%   durationSec - How long to wait (seconds, affected by slowMoFactor)
%   inputDevs   - Input queue devices (trigger, response)
%   debugMode   - If true, enable overlay toggle on special key
%   dbg         - Debug options (slowMoFactor, overlay)
%
% Outputs:
%   keyPressed - True if any key was pressed during wait
%   in         - Updated session info
%   dbg        - Updated debug options (overlay may be toggled)
%
% Example:
%   % Wait for fixation duration and log all key presses
%   [~, in, dbg] = waitAndCaptureInput(params, in, logFile, params.fixDur, inputDevs, debugMode, dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Record start time for this wait period
waitStart = GetSecs();

% Apply slow-mo factor for debugging (allows slowing down task)
adjustedDuration = durationSec * dbg.slowMoFactor;

% Anonymous function: keep waiting while duration hasn't elapsed
conditionFunc = @(x) (GetSecs - waitStart) <= adjustedDuration;

% Wait and log all key presses during this period
[keyPressed, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

% Handle debug overlay toggle (special key pressed during wait)
if debugMode && isfield(in, 'toggleOverlay') && in.toggleOverlay
    dbg.overlay = ~dbg.overlay;
    in = rmfield(in, 'toggleOverlay');
end

end
