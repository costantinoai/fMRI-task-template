function runTrials = runTrialSequence(win, winRect, params, in, logFile, runTrials, runImMat, inputDevs, dbg, trialLogicFn)
% RUNTRIALSEQUENCE Execute the trial loop with automatic timing management.
% TODO: I do not like this. let;s keep the run and trial logic in the main
% task file.
%
%   Calls user-defined trial logic function for each trial and handles
%   timing bookkeeping, drift warnings, error recovery, and escape handling.
%
% Inputs:
%   win          - PTB window pointer
%   winRect      - Screen rectangle [x1 y1 x2 y2]
%   params       - Experiment parameters
%   in           - Session info (scriptStart, colors, etc.)
%   logFile      - Log file handle
%   runTrials    - Array of trial structs for current run
%   runImMat     - Preloaded images (or [] if on-demand)
%   inputDevs    - Input queue devices (trigger, response)
%   dbg          - Debug options (warnOnDrift, overlay, slowMoFactor)
%   trialLogicFn - Function handle to user's trial logic (e.g., @trialLogic)
%
% Outputs:
%   runTrials - Updated trial array with responses and actual timings
%
% Error handling:
%   - Escape key raises ScriptExecution:ManuallyAborted
%   - Invalid trial logic function raises TrialSequence:InvalidLogicFn
%   - PTB errors bubble up to main script's try-catch
%
% Example:
%   runTrials = runTrialSequence(win, winRect, params, in, logFile, ...
%       runTrials, runImMat, inputDevs, dbg, @trialLogic);
%
% Author: fMRI Task Template Team
% Last updated: 2024

%% Validate inputs
if ~isa(trialLogicFn, 'function_handle')
    error('TrialSequence:InvalidLogicFn', ['trialLogicFn must be a function handle. ', ...
        'Expected @trialLogic or @yourCustomFunction. ', ...
        'Make sure src/trialLogic.m exists and is on the MATLAB path.']);
end

if isempty(runTrials)
    error('TrialSequence:EmptyTrials', ['No trials found for this run. ', ...
        'Check that runTrials was extracted correctly from trialList.']);
end

%% Loop through trials
for i = 1:numel(runTrials)
    % Extract image for this trial (if preloaded)
    if ~isempty(runImMat) && i <= numel(runImMat)
        currentImage = runImMat(i);
    else
        currentImage = []; % On-demand loading
    end

    % Call user's trial logic function
    try
        [runTrials(i), actualStimOnset, in] = trialLogicFn(win, winRect, params, in, logFile, ...
            runTrials(i), currentImage, inputDevs, dbg);

    catch ME
        % Check for escape key abort (user requested exit)
        if strcmp(ME.identifier, 'ScriptExecution:ManuallyAborted')
            rethrow(ME); % Propagate to main script's catch block
        end

        % Log error and provide context
        logEvent(logFile, 'ERROR', sprintf('Trial_%d', i), dateTimeStr, '-', '-', '-', ME.message);

        % Add stack trace to log
        for j = 1:min(3, numel(ME.stack))
            stackMsg = sprintf('%s (line %d)', ME.stack(j).name, ME.stack(j).line);
            logEvent(logFile, 'ERROR', 'Stack', dateTimeStr, '-', '-', '-', stackMsg);
        end

        % Re-throw with helpful message
        error('TrialSequence:TrialLogicFailed', ...
            ['Trial logic failed at trial %d (%s): %s\n', ...
            'Check src/trialLogic.m for issues. See log file for full stack trace.'], ...
            i, runTrials(i).stimuli, ME.message);
    end

    % Store actual stimulus onset (already set in trial logic, but ensure it's there)
    if exist('actualStimOnset', 'var') && ~isempty(actualStimOnset)
        runTrials(i).stimOnset = actualStimOnset;
    end
end

end
