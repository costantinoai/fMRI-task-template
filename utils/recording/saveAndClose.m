function saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, varargin)
% SAVEANDCLOSE Save data and close PTB objects.
%
%   Logs END event, saves .mat file (if enabled), and closes log file handle.
%
% Inputs:
%   params    - Experiment parameters
%   in        - Session info (scriptStart, subNum, runNum, etc.)
%   debugMode - If true, skip saving unless saveMat=true
%   runTrials - Trial list with responses and timings
%   runImMat  - Preloaded images (or [] if on-demand)
%   logFile   - Log file handle (1 for console, FID otherwise)
%   saveMat   - (Optional) Debug option: force save even in debugMode
%
% Errors:
%   File:CannotSave - Cannot save .mat file to output directory
%
% Example:
%   saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, dbg.saveMat);
%
% Side effects:
%   - Writes END event to log
%   - Closes log file (if not console)
%   - Saves .mat file to data/sub-XX/ (unless debugMode and not saveMat)
%   - Calls sca (Screen Close All)
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Log end of run if timing info exists
if exist('in', 'var') && isstruct(in) && isfield(in, 'scriptStart')
    logEvent(logFile, 'END', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');
end

% Show the mouse cursor again
ShowCursor;

% Close all open Psychtoolbox screens
Screen('CloseAll');

% Enable character listening again
ListenChar(0);

% Release keyboard queues (both default and device-specific if any)
try, KbQueueRelease(); catch, end

% Optional override to save in debug
forceSave = false;
if ~isempty(varargin)
    forceSave = logical(varargin{1});
end

% If we're not in debug mode (or forced), close the log file and save the run data
if debugMode ~= 1 || forceSave
    try
        % Close the log file
        if ~isempty(logFile)
            fclose(logFile);
        end
    catch
        % Ensure we don't crash on fclose
    end

    % Generate a run info tag in the format "sub-xx_run-xx"
    runInfo = sprintf('sub-%02d_run-%02d', in.subNum, in.runNum);
    % Use this tag to generate a unique identifier for the run data
    dataName = fullfile(in.resDir, [dateTimeStr '_' runInfo '_task-' params.taskName '.mat']);
    try
        % Save the run data using the unique identifier
        save(dataName, 'params', 'in', 'runTrials', 'runImMat', '-v7.3');
    catch ME
        warning('Save:Failed', 'Failed to save run data to %s: %s', dataName, ME.message);
    end
end

end
