function saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, varargin)
% SAVEANDCLOSE - Save data and close resources.
%
%    Syntax:
%      SaveAndClose(params, in, debugMode, runTrials, runImMat, logFile)
%
%    Inputs:
%      - params: Struct containing experiment parameters
%      - in: Struct containing run information.
%      - runTrials: Array storing info about trials and responses.
%      - runImMat: Struct storing info about the images (one image per row).
%      - logFile: File identifier of the log file.
%
%     Description:
%       This function saves relevant variables and files, and closes 
%       resources such as the task screen, log file, and input devices. The
%       variables runTrials and runImMat will be saved in debugMode is
%       turned off.
%
%   Example:
%       SaveAndClose(params, in, runTrials, runImMat, logFile)
% 
%   Author
%   Andrea Costantino [16/6/23]
% 
%   Last updated
%   Tim Maniquet [22/4/24]

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
    runInfo = ['sub-' zeroFill(in.subNum, 2) '_run-' zeroFill(num2str(in.runNum), 2)];
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
