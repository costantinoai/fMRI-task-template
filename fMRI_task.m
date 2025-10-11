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

%% CHECK AND SET WORKING DIRECTORY
% Non-interactive, fail-early setup. If required folders are missing,
% provide actionable instructions to fix the environment.

% Declare default directories for the source and utilities
defaultUtilsDir = './utils';
defaultSrcDir = './src';

% Check if the default utility directory exists
if ~exist(defaultUtilsDir, 'dir')
    error('Path:Missing', 'Missing folder %s. Create it (or run from repo root) and retry.', defaultUtilsDir);
end

% Check if the default source directory exists
if ~exist(defaultSrcDir , 'dir')
    error('Path:Missing', 'Missing folder %s. Create it with config/stimuli and retry.', defaultSrcDir);
end

% Add both directories to the MATLAB path once we're sure they exist
addpath(fullfile(pwd, 'src'));
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'scripts'));
disp('Directories have been added to the MATLAB path.');

%% IMPORT CONFIG (MATLAB) AND PRODUCE PARAMS
% Study-specific parameters now live in ./src/config.m by default.
% The loader converts them into the 'params' structure.
cfgPath = fullfile(defaultSrcDir, 'config.m');
params = TaskConfig.load(cfgPath, fmriMode);

% Debug policy: when debugMode is true, always use PC codes (buttons/trigger/escape)
if debugMode
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
        try, silent_console(true); catch, end
        try, setappdata(0,'LOG_PRETTY_HEADER_PRINTED', false); catch, end
    end

%% USER INPUT: SUBJECT & RUN NUMBER
% Keep subject/run selection visible here to make study control explicit.

% Declare subject number and decide on the run to start from
if debugMode == true
    % Default values for subject & run number in debug mode
    answer = {'99', '1'};
else
    % Else if in actual experiment mode
    prompt = {'subject number', sprintf('Run number (out of %d)', params.numRuns)};
    % Define empty default answers
    def = {'', ''};
    % Collect user input
    answer = inputdlg(prompt,'',1,def);
end

% Store the subject & run number in the 'input' structure
in.subNum = str2double(answer{1});
in.runNum = str2double(answer{2});

% Save a timestamp in the input parameters
in.timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));

%% INITIALISE PSYCHOTOOLBOX
% Initialize PTB and input queues.

% Initialise psychtoolbox (PTB)
initializePTB();

% Create dedicated input queues for trigger and responses if device IDs
% are provided. Falls back to default queue if none given.
if isfield(params, 'triggerDeviceID') && isfield(params, 'responseDeviceID')
    inputDevs = createInputQueues(params.triggerDeviceID, params.responseDeviceID);
else
    inputDevs = createInputQueues([], []);
end

% Print device bindings for awareness
if debugMode
    fprintf('Input devices: trigger=%s, response=%s\n', mat2str(inputDevs.trigger), mat2str(inputDevs.response));
    fprintf('Tip: run scripts/list_devices to inspect device indices.\n');
end

%% SETUP A SUBJECT-SPECIFIC RESULTS DIRECTORY
% All outputs land under data/sub-XX/ with invariant filenames.

% Prepares a subject- and run-specific directory to store outputs

% Make a directory name with subject number if it doesn't exist yet
in.resDir = fullfile(pwd, 'data', ['sub-' zeroFill(answer{1}, 2)]);

% Check if the results directory exists & if we're not in debug mode
if exist(in.resDir, 'dir') == 0 && debugMode == false
    mkdir(in.resDir);
end

%% LOAD TRIAL LIST & IMAGES
% Trial list is derived from params + stimuli TSV; images are preloaded.

% From the parameters (including the list of stimuli), make a trial list
trialList = makeTrialList(params, in);

% Validate trial list integrity (missing files, malformed rows)
validateTrialList(trialList);

% From the trial list and parameters, load the images
imMat = loadImages(trialList, params);

%% START LOGGING
% Keep the log header and field order unchanged for downstream tools.

% Determine the logging destination based on the debugMode and debug config
if debugMode && ~dbg.writeLogs
    % Log in the command window ('1')
    logFile = 1;
else
    % Create a new run- and subject-dependent log file
    logFile = createLogFile(params, in);
end

% Write the header row to the log file, including variable names
logEvent(logFile, 'EVENT_TYPE','EVENT_NAME','DATETIME','EXP_ONSET','ACTUAL_ONSET','DELTA','EVENT_ID');

% Embed the rest of the script in a try-catch structure to log errors
try
    %% SCREEN SETUP
    
    % Configure the PTB graphics window based on parameters and debug mode
    ssOpts = struct();
    if debugMode
        ssOpts.windowScale = dbg.windowScale;
        if ~isempty(dbg.skipSyncTests), ssOpts.skipSyncTests = dbg.skipSyncTests; end
    else
        if isfield(dbg,'releaseSkipSyncTests') && ~isempty(dbg.releaseSkipSyncTests)
            ssOpts.skipSyncTests = dbg.releaseSkipSyncTests;
        end
    end
    [win, winRect, screen, VBLTimestamp] = setupScreen(debugMode, ssOpts);
    
    % Store the screen setup time stamp
    in.scriptStart = VBLTimestamp;
    
    % Log the experiment start event with its timestamp
    logEvent(logFile, 'START','-',dateTimeStr,'-',VBLTimestamp-in.scriptStart,'-','-');

    % Define white, gray, black colours based on the screen
    [white, gray, black] = configScreenCol(screen);
    % Add these values to the input parameters
    in.white = white; in.gray = gray; in.black = black;

    % Turn the screen to gray
    Screen(win, 'fillrect', gray);
    
    % Store the pixels per degree value for use in the setup
    if isfield(params,'useScreenGeometry') && params.useScreenGeometry
        % Compute from actual screen geometry
        scrRect = Screen('Rect', screen);
        scrWpx = scrRect(3); scrHpx = scrRect(4);
        scrWmm = params.scrWidth;
        if isfield(params,'scrHeightMRI') && fmriMode
            scrHmm = params.scrHeightMRI;
        elseif isfield(params,'scrHeightPC') && ~fmriMode
            scrHmm = params.scrHeightPC;
        else
            scrHmm = scrWmm * (scrHpx / scrWpx); % estimate from aspect ratio
        end
        in.PPD = convertVisualUnits(1, 'deg', 'px', params.scrDist, scrWpx, scrHpx, scrWmm, scrHmm);
    else
        in.PPD = convertVisualUnits(1, 'deg', 'px');
    end
    % Expose PPD to params for downstream utilities that only see params
    params.PPD = in.PPD;
   
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
    
    %% INSTRUCTIONS
    
    % Generate the run-specific instructions
    displayInstructions(win, params, in, respInst1, respInst2);
    
    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end
    % Display them on screen and log it
    VBLTimestamp = flipAndLog(win, logFile, in, EVN_INSTR, '-', '-');
    
    % Anonymous function that always returns true
    conditionFunc = @(x) true; 

    % Log the key press confirming participant has read the instructions
    [~, in] = logKeyPressDual(params, in, logFile, false, true, conditionFunc, inputDevs);
    if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
        if ~isfield(dbg,'overlay') || ~dbg.overlay
            dbg.overlay = true;
        else
            dbg.overlay = false;
        end
        in = rmfield(in,'toggleOverlay');
    end
    
    %% TRIGGER WAIT
    
    % Display a message on screen while waiting for the scanner trigger
    DrawFormattedText(win, params.triggerWaitText, 'center', 'center', black);
    
    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: waiting trigger  sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end
    % Display the message and log it
    VBLTimestamp = flipAndLog(win, logFile, in, EVN_TGRWAIT, '-', '-');
    
    % Anonymous function that always returns true
    conditionFunc = @(x) true;

    % Trigger policy handling
    if isfield(params,'triggerPolicy') && strcmpi(params.triggerPolicy, 'single')
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);
    elseif isfield(params,'triggerPolicy') && strcmpi(params.triggerPolicy, 'window')
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);
        t0 = GetSecs;
        windowSec = params.triggerWindowMs / 1000;
        cond = @(x) (GetSecs - t0) <= windowSec;
        [~, in] = logKeyPressDual(params, in, logFile, true, false, cond, inputDevs);
    else
        % default 'double'
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);
        [~, in] = logKeyPressDual(params, in, logFile, true, false, conditionFunc, inputDevs);
    end
    
    %% PRE-FIXATION
    
    % Show an initial fixation display
    Screen('FillRect', win, gray); % Fill the screen with gray
    displayFixation(win, winRect, params, in); % Draw the fixation element
    
    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: pre-fix sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end
    % Display the fixation cross and log it
    VBLTimestamp = flipAndLog(win, logFile, in, EVN_PREFIX, '-', '-');
    
    % Record the trial sequence official starts, immediately after fixation
    runStart = VBLTimestamp;
    % Calculate the time elapsed since the script started
    preRunTime = runStart - in.scriptStart;
    
    % Anonymous function to wait for the duration of the pre-trial fixation
    conditionFunc = @(x) (GetSecs - runStart) <= params.prePost;

    % Wait for and log any key presses during the fixation period
    [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
    if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
        dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
    end
    
    %% TRIAL LOOP
    
    % Loop through the run trials, presenting stimuli and recording responses
    for i = 1:length(runTrials)
        %% Trial timing
        
        % Record the start time of the current trial for timing calculations
        trialStart = GetSecs;

        % Calculate and store the onset time (relative to the pre-stim fixation block)
        runTrials(i).stimOnset = trialStart - runStart;

        % Adjust fixation duration based on the timing of this trial relative to its scheduled time.
        % (recomputed later with effective debug durations)
        fixDur = adjustFixationDuration(runTrials, i, params);
    
        %% Stimulus presentation
        
        % Display the stimulus on screen based on the displayTrial function
        displayTrial(params, in, runImMat, runTrials, i, win, winRect);

        % Optional debug overlay
        if debugMode && dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('DEBUG: trial %d', i), 15, 15, in.black);
        end
        % Flip the screen and log the stimulus event
        idealStimOnset = preRunTime + runTrials(i).idealStimOnset;
        VBLTimestamp = flipAndLog(win, logFile, in, EVN_STIM, idealStimOnset, runTrials(i).stimuli);

        % Store the ideal and the actual onset values in the trial list
        runTrials(i).idealStimOnset = idealStimOnset;
        actualStimOnset = VBLTimestamp - in.scriptStart;
        runTrials(i).stimOnset = actualStimOnset;
        
        % Optional drift warning (debug-only)
        if debugMode && dbg.warnOnDrift
            delta = actualStimOnset - idealStimOnset;
            if abs(delta) > (dbg.driftWarnMs/1000)
                logEvent(logFile, 'WARN','Drift', dateTimeStr, idealStimOnset, actualStimOnset, delta, runTrials(i).stimuli);
            end
        end
        
        %% Trial response
        
        % Effective durations (debug slow motion)
        stimDurEff = params.stimDur * dbg.slowMoFactor;
        fixDurEffParam = params.fixDur * dbg.slowMoFactor; % param baseline
        paramsEff = params; paramsEff.fixDur = fixDurEffParam;
        
        % Anonymous function to wait for the duration of the stimulus duration
        conditionFunc = @(x) (GetSecs - trialStart) <= stimDurEff;
        
        % Record key presses during the stimulus presentation
        [pressedKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
        if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
            dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
        end

        % Store the response in the trial list structure
        runTrials(i).response = pressedKey;
        
        %% Post-stimulus fixation
        
        % Fill the screen with gray & show the fixation
        Screen('FillRect', win, gray);
        displayFixation(win, winRect, params, in);

        % Optional debug overlay
        if debugMode && dbg.overlay
            Screen('TextSize', win, 16);
            DrawFormattedText(win, sprintf('DEBUG: fix trial %d', i), 15, 15, in.black);
        end
        % Flip the screen and log it
        VBLTimestamp = flipAndLog(win, logFile, in, EVN_FIX, '-', '-');
    
        % Anonymous function to wait for the duration of the post-trial fixation
        fixDur = adjustFixationDuration(runTrials, i, paramsEff);
        conditionFunc = @(x) (GetSecs - trialStart) <= stimDurEff + fixDur;
        
        % Record key presses during fixation. Here we select only the first response
        % If the subj responded during the stimulus, we don't record this response
        if isempty(pressedKey) % If no key press was recorded during the stimulus presentation,
            % attempt to capture responses during the fixation.
            [pressedKey, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
            if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
                dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
            end
        else
            % Otherwise, continue to log any additional key presses (first response was already recorded).
            [~, in] = logKeyPressDual(params, in, logFile, false, false, conditionFunc, inputDevs);
            if debugMode && isfield(in,'toggleOverlay') && in.toggleOverlay
                dbg.overlay = ~dbg.overlay; in = rmfield(in,'toggleOverlay');
            end
        end
    
        % Store the response (if any) in the trial list for later analysis.
        if ~isempty(pressedKey)
            runTrials(i).response = pressedKey; % Update the trial list with the key press identifier.
        end

        %% Trial accuracy

        % % This is a working zone showing how you can record trial accuracy
        % % It is commented out by default; uncommented it to see the demo
        % % Fetch the correct key based on the current button mapping
        % if strcmp(runTrials(i).setting, 'inside')
        %     corrKey = respKey1;
        % elseif strcmp(runTrials(i).setting, 'outside')
        %     corrKey = respKey2;
        % else
        %     corrKey = NaN;
        % end
        % % Calculate accuracy based on the current pressed key
        % accuracy = corrKey == pressedKey;
        % % Log the accuracy in the console
        % fprintf(1, 'Trial %d accuracy = %d\n', i, accuracy);

    end
    
    %% FINAL FIXATION
    
    % Fill the screen with gray to reset the background
    Screen('FillRect', win, gray);
    % Draw the final fixation cross
    displayFixation(win, winRect, params, in);

    % Optional debug overlay
    if debugMode && dbg.overlay
        Screen('TextSize', win, 16);
        DrawFormattedText(win, sprintf('DEBUG: post-fix sub-%02d run-%02d', in.subNum, in.runNum), 15, 15, in.black);
    end
    % Flip the screen and log it
    PostFixFlip = flipAndLog(win, logFile, in, EVN_POSTFIX, '-', '-');
    
    % Anonymous function to wait for the duration of the final fixation
    conditionFunc = @(x) (GetSecs - PostFixFlip) <= params.prePost;

    % Record any key presses during this final fixation period, ensuring all participant responses are captured
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

% Log the end of the run only if timing info exists
if exist('in','var') && isstruct(in) && isfield(in,'scriptStart')
    logEvent(logFile, 'END','-', dateTimeStr, '-', GetSecs-in.scriptStart, '-', '-');
end

% Save the relevant data and close PTB objects
safeRunTrials = [];
if exist('runTrials','var'), safeRunTrials = runTrials; end
safeImMat = [];
if exist('runImMat','var'), safeImMat = runImMat; end
saveAndClose(params, in, debugMode, safeRunTrials, safeImMat, logFile, dbg.saveMat);
