function [win, winRect, screen, in, params] = openScreen(params, in, fmriMode, debugMode, dbg)
% OPENSCREEN Open PTB window, configure colors, and compute PPD.
%
%   Opens PTB graphics window (fullscreen or windowed based on mode),
%   gets color indices, fills with gray, computes pixels per degree,
%   and stores timing reference.
%
% Inputs:
%   params    - Experiment parameters (useScreenGeometry, scrDist, scrWidth, etc.)
%   in        - Session info (will be updated with scriptStart, colors, PPD)
%   fmriMode  - If true, use MRI screen geometry
%   debugMode - If true, open windowed mode
%   dbg       - Debug options (windowScale, skipSyncTests, releaseSkipSyncTests)
%
% Outputs:
%   win     - PTB window pointer
%   winRect - Screen rectangle [x1 y1 x2 y2]
%   screen  - Screen number
%   in      - Updated with scriptStart, white, gray, black, PPD
%   params  - Updated with PPD (for utilities that only receive params)
%
% Errors:
%   Hardware:ScreenFailed     - Screen setup failed
%   Hardware:MissingGeometry  - Required geometry fields missing
%
% Example:
%   [win, winRect, screen, in, params] = openScreen(params, in, false, true, dbg);
%
% Author: fMRI Task Template Team
% Last updated: 2025

try
    % Determine sync test policy based on mode
    if debugMode
        if ~isempty(dbg.skipSyncTests)
            Screen('Preference', 'SkipSyncTests', dbg.skipSyncTests);
        else
            Screen('Preference', 'SkipSyncTests', 0);
        end
    else
        % Release mode: default to skip=1 unless overridden
        if isfield(dbg, 'releaseSkipSyncTests') && ~isempty(dbg.releaseSkipSyncTests)
            Screen('Preference', 'SkipSyncTests', dbg.releaseSkipSyncTests);
        else
            Screen('Preference', 'SkipSyncTests', 1);
        end
    end

    % Select screen (typically primary monitor)
    screen = max(Screen('Screens'));

    % Open window based on mode
    if debugMode
        % Windowed mode: scaled window with GUI decorations for easy debugging
        windowRect = Screen('Rect', screen);
        windowRect(3) = round(windowRect(3) * dbg.windowScale);
        windowRect(4) = round(windowRect(4) * dbg.windowScale);
        [win, winRect] = Screen('OpenWindow', screen, 0, windowRect, [], [], [], [], [], kPsychGUIWindow);
    else
        % Fullscreen mode: hide cursor/keyboard for clean presentation
        ListenChar(2);
        HideCursor;
        [win, winRect] = Screen('OpenWindow', screen, 0);
    end

    % Get initial flip timestamp (timing reference for all logged events)
    VBLTimestamp = Screen('Flip', win);

catch ME
    error('Hardware:ScreenFailed', ['Screen setup failed: %s. ', ...
        'Try setting dbg.skipSyncTests=1 in src/config.m for debugging (NOT for real experiments).'], ME.message);
end

% Store screen timing reference (all event onsets logged relative to this)
in.scriptStart = VBLTimestamp;

% Configure screen colors (CLUT indices)
in.white = WhiteIndex(screen);
in.black = BlackIndex(screen);
in.gray = round(in.white / 2);

% Fill screen with gray background
Screen(win, 'FillRect', in.gray);

%% Compute pixels per degree (PPD) for visual angle calculations
[in, params] = computePPD(params, in, fmriMode, screen);

end
