function [VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg)
% WAITFORTRIGGER Display trigger wait screen and wait for scanner trigger(s).
%
%   Handles different trigger policies: 'single', 'double', 'window'.
%   Automatically includes debug overlay if dbg.overlay is true.
%
% Inputs:
%   win       - PTB window pointer
%   params    - Must include: triggerWaitText, triggerPolicy (optional), triggerWindowMs (optional)
%   in        - Session info (must include: black, subNum, runNum, scriptStart)
%   logFile   - Log file handle
%   inputDevs - Input queue devices (trigger, response)
%   dbg       - Debug options (overlay, slowMoFactor)
%
% Outputs:
%   VBL - VBL timestamp of trigger wait screen flip
%   in  - Updated session info
%
% Trigger policies:
%   'single' - Wait for one trigger
%   'double' - Wait for two triggers (default, common for MRI scanners)
%   'window' - Wait for any trigger within triggerWindowMs after first trigger
%
% Example:
%   [VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2024

% Draw trigger wait message
DrawFormattedText(win, params.triggerWaitText, 'center', 'center', in.black);

% Add debug overlay if enabled
if isfield(dbg, 'overlay') && dbg.overlay
    overlayText = sprintf('DEBUG: Waiting trigger | sub-%02d run-%02d', in.subNum, in.runNum);
    Screen('TextSize', win, 16);
    DrawFormattedText(win, overlayText, 15, 15, in.black);
end

% Flip and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', 'TgrWait', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Condition: always accept trigger
conditionFunc = @(x) true;

% Determine trigger policy
if isfield(params, 'triggerPolicy')
    policy = lower(params.triggerPolicy);
else
    policy = 'double'; % Default
end

% Execute trigger wait based on policy
switch policy
    case 'single'
        % Wait for one trigger
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);

    case 'window'
        % First trigger
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);

        % Accept any trigger within window
        t0 = GetSecs;
        windowSec = params.triggerWindowMs / 1000;
        windowCond = @(x) (GetSecs - t0) <= windowSec;
        [~, in] = logKeyPressDual(params, in, logFile, true, false, windowCond, inputDevs);

    case 'double'
        % Wait for two triggers (most common for MRI)
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);

    otherwise
        error('Trigger:InvalidPolicy', ['Unknown trigger policy: %s. ', ...
            'Valid options are: single, double, window. Set params.triggerPolicy in src/config.m.'], policy);
end

end
