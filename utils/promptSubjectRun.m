function [subNum, runNum] = promptSubjectRun(params, debugMode)
% PROMPTSUBJECTRUN Get subject and run numbers (interactive or defaults).
%
%   In debug mode, returns defaults (subNum=99, runNum=1).
%   In production, shows input dialog for experimenter to enter values.
%
% Inputs:
%   params    - Must include numRuns field for validation prompt
%   debugMode - If true, skip dialog and use defaults
%
% Outputs:
%   subNum - Subject number (integer)
%   runNum - Run number (integer)
%
% Example:
%   [subNum, runNum] = promptSubjectRun(params, false);  % Show dialog
%   [subNum, runNum] = promptSubjectRun(params, true);   % Use defaults
%
% Author: Andrea Costantino

if debugMode
    % Use defaults for quick testing
    answer = {'99', '1'};
else
    % Show input dialog for experimenter
    prompt = {'Subject number', sprintf('Run number (out of %d)', params.numRuns)};
    answer = inputdlg(prompt, 'Session Info', 1, {'', ''});

    % Handle cancel button
    if isempty(answer)
        error('Session:Cancelled', 'Session setup cancelled by user.');
    end
end

% Convert to numbers
subNum = str2double(answer{1});
runNum = str2double(answer{2});

% Validate
if isnan(subNum) || isnan(runNum)
    error('Session:InvalidInput', 'Subject and run numbers must be numeric.');
end

if runNum < 1 || runNum > params.numRuns
    error('Session:InvalidRun', 'Run number must be between 1 and %d.', params.numRuns);
end

end
