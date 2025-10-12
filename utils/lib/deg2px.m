function px = deg2px(degValue, params, in)
% DEG2PX Convert degrees of visual angle to pixels.
%
%   Single source of truth for visual angle conversion. Uses either
%   measured PPD from screen geometry or hardcoded defaults.
%
% Inputs:
%   degValue - Visual angle in degrees
%   params   - Experiment parameters (useScreenGeometry)
%   in       - Session info (PPD field if useScreenGeometry=true)
%
% Outputs:
%   px - Value in pixels (rounded to integer)
%
% Example:
%   fixSize = deg2px(0.5, params, in);  % 0.5 degrees to pixels
%
% Author: fMRI Task Template Team
% Last updated: 2025

if isfield(params, 'useScreenGeometry') && params.useScreenGeometry && isfield(in, 'PPD')
    % Use measured pixels per degree from screen geometry
    px = round(degValue * in.PPD);
else
    % Use hardcoded defaults in convertVisualUnits
    px = round(convertVisualUnits(degValue, 'deg', 'px'));
end

end
