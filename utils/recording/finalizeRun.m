function finalizeRun(params, in, debugMode, runTrials, runImMat, logFile, saveMat)
% FINALIZERUN Save data and close PTB objects.
%
%   Wraps saveAndClose with proper error handling. Logs END event,
%   saves .mat file (if enabled), and closes log file handle.
%
% Inputs:
%   params    - Experiment parameters
%   in        - Session info (scriptStart, subNum, runNum, etc.)
%   debugMode - If true, skip saving unless saveMat=true
%   runTrials - Trial list with responses and timings
%   runImMat  - Preloaded images (or [] if on-demand)
%   logFile   - Log file handle (1 for console, FID otherwise)
%   saveMat   - Debug option: force save even in debugMode
%
% Errors:
%   File:CannotSave - Cannot save .mat file to output directory
%
% Example:
%   finalizeRun(params, in, debugMode, runTrials, runImMat, logFile, dbg.saveMat);
%
% Side effects:
%   - Writes END event to log
%   - Closes log file (if not console)
%   - Saves .mat file to data/sub-XX/ (unless debugMode and not saveMat)
%   - Calls sca (Screen Close All) via saveAndClose
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Log end of run if timing info exists
if exist('in', 'var') && isstruct(in) && isfield(in, 'scriptStart')
    logEvent(logFile, 'END', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');
end

% Save data and close PTB objects
try
    saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, saveMat);
catch ME
    % Still try to close PTB window
    try
        sca;
    catch
    end

    error('File:CannotSave', ...
        ['Failed to save run data.\n', ...
         'Ensure output directory %s exists and is writable.\n', ...
         'Original error: %s'], ...
        in.resDir, ME.message);
end

end
