function [params, paths, dbg] = initializeSession(debugMode, fmriMode)
% INITIALIZESESSION Consolidate all session initialization boilerplate.
%
%   Single entry point for environment setup, config loading, and debug
%   options. Reduces fMRI_task.m to only study-specific choices.
%
% Inputs:
%   debugMode - If true, use windowed mode and PC input codes
%   fmriMode  - If true, use MRI screen geometry and scanner input codes
%
% Outputs:
%   params - Validated experiment parameters
%   paths  - Struct with canonical paths (utils, src, scripts, root)
%   dbg    - Debug options struct (writeLogs, saveMat, overlay, etc.)
%
% Side effects:
%   - Adds utils/ to MATLAB path
%   - Sets appdata flags for pretty console in debug mode
%   - Validates params structure
%
% Example:
%   [params, paths, dbg] = initializeSession(true, false);  % Debug mode
%
% Author: fMRI Task Template Team
% Last updated: 2025

%% Environment setup
% Add utils to path first (prepareEnvironment itself is in utils/)
addpath(genpath('./utils'));

% Check folders exist and add to MATLAB path
paths = prepareEnvironment();

%% Load and configure parameters
% Load experiment configuration
cfgPath = fullfile(paths.src, 'config.m');
params = TaskConfig.load(cfgPath, fmriMode);

% Debug policy: when debugMode is true, always use PC codes (buttons/trigger/escape)
if debugMode
    % Enable pretty console output in debug mode for better readability
    setappdata(0, 'LOG_PRETTY_CONSOLE', true);

    if isfield(params,'buttonsPC') && ~isempty(params.buttonsPC)
        params.buttons = params.buttonsPC;
        if numel(params.buttonsPC) >= 2
            params.respKey1Code = params.buttonsPC(1);
            params.respKey2Code = params.buttonsPC(2);
        end
    end
    if isfield(params,'triggerKeyPCCode') && ~isempty(params.triggerKeyPCCode)
        params.triggerKeyCode = params.triggerKeyPCCode;
    end
    if isfield(params,'escapeKeyPCCode') && ~isempty(params.escapeKeyPCCode)
        params.escapeKeyCode = params.escapeKeyPCCode;
    end
end

% Validate parameters
validateParams(params, fmriMode);

%% Debug options
% Defaults + optional overrides from config.debug
dbg = struct('writeLogs', false, 'saveMat', false, 'windowScale', 0.9, ...
             'slowMoFactor', 1.0, 'overlay', false, 'skipSyncTests', [], ...
             'warnOnDrift', false, 'driftWarnMs', 10, 'rngSeed', [], ...
             'releaseSkipSyncTests', []);

if isfield(params, 'debug') && isstruct(params.debug)
    fns = fieldnames(params.debug);
    for ii=1:numel(fns)
        dbg.(fns{ii}) = params.debug.(fns{ii});
    end
end

% In debug mode, suppress raw TSV console output (pretty format will be shown instead)
if debugMode
    setappdata(0, 'LOG_SILENT_CONSOLE', true);
    setappdata(0, 'LOG_PRETTY_HEADER_PRINTED', false);
end

end
