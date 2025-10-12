%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fMRI EXPERIMENTAL TASK
%
% This is a template task to run an fMRI experiment. Use it as a base to
% write your own experimental script.
% 
% The template implements a simple binary classification task where
% participants are prompted to report if images show an inside or an
% outside scene. 
% 
% Make sure to set the debugMode and fmriMode flags to the values you need
% before running this script.
%  - Turn 'debugMode' on to run the task in a window rather than full
%    screen, and to avoid saving results.
%  - Turn 'fmriMode' on to read the scanner trigger and response buttons,
%    and use the scanner screen distance and width properties.
% 
% 
% The structure & most of the ideas for this script are from previous code 
% from Andrea Costantino & Laura Van Hove. It was adapted to a general
% template by Tim Maniquet.
% 
% Authors
% Andrea Costantino, Laura Van Hove [9/6/23]
% 
% Last updated
% Tim Maniquet [22/4/24]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% STUDY-SPECIFIC SETTINGS
% ======================
% This section contains the only settings you typically need to change.
% All other configuration is in src/config.m

% Clean up MATLAB environment before starting
clc;          % Clear command window
close all;    % Close all figure windows
clear;        % Clear workspace variables
cleanObj = onCleanup(@()sca);  % Auto-close PTB window if script crashes

% === EXPERIMENT MODES (change these for your study) ===
% debugMode: Controls windowing, input devices, and logging behavior
%   true  = windowed mode, PC keyboard, pretty console output, no auto-save
%   false = fullscreen, device IDs from config, saves data automatically
debugMode = true;

% fmriMode: Controls which input codes and screen geometry to use
%   true  = use scanner trigger/buttons (buttonsFMRI), MRI screen geometry
%   false = use PC keyboard codes (buttonsPC), PC screen geometry
fmriMode = false;

%% INITIALIZE SESSION
% Load config, setup paths, validate params (all boilerplate consolidated)
[params, paths, dbg] = initializeSession(debugMode, fmriMode);

%% GET SUBJECT INFO
% Prompt for subject/run numbers (or use defaults in debug mode)
[subNum, runNum] = promptSubjectRun(params, debugMode);

% Create session info struct and output directory
in = prepareSession(subNum, runNum, debugMode);

%% PREPARE EXPERIMENT
% Build trial list from stimuli TSV, validate, and preload images
trialList = makeTrialList(params, in);
validateTrialList(trialList);
imMat = loadImages(trialList, params);

%% START LOGGING
% Create log file and write TSV header (wraps hardware init in try-catch)
logFile = createLogFile(params, in, debugMode, dbg);

% Embed the rest of the script in a try-catch structure to log errors
try
    %% HARDWARE INITIALIZATION
    % Three explicit steps for clarity (no hidden workflow)

    % 1. Initialize Psychtoolbox (close screens, unify key names)
    initPTB();

    % 2. Create input queues for trigger and response devices
    inputDevs = createInputQueues(params);

    % 3. Open PTB window, configure colors, and compute PPD
    [win, winRect, screen, in, params] = openScreen(params, in, fmriMode, debugMode, dbg);

    % Print device info in debug mode
    if debugMode
        fprintf('Input devices: trigger=%s, response=%s\n', mat2str(inputDevs.trigger), mat2str(inputDevs.response));
        fprintf('Tip: run scripts/list_devices to inspect device indices.\n');
    end

    % Log the experiment start event
    logEvent(logFile, 'START', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');
   
    %% RUN-SPECIFIC PARAMETERS
    % ========================
    % Extract just the trials for this run from the full trial list
    % (trial list contains all runs, but we only execute one run per script call)
    runTrials = trialList([trialList.run] == in.runNum);

    % Get response key codes for this run (button mapping may vary by run)
    % These are decimal key codes (e.g., 102='f', 106='j')
    params.respKeysCode = [runTrials(1).respKey1Code, runTrials(1).respKey2Code];

    % Get response instructions (displayed to participant, e.g., "left/green")
    respInst1 = runTrials(1).respInst1;
    respInst2 = runTrials(1).respInst2;

    % Extract preloaded images for this run only (memory optimization)
    % Images were loaded during setup; here we just slice the relevant subset
    runImMat = imMat.image(runTrials(1).trialNb:runTrials(end).trialNb);
    
    %% TASK EXECUTION - Instructions, Trigger, Fixations, Trials

    % Show instructions and wait for participant
    [VBL, in] = showInstructions(win, params, in, logFile, respInst1, respInst2, inputDevs, dbg);

    % Wait for scanner trigger
    [VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg);

    %% PRE-RUN FIXATION
    % =================
    % Initial baseline period before first stimulus
    % Duration set by params.prePost (e.g., 10 seconds)
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);

    if debugMode && dbg.overlay
        drawDebugOverlay(win, sprintf('Pre-fix | sub-%02d run-%02d', in.subNum, in.runNum), in);
    end

    VBL = Screen('Flip', win);  % Display fixation and get precise flip timestamp
    logEvent(logFile, 'FLIP', params.eventNames.preFix, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

    % Record run start time - this is T=0 for all ideal onset calculations
    runStart = VBL;
    preRunTime = runStart - in.scriptStart;  % How much time elapsed before run started

    % Wait for pre-run fixation duration, capturing any key presses
    % (keyboard presses are logged but not used as responses at this stage)
    [~, in, dbg] = waitAndCaptureInput(params, in, logFile, params.prePost, inputDevs, debugMode, dbg);

    %% TRIAL LOOP
    % ===========
    % Main experimental loop: present stimulus → collect response → show fixation
    % Timing is controlled by ideal onsets (pre-calculated) with drift compensation
    for i = 1:length(runTrials)
        %% TRIAL TIMING SETUP
        trialStart = GetSecs;  % Record when this trial started (for logging)

        % Adjust ideal onset: add pre-run time to convert from "run time" to "script time"
        % Trial list stores onsets relative to run start (T=0 at runStart)
        % But logging uses script start (in.scriptStart) as reference, so we add preRunTime
        runTrials(i).idealStimOnset = preRunTime + runTrials(i).idealStimOnset;

        %% STIMULUS PRESENTATION
        Screen('FillRect', win, in.gray);  % Clear to gray background

        % Get preloaded image for this trial
        if ~isempty(runImMat) && i <= numel(runImMat)
            currentImage = runImMat(i);
        else
            currentImage = [];  % Handles fixation trials
        end
        displayTrial(params, in, currentImage, runTrials(i), 1, win, winRect);

        % Optional debug overlay (toggle with special key during run)
        if debugMode && dbg.overlay
            drawDebugOverlay(win, sprintf('Trial %d | %s', i, runTrials(i).stimuli), in);
        end

        % Flip stimulus to screen and record precise timing
        VBL = Screen('Flip', win);
        actualStimOnset = VBL - in.scriptStart;  % Onset relative to script start

        % Log stimulus flip with timing deviation (delta)
        % Delta = actual - ideal; positive means late, negative means early
        logEvent(logFile, 'FLIP', params.eventNames.stimulus, dateTimeStr, runTrials(i).idealStimOnset, actualStimOnset, ...
            actualStimOnset - runTrials(i).idealStimOnset, runTrials(i).stimuli);

        runTrials(i).stimOnset = actualStimOnset;  % Store for drift compensation

        % Optional: warn if timing drifted beyond threshold
        if debugMode && dbg.warnOnDrift
            drift = (actualStimOnset - runTrials(i).idealStimOnset) * 1000; % Convert to ms
            if abs(drift) > dbg.driftWarnMs
                logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
                    sprintf('Trial %d drifted %.1f ms', i, drift));
            end
        end

        %% RESPONSE COLLECTION
        % Wait for stimulus duration (params.stimDur), collecting first valid response
        % All key presses are logged; first valid response is stored in trial struct
        [pressedKey, in, dbg] = waitAndCaptureInput(params, in, logFile, params.stimDur, inputDevs, debugMode, dbg);

        % Store response (or NaN if no response during stimulus period)
        if ~isempty(pressedKey)
            runTrials(i).response = pressedKey;
        else
            runTrials(i).response = NaN;  % No response yet (may respond during fixation)
        end

        %% INTER-STIMULUS FIXATION
        % Show fixation between trials, with duration adjusted for timing drift
        Screen('FillRect', win, in.gray);
        displayFixation(win, winRect, params, in);

        % Calculate drift-compensated fixation duration
        % If previous stimulus was late, this fixation is shortened to stay on track
        % If previous stimulus was early, this fixation is lengthened
        fixDur = adjustFixationDuration(runTrials, i, params);

        if debugMode && dbg.overlay
            drawDebugOverlay(win, sprintf('Fixation (%.2fs)', fixDur * dbg.slowMoFactor), in);
        end

        VBL = Screen('Flip', win);
        logEvent(logFile, 'FLIP', params.eventNames.fixation, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

        % Wait for fixation duration, capturing late responses
        [additionalKey, in, dbg] = waitAndCaptureInput(params, in, logFile, fixDur, inputDevs, debugMode, dbg);

        % Accept late response if participant didn't respond during stimulus
        % This allows slower responders to still provide valid data
        if isnan(runTrials(i).response) && ~isempty(additionalKey)
            runTrials(i).response = additionalKey;
        end
    end
    
    %% POST-RUN FIXATION
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);

    if debugMode && dbg.overlay
        drawDebugOverlay(win, sprintf('Post-fix | sub-%02d run-%02d', in.subNum, in.runNum), in);
    end

    PostFixFlip = Screen('Flip', win);
    logEvent(logFile, 'FLIP', params.eventNames.postFix, dateTimeStr, '-', PostFixFlip - in.scriptStart, '-', '-');

    % Wait for post-run fixation duration
    [~, in, dbg] = waitAndCaptureInput(params, in, logFile, params.prePost, inputDevs, debugMode, dbg);
    
    % Calculate and log the total duration of the run, providing a measure of the entire trial sequence length.
    runTime = GetSecs - runStart; % Calculate the total time taken for the run.
    logEvent(logFile, 'RUNTIME','-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', runTime);

%% CATCH EXCEPTION
catch exception

    % Log the exception if it has been caught
    % Get the full stack trace from the exception object
    stackTrace = getReport(exception, 'extended', 'hyperlinks', 'off');
    
    % Log error message and stack trace to the log file
    logEvent(logFile, 'ERROR','Err', dateTimeStr, '-', '-', '-', '-');
    fprintf(logFile, 'Detailed error message:\n%s\n', stackTrace);
    
    % Also display the error message in the MATLAB Command Window
    disp(['Error: ' stackTrace]);

end
%% SAVE AND CLOSE
% Finalize run: log END, save .mat, close PTB
safeRunTrials = [];
if exist('runTrials','var'), safeRunTrials = runTrials; end
safeImMat = [];
if exist('runImMat','var'), safeImMat = runImMat; end
saveAndClose(params, in, debugMode, safeRunTrials, safeImMat, logFile, dbg.saveMat);
