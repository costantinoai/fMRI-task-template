function image = getTrialImage(runImMat, trialIdx)
% GETTRIALIMAGE Safely extract trial image from preloaded matrix
%
%   Handles empty matrices and out-of-bounds indices gracefully.
%   Returns empty array for fixation trials or when image not available.
%
% Inputs:
%   runImMat  - Cell array or struct array of preloaded images
%   trialIdx  - Trial index (1-based)
%
% Outputs:
%   image     - Image matrix/struct or [] if not available
%
% Example:
%   img = getTrialImage(runImMat, 5);
%
% See also: loadImages, displayTrial
%
% Author: fMRI Task Template Team
% Last updated: 2025

if isempty(runImMat) || trialIdx > numel(runImMat)
    image = [];
else
    image = runImMat(trialIdx);
end

end
