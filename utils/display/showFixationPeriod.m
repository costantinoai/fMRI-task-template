function VBL = showFixationPeriod(win, winRect, params, in, logFile, duration, eventName, dbg)
% SHOWFIXATIONPERIOD Display fixation cross for a specified duration.
%
%   Handles gray background, fixation drawing, flip+log, and wait.
%   Automatically includes debug overlay if dbg.overlay is true.
%
% Inputs:
%   win       - PTB window pointer
%   winRect   - Screen rectangle [x1 y1 x2 y2]
%   params    - Fixation parameters (fixSize, fixType)
%   in        - Session info (gray, black, colors, subNum, runNum, scriptStart)
%   logFile   - Log file handle
%   duration  - Duration in seconds
%   eventName - Event name for logging (e.g., 'Pre-fix', 'Post-fix')
%   dbg       - Debug options (overlay, slowMoFactor)
%
% Outputs:
%   VBL - VBL timestamp of fixation flip
%
% Example:
%   VBL = showFixationPeriod(win, winRect, params, in, logFile, 10, 'Pre-fix', dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2024

% Clear screen to gray background
Screen('FillRect', win, in.gray);

% Draw fixation cross
displayFixation(win, winRect, params, in);

% Add debug overlay if enabled
if isfield(dbg, 'overlay') && dbg.overlay
    overlayText = sprintf('DEBUG: %s | sub-%02d run-%02d', eventName, in.subNum, in.runNum);
    Screen('TextSize', win, 16);
    DrawFormattedText(win, overlayText, 15, 15, in.black);
end

% Flip and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', eventName, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Wait for duration (adjusted for debug slow-motion)
adjustedDuration = duration * dbg.slowMoFactor;
WaitSecs(adjustedDuration);

end
