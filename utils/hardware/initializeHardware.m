function [win, winRect, screen, in, inputDevs] = initializeHardware(params, in, fmriMode, debugMode, dbg)
% INITIALIZEHARDWARE Setup PTB, screen, input queues, and compute PPD.
%
%   One-stop function for all hardware initialization.
%   Handles debug vs release screen setup, PPD calculation, and input queues.
%
% Inputs:
%   params    - Experiment parameters (deviceIDs, scrDist, scrWidth, useScreenGeometry, etc.)
%   in        - Session info (updated with colors, PPD, scriptStart)
%   fmriMode  - Boolean flag (true = use MRI screen geometry)
%   debugMode - Boolean flag (true = windowed mode)
%   dbg       - Debug options (windowScale, skipSyncTests, releaseSkipSyncTests)
%
% Outputs:
%   win       - PTB window pointer
%   winRect   - Screen rectangle [x1 y1 x2 y2]
%   screen    - Screen number
%   in        - Updated session info with added fields:
%               - scriptStart: VBL timestamp when screen opened (timing reference)
%               - white, gray, black: Screen color values
%               - PPD: Pixels per degree of visual angle
%   inputDevs - Input queue devices struct (trigger, response)
%
% Errors:
%   Hardware:PTBFailed    - PTB initialization failed
%   Hardware:ScreenFailed - Screen setup failed
%
% Example:
%   [win, winRect, screen, in, inputDevs] = initializeHardware(params, in, false, true, dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2024

%% Initialize PTB
try
    Screen('CloseAll');
    KbName('UnifyKeyNames');
catch ME
    error('Hardware:PTBFailed', ['PTB initialization failed: %s. ', ...
        'Make sure Psychtoolbox is installed and on the MATLAB path.'], ME.message);
end

%% Create input queues
% Extract device IDs from params (if provided)
if isfield(params, 'deviceIDs') && isstruct(params.deviceIDs)
    triggerID = params.deviceIDs.trigger;
    responseID = params.deviceIDs.response;
else
    triggerID = [];
    responseID = [];
end

try
    inputDevs = createInputQueues(triggerID, responseID);
catch ME
    error('Hardware:InputQueuesFailed', ['Input queue creation failed: %s. ', ...
        'Check params.deviceIDs in src/config.m or run scripts/list_devices.'], ME.message);
end

%% Setup screen
try
    % Build screen setup options
    ssOpts = struct();
    if debugMode
        ssOpts.windowScale = dbg.windowScale;
        if ~isempty(dbg.skipSyncTests)
            ssOpts.skipSyncTests = dbg.skipSyncTests;
        end
    else
        % Release mode
        if isfield(dbg, 'releaseSkipSyncTests') && ~isempty(dbg.releaseSkipSyncTests)
            ssOpts.skipSyncTests = dbg.releaseSkipSyncTests;
        end
    end

    % Open PTB window
    [win, winRect, screen, VBLTimestamp] = setupScreen(debugMode, ssOpts);

catch ME
    error('Hardware:ScreenFailed', ['Screen setup failed: %s. ', ...
        'Try setting dbg.skipSyncTests=1 in src/config.m for debugging (NOT for real experiments).'], ME.message);
end

%% Store screen timing reference
% All event onsets are logged relative to this timestamp
in.scriptStart = VBLTimestamp;

%% Configure screen colors
% Get CLUT indices for black/white/gray
in.white = WhiteIndex(screen);
in.black = BlackIndex(screen);
in.gray = round(in.white / 2);

% Fill screen with gray background
Screen(win, 'FillRect', in.gray);

%% Compute pixels per degree (PPD)
if isfield(params, 'useScreenGeometry') && params.useScreenGeometry
    % Use actual measured screen geometry for accurate visual angle calculations
    scrRect = Screen('Rect', screen);
    scrWpx = scrRect(3);  % Screen width in pixels
    scrHpx = scrRect(4);  % Screen height in pixels

    % Get screen width in mm (mode-specific)
    if fmriMode && isfield(params, 'scrWidthMRI')
        scrWmm = params.scrWidthMRI;
    elseif ~fmriMode && isfield(params, 'scrWidthPC')
        scrWmm = params.scrWidthPC;
    elseif isfield(params, 'scrWidth')
        scrWmm = params.scrWidth;
    else
        error('Hardware:MissingGeometry', ['useScreenGeometry=true but scrWidth not found. ', ...
            'Set params.scrWidthMRI and params.scrWidthPC in src/config.m.']);
    end

    % Get screen height in mm (or estimate from aspect ratio)
    if fmriMode && isfield(params, 'scrHeightMRI')
        scrHmm = params.scrHeightMRI;
    elseif ~fmriMode && isfield(params, 'scrHeightPC')
        scrHmm = params.scrHeightPC;
    elseif isfield(params, 'scrHeight')
        scrHmm = params.scrHeight;
    else
        % Estimate height from aspect ratio
        scrHmm = scrWmm * (scrHpx / scrWpx);
    end

    % Get viewing distance (mode-specific)
    if fmriMode && isfield(params, 'scrDistMRI')
        scrDist = params.scrDistMRI;
    elseif ~fmriMode && isfield(params, 'scrDistPC')
        scrDist = params.scrDistPC;
    elseif isfield(params, 'scrDist')
        scrDist = params.scrDist;
    else
        error('Hardware:MissingGeometry', ['useScreenGeometry=true but scrDist not found. ', ...
            'Set params.scrDistMRI and params.scrDistPC in src/config.m.']);
    end

    % Calculate PPD using screen geometry
    in.PPD = convertVisualUnits(1, 'deg', 'px', scrDist, scrWpx, scrHpx, scrWmm, scrHmm);

else
    % Use hardcoded defaults in convertVisualUnits
    in.PPD = convertVisualUnits(1, 'deg', 'px');
end

% Expose PPD to params for utilities that only receive params
params.PPD = in.PPD;

end
