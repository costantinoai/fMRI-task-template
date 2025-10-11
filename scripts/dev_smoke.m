% DEV_SMOKE Quick deterministic smoke test for development.
%
% Runs a minimal 2-trial experiment with mock images in windowed mode.
% Useful for:
% - Testing code changes without full PTB setup
% - Verifying timing logic and log output
% - Fast iteration during development
%
% Configuration:
% - Always runs in debugMode (windowed, no save)
% - fmriMode = false (PC input codes)
% - Deterministic RNG seed for reproducibility
% - 2 trials only (overrides config)
% - No image preloading (faster startup)
%
% To run: scripts/dev_smoke
%
% Author: fMRI Task Template Team
% Last updated: 2025

%% CLEANUP & SETUP
clc;
close all;
clear;

% Force debug and PC modes
debugMode = true;
fmriMode = false;

% Ensure cleanup
cleanObj = onCleanup(@()sca);

fprintf('=== DEV SMOKE TEST ===\n');
fprintf('Quick 2-trial run for development/testing\n\n');

%% ENVIRONMENT & CONFIG
paths = prepareEnvironment();
cfgPath = fullfile(paths.src, 'config.m');
params = TaskConfig.load(cfgPath, fmriMode);

% Override for quick testing
params.numRuns = 1;
params.numRepetitions = 1;  % Will be overridden by trial count
params.preloadImages = false;  % Faster startup
params.prePost = 2;  % Shorter fixation periods
params.stimDur = 1;  % Shorter stimulus
params.fixDur = 1;  % Shorter fixation

% Force PC codes for debug
if isfield(params, 'buttonsPC') && ~isempty(params.buttonsPC)
    params.buttons = params.buttonsPC;
    if numel(params.buttonsPC) >= 2
        params.respKey1Code = params.buttonsPC(1);
        params.respKey2Code = params.buttonsPC(2);
    end
end
if isfield(params, 'triggerKeyPCCode') && ~isempty(params.triggerKeyPCCode)
    params.triggerKeyCode = params.triggerKeyPCCode;
end
if isfield(params, 'escapeKeyPCCode') && ~isempty(params.escapeKeyPCCode)
    params.escapeKeyCode = params.escapeKeyPCCode;
end

validateParams(params, fmriMode);

% Debug options with deterministic seed
dbg = struct('writeLogs', false, 'saveMat', false, 'windowScale', 0.5, ...
    'slowMoFactor', 1.0, 'overlay', true, 'skipSyncTests', 1, ...
    'warnOnDrift', false, 'driftWarnMs', 10, 'rngSeed', 42, ...
    'releaseSkipSyncTests', []);

% Pretty console output
try
    pretty_console(true);
    setappdata(0, 'LOG_SILENT_CONSOLE', true);
    setappdata(0, 'LOG_PRETTY_HEADER_PRINTED', false);
catch
end

%% SESSION SETUP
% Default smoke test subject/run
in = prepareSession(99, 1, debugMode);

%% LOAD MINIMAL TRIAL LIST
% Read stimuli list
trialList = makeTrialList(params, in);

% Override to use only 2 trials for speed
if numel(trialList) > 2
    trialList = trialList(1:2);
    fprintf('Note: Limited to 2 trials for smoke test\n');
end

validateTrialList(trialList);

% Load images (only for selected trials)
if params.preloadImages
    imMat = loadImages(trialList, params);
else
    imMat = struct('image', []);
end

%% START LOGGING (console only)
logFile = initLogging(params, in, debugMode, dbg);

try
    %% HARDWARE INIT
    [win, winRect, ~, in, inputDevs] = initializeHardware(params, in, fmriMode, debugMode, dbg);

    fprintf('\n=== Smoke Test Ready ===\n');
    fprintf('Device IDs: trigger=%s, response=%s\n', ...
        mat2str(inputDevs.trigger), mat2str(inputDevs.response));
    fprintf('Press any key for instructions...\n');

    logEvent(logFile, 'START', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');

    %% RUN-SPECIFIC PARAMS
    runTrials = trialList([trialList.run] == in.runNum);
    respKey1Code = runTrials(1).respKey1Code;
    respKey2Code = runTrials(1).respKey2Code;
    params.respKeysCode = [respKey1Code, respKey2Code];
    respInst1 = runTrials(1).respInst1;
    respInst2 = runTrials(1).respInst2;

    if params.preloadImages
        runImMat = imMat.image(runTrials(1).trialNb:runTrials(end).trialNb);
    else
        runImMat = [];
    end

    %% TASK EXECUTION
    % Instructions
    [VBL, in] = showInstructions(win, params, in, logFile, respInst1, respInst2, inputDevs, dbg);

    % Trigger wait (press '5' to continue in PC mode)
    [VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg);

    % Pre-fix
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);
    if dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, 'DEBUG: Pre-fix (smoke)', 15, 15, in.black);
    end
    VBL = Screen('Flip', win);
    logEvent(logFile, 'FLIP', 'Pre-fix', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

    runStart = VBL;
    preRunTime = runStart - in.scriptStart;

    % Wait for pre-fix duration
    conditionFunc = @(x) (GetSecs - runStart) <= (params.prePost * dbg.slowMoFactor);
    [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

    %% TRIAL LOOP (minimal)
    for i = 1:length(runTrials)
        trialStart = GetSecs;
        runTrials(i).idealStimOnset = preRunTime + runTrials(i).idealStimOnset;

        % Stimulus
        Screen('FillRect', win, in.gray);
        if ~isempty(runImMat) && i <= numel(runImMat)
            currentImage = runImMat(i);
        else
            currentImage = [];
        end
        displayTrial(params, in, currentImage, runTrials(i), 1, win, winRect);

        if dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('SMOKE: trial %d/%d | %s', ...
                i, length(runTrials), runTrials(i).stimuli), 15, 15, in.black);
        end

        VBL = Screen('Flip', win);
        actualStimOnset = VBL - in.scriptStart;
        logEvent(logFile, 'FLIP', 'Stim', dateTimeStr, runTrials(i).idealStimOnset, ...
            actualStimOnset, actualStimOnset - runTrials(i).idealStimOnset, runTrials(i).stimuli);
        runTrials(i).stimOnset = actualStimOnset;

        % Response collection
        stimDur = params.stimDur * dbg.slowMoFactor;
        conditionFunc = @(x) (GetSecs - trialStart) <= stimDur;
        [pressedKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

        runTrials(i).response = ~isempty(pressedKey) ? pressedKey : NaN;

        % Fixation
        Screen('FillRect', win, in.gray);
        displayFixation(win, winRect, params, in);
        fixDur = adjustFixationDuration(runTrials, i, params);
        fixDurAdj = fixDur * dbg.slowMoFactor;

        if dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('SMOKE: fixation %.2fs', fixDurAdj), 15, 15, in.black);
        end

        VBL = Screen('Flip', win);
        logEvent(logFile, 'FLIP', 'Fix', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

        conditionFunc = @(x) (GetSecs - VBL) <= fixDurAdj;
        [additionalKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

        if isnan(runTrials(i).response) && ~isempty(additionalKey)
            runTrials(i).response = additionalKey;
        end
    end

    %% POST-FIX
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);
    if dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, 'SMOKE: Post-fix', 15, 15, in.black);
    end
    PostFixFlip = Screen('Flip', win);
    logEvent(logFile, 'FLIP', 'Post-fix', dateTimeStr, '-', PostFixFlip - in.scriptStart, '-', '-');

    conditionFunc = @(x) (GetSecs - PostFixFlip) <= (params.prePost * dbg.slowMoFactor);
    [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

    runTime = GetSecs - runStart;
    logEvent(logFile, 'RUNTIME', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', runTime);

catch exception
    stackTrace = getReport(exception, 'extended', 'hyperlinks', 'off');
    logEvent(logFile, 'ERROR', 'Err', dateTimeStr, '-', '-', '-', '-');
    fprintf(logFile, 'Detailed error message:\n%s\n', stackTrace);
    disp(['Error: ' stackTrace]);
end

%% FINALIZE
finalizeRun(params, in, debugMode, runTrials, [], logFile, false);

fprintf('\n=== Smoke Test Complete ===\n');
fprintf('Check console output above for timing and events.\n');
