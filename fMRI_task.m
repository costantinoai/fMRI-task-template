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
% Configure experiment modes here. All other setup is handled by utilities.

% Clean up the environment
clc;
close all;
clear;
cleanObj = onCleanup(@()sca);  % Ensure PTB window closes on script exit

% === EXPERIMENT MODES (change these for your study) ===
debugMode = true;   % true = windowed mode, PC inputs, pretty console
fmriMode = false;   % true = fullscreen, MRI inputs, scanner geometry

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
    
    % Extract the trials of the run
    runTrials = trialList([trialList.run] == in.runNum);
    
    % Based on the run number find the response buttons (decimal codes)
    respKey1Code = runTrials(1).respKey1Code;
    respKey2Code = runTrials(1).respKey2Code;
    % Response codes for robust comparisons; logs keep readable names
    params.respKeysCode = [respKey1Code, respKey2Code];

    % Based on the run number find the response button instructions
    respInst1 = runTrials(1).respInst1;
    respInst2 = runTrials(1).respInst2;
    
    % Extract the images of the run (if preloaded)
    if isfield(params,'preloadImages') && params.preloadImages
        runImMat = imMat.image(runTrials(1).trialNb:runTrials(end).trialNb);
    else
        runImMat = [];
    end
    
    %% TASK EXECUTION - Instructions, Trigger, Fixations, Trials

    % Show instructions and wait for participant
    [VBL, in] = showInstructions(win, params, in, logFile, respInst1, respInst2, inputDevs, dbg);

    % Wait for scanner trigger
    [VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg);

    % Pre-run fixation period
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);

    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: Pre-fix | sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end

    % Flip and log
    VBL = Screen('Flip', win);
    logEvent(logFile, 'FLIP', params.eventNames.preFix, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

    % Record run start time (for ideal onset calculations)
    runStart = VBL;
    % Calculate the time elapsed since the script started (for adjusting ideal onsets)
    preRunTime = runStart - in.scriptStart;

    % Anonymous function to wait for the duration of the pre-trial fixation
    conditionFunc = @(x) (GetSecs - runStart) <= (params.prePost * dbg.slowMoFactor);

    % Wait for and log any key presses during the fixation period
    [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
    if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
        dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
    end

    %% TRIAL LOOP
    % Loop through the run trials, presenting stimuli and recording responses
    for i = 1:length(runTrials)
        %% Trial timing
        trialStart = GetSecs;

        % Adjust trial's ideal onset to account for pre-trigger delays
        runTrials(i).idealStimOnset = preRunTime + runTrials(i).idealStimOnset;

        %% Stimulus presentation
        % Clear screen to gray background
        Screen('FillRect', win, in.gray);

        % Display the stimulus image
        if ~isempty(runImMat) && i <= numel(runImMat)
            currentImage = runImMat(i);
        else
            currentImage = [];
        end
        displayTrial(params, in, currentImage, runTrials(i), 1, win, winRect);

        % Optional debug overlay
        if debugMode && dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('DEBUG: trial %d | %s', i, runTrials(i).stimuli), 15, 15, in.black);
        end

        % Flip to screen and log event
        VBL = Screen('Flip', win);
        actualStimOnset = VBL - in.scriptStart;
        logEvent(logFile, 'FLIP', params.eventNames.stimulus, dateTimeStr, runTrials(i).idealStimOnset, actualStimOnset, ...
            actualStimOnset - runTrials(i).idealStimOnset, runTrials(i).stimuli);

        % Store actual onset for drift compensation
        runTrials(i).stimOnset = actualStimOnset;

        % Optional drift warning
        if debugMode && dbg.warnOnDrift
            drift = (actualStimOnset - runTrials(i).idealStimOnset) * 1000; % ms
            if abs(drift) > dbg.driftWarnMs
                logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
                    sprintf('Trial %d drifted %.1f ms', i, drift));
            end
        end

        %% Response collection
        % Adjust duration for debug slow-motion
        stimDur = params.stimDur * dbg.slowMoFactor;
        conditionFunc = @(x) (GetSecs - trialStart) <= stimDur;

        % Wait for first valid response key (or timeout)
        [pressedKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

        % Handle debug overlay toggle
        if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
            dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
        end

        % Store response
        if ~isempty(pressedKey)
            runTrials(i).response = pressedKey;
        else
            runTrials(i).response = NaN;
        end

        %% Post-stimulus fixation
        % Clear screen and draw fixation
        Screen('FillRect', win, in.gray);
        displayFixation(win, winRect, params, in);

        % Calculate adjusted fixation duration (compensates for drift)
        fixDur = adjustFixationDuration(runTrials, i, params);
        fixDurAdj = fixDur * dbg.slowMoFactor;

        % Optional debug overlay
        if debugMode && dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('DEBUG: fixation (%.2fs)', fixDurAdj), 15, 15, in.black);
        end

        % Flip fixation to screen and log
        VBL = Screen('Flip', win);
        logEvent(logFile, 'FLIP', params.eventNames.fixation, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

        % Wait for fixation duration and log any additional key presses
        conditionFunc = @(x) (GetSecs - VBL) <= fixDurAdj;
        [additionalKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);

        % Handle debug overlay toggle
        if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
            dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
        end

        % Update response if participant responded during fixation (and hadn't responded yet)
        if isnan(runTrials(i).response) && ~isempty(additionalKey)
            runTrials(i).response = additionalKey;
        end
    end
    
    %% FINAL FIXATION
    % Post-run fixation period
    Screen('FillRect', win, in.gray);
    displayFixation(win, winRect, params, in);

    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: Post-fix | sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end

    % Flip and log
    PostFixFlip = Screen('Flip', win);
    logEvent(logFile, 'FLIP', params.eventNames.postFix, dateTimeStr, '-', PostFixFlip - in.scriptStart, '-', '-');

    % Record any key presses during this final fixation period
    conditionFunc = @(x) (GetSecs - PostFixFlip) <= (params.prePost * dbg.slowMoFactor);
    [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
    if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
        dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
    end
    
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
