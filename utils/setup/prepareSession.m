function in = prepareSession(subNum, runNum, debugMode)
% PREPARESESSION Create session info struct and output directory.
%
%   Builds the 'in' struct with subject/run info, timestamp, and result directory.
%   Creates output directory if not in debug mode.
%
% Inputs:
%   subNum    - Subject number (positive integer)
%   runNum    - Run number (positive integer)
%   debugMode - Boolean flag (true = no output directory created)
%
% Outputs:
%   in - Session info struct with fields:
%        subNum    - Subject number
%        runNum    - Run number
%        timestamp - Current datetime as 'yyyy-MM-dd_HHmmss'
%        resDir    - Path to data/sub-XX/ output directory
%
% Errors:
%   Session:InvalidSubNum - Subject number must be positive integer
%   Session:InvalidRunNum - Run number must be positive integer
%
% Example:
%   in = prepareSession(1, 2, false);
%   disp(in.resDir);  % Shows: /path/to/repo/data/sub-01
%
% Author: fMRI Task Template Team
% Last updated: 2024

% Validate subject number
if ~isnumeric(subNum) || subNum < 1 || mod(subNum, 1) ~= 0
    error('Session:InvalidSubNum', ['Subject number must be a positive integer. ', ...
        'Received: %s. Check your input in fMRI_task.m or inputdlg.'], mat2str(subNum));
end

% Validate run number
if ~isnumeric(runNum) || runNum < 1 || mod(runNum, 1) ~= 0
    error('Session:InvalidRunNum', ['Run number must be a positive integer. ', ...
        'Received: %s. Check your input in fMRI_task.m or inputdlg.'], mat2str(runNum));
end

% Build session info struct
in = struct();
in.subNum = subNum;
in.runNum = runNum;
in.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));

% Construct subject-specific output directory path
subID = ['sub-' zeroFill(num2str(subNum), 2)];
in.resDir = fullfile(pwd, 'data', subID);

% Create directory if not in debug mode
if ~debugMode && ~exist(in.resDir, 'dir')
    mkdir(in.resDir);
end

end
