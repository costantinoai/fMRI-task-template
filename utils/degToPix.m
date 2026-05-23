function px = degToPix(deg, params)
% DEGTOPIX Convert a size in degrees of visual angle to pixels using the screen
% geometry declared in params, instead of convertVisualUnits' hardcoded defaults.
%
%   This is the single place that maps visual degrees to pixels, so the
%   conversion follows the actual screen distance and width selected for the
%   current mode (MRI vs PC) rather than always assuming the scanner values.
%
%   Notes:
%   - Presentation resolution defaults to 1920x1080 (the scanner display) and
%     can be overridden via params.scrResX / params.scrResY. Resize happens
%     before the window opens, so the resolution is taken from params, not the
%     live window.
%   - Square pixels are assumed (physical height derived from width and
%     resolution); for the reference geometry this yields exactly the same
%     pixels as the previous hardcoded defaults.
%
%   Inputs:
%   - deg:    size(s) in degrees of visual angle (scalar or array).
%   - params: must contain scrDist (mm) and scrWidth (mm); optional scrResX/scrResY.
%
%   Author
%   Andrea Costantino

% Presentation resolution (scanner default; overridable via params)
resX = 1920;
resY = 1080;
if isfield(params, 'scrResX') && ~isempty(params.scrResX), resX = params.scrResX; end
if isfield(params, 'scrResY') && ~isempty(params.scrResY), resY = params.scrResY; end

% Physical screen height (mm) from the declared width, assuming square pixels
sizeYmm = params.scrWidth * resY / resX;

% Delegate the actual conversion, now driven by params geometry
px = convertVisualUnits(deg, 'deg', 'px', params.scrDist, resX, resY, params.scrWidth, sizeYmm);

end
