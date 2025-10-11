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
% Last updated: 2024

% Draw instructions using existing helper
displayInstructions(win, params, in, respInst1, respInst2);

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
