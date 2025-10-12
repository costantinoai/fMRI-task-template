function [in, params] = computePPD(params, in, fmriMode, screen)
% COMPUTEPPD Calculate pixels per degree of visual angle.
%
%   Uses either measured screen geometry (if useScreenGeometry=true) or
%   hardcoded defaults in convertVisualUnits. Adds PPD to both in and params.
%
% Inputs:
%   params   - Must include useScreenGeometry, scrWidth/scrWidthMRI/scrWidthPC,
%              scrDist/scrDistMRI/scrDistPC (if useScreenGeometry=true)
%   in       - Session info (will be updated with PPD)
%   fmriMode - If true, use MRI-specific geometry
%   screen   - PTB screen number
%
% Outputs:
%   in     - Updated with PPD field
%   params - Updated with PPD field (for utilities that only receive params)
%
% Errors:
%   Hardware:MissingGeometry - Required geometry fields not found in params
%
% Example:
%   [in, params] = computePPD(params, in, false, screen);
%
% Author: fMRI Task Template Team
% Last updated: 2025

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
