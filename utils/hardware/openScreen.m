function [win, winRect, screen, in] = openScreen(debugMode, dbg, in)
% OPENSCREEN Open PTB window and configure screen colors.
%
%   Opens PTB graphics window (fullscreen or windowed based on mode),
%   gets color indices, fills with gray, and stores timing reference.
%
% Inputs:
%   debugMode - If true, open windowed mode
%   dbg       - Debug options (windowScale, skipSyncTests, releaseSkipSyncTests)
%   in        - Session info (will be updated with scriptStart, colors)
%
% Outputs:
%   win     - PTB window pointer
%   winRect - Screen rectangle [x1 y1 x2 y2]
%   screen  - Screen number
%   in      - Updated with scriptStart, white, gray, black
%
% Errors:
%   Hardware:ScreenFailed - Screen setup failed
%
% Example:
%   [win, winRect, screen, in] = openScreen(true, dbg, in);
%
% Author: fMRI Task Template Team
% Last updated: 2025

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

% Store screen timing reference (all event onsets logged relative to this)
in.scriptStart = VBLTimestamp;

% Configure screen colors (CLUT indices)
in.white = WhiteIndex(screen);
in.black = BlackIndex(screen);
in.gray = round(in.white / 2);

% Fill screen with gray background
Screen(win, 'FillRect', in.gray);

end
