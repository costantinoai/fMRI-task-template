function logFile = initLogging(params, in, debugMode, dbg)
% INITLOGGING Create log file and write header row.
%
%   Centralizes logging initialization: determines output destination
%   (file vs console), creates log file with proper naming, and writes
%   the TSV header row.
%
% Inputs:
%   params    - Experiment parameters (taskName)
%   in        - Session info (subNum, runNum, timestamp, resDir)
%   debugMode - If true and dbg.writeLogs=false, log to console (stdout=1)
%   dbg       - Debug options struct (writeLogs field)
%
% Outputs:
%   logFile - File handle (1 for console, integer FID otherwise)
%
% Errors:
%   File:CannotCreate - Cannot create log file in output directory
%
% Example:
%   logFile = initLogging(params, in, debugMode, dbg);
%   logEvent(logFile, 'START', '-', dateTimeStr, '-', 0, '-', '-');
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Determine logging destination based on debug mode and config
if debugMode && isfield(dbg, 'writeLogs') && ~dbg.writeLogs
    % Log to console (stdout)
    logFile = 1;
else
    % Create log file in output directory
    try
        logFile = createLogFile(params, in);
    catch ME
        error('File:CannotCreate', ...
            ['Cannot create log file in %s.\n', ...
             'Ensure output directory exists and is writable.\n', ...
             'Original error: %s'], ...
            in.resDir, ME.message);
    end
end

% Write TSV header row
logEvent(logFile, 'EVENT_TYPE', 'EVENT_NAME', 'DATETIME', 'EXP_ONSET', ...
    'ACTUAL_ONSET', 'DELTA', 'EVENT_ID');

end
