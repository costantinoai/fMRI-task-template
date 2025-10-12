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

%% CLEANUP & SET MODES
% Study-specific entrypoint: configure modes and any per-study choices here.
% Utilities in ./utils are generic; keep study semantics in this file.

% Clean up the environment
clc; % Clear the Command Window.
close all; % Close all figures (except those of imtool.)
clear; % Clear all variables from the workspace.

% Ensure that the screen gets closed when the script terminates.
cleanObj = onCleanup(@()sca);

% Decide on the debugMode and PC mode
debugMode = true; % debugMode mode flag. Set to false for actual experiment runs.
fmriMode = false; % Computer mode flag. Set to true whenrunning on the fMRI scanner computer.

% (Device IDs are configured via src/config.m)

% Event name constants (for consistency)
EVN_INSTR   = 'Instr';
EVN_TGRWAIT = 'TgrWait';
EVN_PREFIX  = 'Pre-fix';
EVN_STIM    = 'Stim';
EVN_FIX     = 'Fix';
EVN_POSTFIX = 'Post-fix';

%% SETUP ENVIRONMENT
% Verify paths and load configuration using setup helpers.

% Add utils to path first (prepareEnvironment itself is in utils/)
addpath(genpath('./utils'));

% Check folders exist and add to MATLAB path
paths = prepareEnvironment();

% Load experiment configuration
cfgPath = fullfile(paths.src, 'config.m');
params = TaskConfig.load(cfgPath, fmriMode);

% Debug policy: when debugMode is true, always use PC codes (buttons/trigger/escape)
if debugMode
    % Enable pretty console output in debug mode for better readability
    setappdata(0, 'LOG_PRETTY_CONSOLE', true);
    if isfield(params,'buttonsPC') && ~isempty(params.buttonsPC)
        params.buttons = params.buttonsPC;
        if numel(params.buttonsPC) >= 2
            params.respKey1Code = params.buttonsPC(1);
            params.respKey2Code = params.buttonsPC(2);
        end
    end
    if isfield(params,'triggerKeyPCCode') && ~isempty(params.triggerKeyPCCode)
        params.triggerKeyCode = params.triggerKeyPCCode;
    end
    if isfield(params,'escapeKeyPCCode') && ~isempty(params.escapeKeyPCCode)
        params.escapeKeyCode = params.escapeKeyPCCode;
    end
end

validateParams(params, fmriMode);

% Debug options: defaults + optional overrides from config.debug
dbg = struct('writeLogs', false, 'saveMat', false, 'windowScale', 0.9, ...
             'slowMoFactor', 1.0, 'overlay', false, 'skipSyncTests', [], ...
             'warnOnDrift', false, 'driftWarnMs', 10, 'rngSeed', [], ...
             'releaseSkipSyncTests', []);
if isfield(params, 'debug') && isstruct(params.debug)
    fns = fieldnames(params.debug);
    for ii=1:numel(fns)
        dbg.(fns{ii}) = params.debug.(fns{ii});
    end
end

% In debug mode, prefer a readable console and less console I/O
    if debugMode
    try, pretty_console(true); catch, end
    % Suppress TSV echo in console without helper scripts
    try, setappdata(0,'LOG_SILENT_CONSOLE', true); catch, end
    try, setappdata(0,'LOG_PRETTY_HEADER_PRINTED', false); catch, end
    end

%% SESSION SETUP
% Get subject/run numbers and prepare session info.

% Get subject and run number (interactive or default for debug)
if debugMode
    answer = {'99', '1'};
else
    prompt = {'Subject number', sprintf('Run number (out of %d)', params.numRuns)};
    answer = inputdlg(prompt, '', 1, {'', ''});
end

subNum = str2double(answer{1});
runNum = str2double(answer{2});

% Create session info struct and output directory
in = prepareSession(subNum, runNum, debugMode);

%% INITIALIZE HARDWARE
% Setup PTB, screen, input queues, and compute PPD.
% This must happen AFTER logging starts so screen timing is captured.
% (Will be called inside try-catch block after logFile is created)

%% LOAD TRIAL LIST & IMAGES
% Trial list is derived from params + stimuli TSV; images are preloaded.

% From the parameters (including the list of stimuli), make a trial list
trialList = makeTrialList(params, in);

% Validate trial list integrity (missing files, malformed rows)
validateTrialList(trialList);

% From the trial list and parameters, load the images
imMat = loadImages(trialList, params);

%% START LOGGING
% Create log file and write TSV header
logFile = createLogFile(params, in, debugMode, dbg);

% Embed the rest of the script in a try-catch structure to log errors
try
    %% HARDWARE INITIALIZATION
    % Initialize PTB, screen, input queues, and compute PPD
    [win, winRect, screen, in, inputDevs] = initializeHardware(params, in, fmriMode, debugMode, dbg);

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
    logEvent(logFile, 'FLIP', EVN_PREFIX, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

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
        logEvent(logFile, 'FLIP', EVN_STIM, dateTimeStr, runTrials(i).idealStimOnset, actualStimOnset, ...
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
        logEvent(logFile, 'FLIP', EVN_FIX, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

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
    logEvent(logFile, 'FLIP', EVN_POSTFIX, dateTimeStr, '-', PostFixFlip - in.scriptStart, '-', '-');

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
