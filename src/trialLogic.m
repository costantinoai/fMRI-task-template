function [trial, actualStimOnset, in] = trialLogic(win, winRect, params, in, logFile, trial, image, inputDevs, dbg)
% TRIALLOGIC Defines what happens during a single trial.
%
%   This function is called once per trial by runTrialSequence.
%   ** CUSTOMIZE THIS FILE ** to change trial behavior for your study.
%
% Inputs:
%   win        - PTB window pointer
%   winRect    - Screen rectangle [x1 y1 x2 y2]
%   params     - Experiment parameters from config.m
%   in         - Session info (subNum, colors, PPD, timestamps, etc.)
%   logFile    - Log file handle (1 for console, file ID otherwise)
%   trial      - Current trial struct (from trialList)
%   image      - Preloaded image data (or [] if on-demand loading)
%   inputDevs  - Input queue devices (trigger, response)
%   dbg        - Debug options struct
%
% Outputs:
%   trial            - Updated trial struct (with response, RT, etc.)
%   actualStimOnset  - Timestamp when stimulus appeared (for drift compensation)
%   in               - Updated session info (if needed)
%
% HOW TO CUSTOMIZE:
%   - Change stimulus display: Modify displayTrial call or draw your own
%   - Add feedback: Insert DrawFormattedText + Screen('Flip') after response
%   - Change fixation: Modify displayFixation or fixDur calculation
%   - Log custom events: Call logEvent with your own event types
%   - Add conditional logic: Branch based on trial.* fields
%
% See README.md "Customizing Your Task" section for detailed examples.
%
% Author: fMRI Task Template Team
% Last updated: 2024

%% STIMULUS PRESENTATION
% Clear screen to gray background
Screen('FillRect', win, in.gray);

% Draw the stimulus image (or fixation if trial.stimuli == 'fixation')
% The displayTrial function handles both images and fixation trials
displayTrial(params, in, image, trial, 1, win, winRect);

% Add debug overlay if enabled (shows trial number)
if isfield(dbg, 'overlay') && dbg.overlay
    Screen('TextSize', win, 16);
    DrawFormattedText(win, sprintf('DEBUG: trial %d | %s', trial.trialNb, trial.stimuli), 15, 15, in.black);
end

% Flip to screen and log event
% Returns actual onset timestamp for drift compensation
VBL = Screen('Flip', win);
actualStimOnset = VBL - in.scriptStart;
logEvent(logFile, 'FLIP', 'Stim', dateTimeStr, trial.idealStimOnset, actualStimOnset, ...
    actualStimOnset - trial.idealStimOnset, trial.stimuli);

% Optional drift warning
if isfield(dbg, 'warnOnDrift') && dbg.warnOnDrift
    drift = (actualStimOnset - trial.idealStimOnset) * 1000; % Convert to ms
    if abs(drift) > dbg.driftWarnMs
        logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
            sprintf('Trial %d drifted %.1f ms', trial.trialNb, drift));
    end
end

%% RESPONSE COLLECTION
% Collect response during stimulus presentation window
% Adjust duration for debug slow-motion
stimDur = params.stimDur * dbg.slowMoFactor;

trialStart = GetSecs;
conditionFunc = @(x) (GetSecs - trialStart) <= stimDur;

% Wait for first valid response key (or timeout)
[pressedKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

% Handle debug overlay toggle (special key press)
if isfield(in, 'toggleOverlay') && in.toggleOverlay
    if isfield(dbg, 'overlay')
        dbg.overlay = ~dbg.overlay;
    else
        dbg.overlay = true;
    end
    in = rmfield(in, 'toggleOverlay');
end

% Store response in trial struct
if ~isempty(pressedKey)
    trial.response = pressedKey;
else
    trial.response = NaN; % No response
end

%% FIXATION PERIOD
% Clear screen and draw fixation
Screen('FillRect', win, in.gray);
displayFixation(win, winRect, params, in);

% Calculate adjusted fixation duration (compensates for stimulus onset drift)
% This is the key to maintaining precise timing despite PTB variability
fixDur = adjustFixationDuration(trial, params);
fixDurAdj = fixDur * dbg.slowMoFactor;

% Add debug overlay if enabled
if isfield(dbg, 'overlay') && dbg.overlay
    Screen('TextSize', win, 16);
    DrawFormattedText(win, sprintf('DEBUG: fixation (%.2fs)', fixDurAdj), 15, 15, in.black);
end

% Flip fixation to screen and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', 'Fix', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Wait for fixation duration
WaitSecs(fixDurAdj);

%% OPTIONAL CUSTOMIZATION EXAMPLES
% Uncomment and modify these examples to customize your task:

% EXAMPLE 1: Show feedback based on response
% if isfield(trial, 'correctAnswer')
%     if trial.response == trial.correctAnswer
%         DrawFormattedText(win, 'Correct!', 'center', 'center', [0 255 0]);
%     elseif ~isnan(trial.response)
%         DrawFormattedText(win, 'Wrong', 'center', 'center', [255 0 0]);
%     else
%         DrawFormattedText(win, 'Too slow!', 'center', 'center', [255 165 0]);
%     end
%     Screen('Flip', win);
%     WaitSecs(0.5);
% end

% EXAMPLE 2: Log custom event based on trial metadata
% if isfield(trial, 'condition') && strcmp(trial.condition, 'critical')
%     logEvent(logFile, 'INFO', 'CriticalTrial', dateTimeStr, '-', '-', '-', ...
%         sprintf('Trial %d condition: %s', trial.trialNb, trial.condition));
% end

% EXAMPLE 3: Conditional branching (repeat trial if no response)
% if isnan(trial.response)
%     % Flash "Please respond faster" message
%     DrawFormattedText(win, 'Please respond faster!', 'center', 'center', [255 0 0]);
%     Screen('Flip', win);
%     WaitSecs(1.0);
%
%     % Re-run this trial (recursive call)
%     [trial, actualStimOnset, in] = trialLogic(win, winRect, params, in, logFile, ...
%         trial, image, inputDevs, dbg);
% end

end
