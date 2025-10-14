function [VBL, actualOnset] = showTrialStimulus(win, winRect, params, in, image, trial, trialIdx, logFile, debugMode, dbg)
% SHOWTRIAL STIMULUS Display stimulus, flip, log timing, and optionally warn on drift
%
%   Consolidates the common pattern of: fill background → display trial →
%   optional debug overlay → flip → log with timing → optional drift warning.
%
% Inputs:
%   win         - PTB window pointer
%   winRect     - Screen rectangle [x1 y1 x2 y2]
%   params      - Experiment parameters (eventNames, etc.)
%   in          - Session info (scriptStart, gray, colors)
%   image       - Preloaded image matrix/struct or []
%   trial       - Trial struct with idealStimOnset, stimuli fields
%   trialIdx    - Trial index (for debug overlay and warnings)
%   logFile     - Log file handle
%   debugMode   - Enable debug features (logical)
%   dbg         - Debug options (overlay, warnOnDrift, driftWarnMs)
%
% Outputs:
%   VBL         - Flip timestamp (GetSecs)
%   actualOnset - Onset relative to script start (seconds)
%
% Example:
%   [VBL, onset] = showTrialStimulus(win, winRect, params, in, img, ...
%       trial, 5, logFile, true, dbg);
%
% See also: displayTrial, displayFixation, logEvent
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Fill background
Screen('FillRect', win, in.gray);

% Display trial content (stimulus or fixation)
displayTrial(params, in, image, trial, 1, win, winRect);

% Optional debug overlay
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Trial %d | %s', trialIdx, trial.stimuli), in);
end

% Flip and record timing
VBL = Screen('Flip', win);
actualOnset = VBL - in.scriptStart;

% Log flip event with timing delta
logEvent(logFile, 'FLIP', params.eventNames.stimulus, dateTimeStr, ...
    trial.idealStimOnset, actualOnset, ...
    actualOnset - trial.idealStimOnset, trial.stimuli);

% Optional drift warning
if debugMode && dbg.warnOnDrift
    drift = (actualOnset - trial.idealStimOnset) * 1000; % ms
    if abs(drift) > dbg.driftWarnMs
        logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
            sprintf('Trial %d drifted %.1f ms', trialIdx, drift));
    end
end

end
