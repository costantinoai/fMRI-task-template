function paths = prepareEnvironment()
% PREPAREENVIRONMENT Verify required folders exist and add to MATLAB path.
%
%   Checks for utils/, src/, scripts/ directories and adds them to path.
%   Fails fast with actionable error message if folders are missing.
%
% Outputs:
%   paths - Struct with canonical paths: utils, src, scripts, root
%
% Errors:
%   Path:MissingUtils  - utils/ folder not found
%   Path:MissingSrc    - src/ folder not found
%
% Example:
%   paths = prepareEnvironment();
%   disp(paths.src);  % Show path to src/ directory
%
% Author: fMRI Task Template Team
% Last updated: 2024

% Define expected directories
utilsDir = './utils';
srcDir = './src';
scriptsDir = './scripts';

% Check utils/ (required)
if ~exist(utilsDir, 'dir')
    error('Path:MissingUtils', ['Missing folder %s. ', ...
        'Make sure you are running from the repository root (the folder containing fMRI_task.m).'], utilsDir);
end

% Check src/ (required)
if ~exist(srcDir, 'dir')
    error('Path:MissingSrc', ['Missing folder %s. ', ...
        'Create it with config.m, list_of_stimuli.tsv, and stimuli/ subdirectory. ', ...
        'See README.md for setup instructions.'], srcDir);
end

% Check scripts/ (optional - contains helper utilities)
if ~exist(scriptsDir, 'dir')
    warning('Path:MissingScripts', ...
        'Optional folder %s not found. Helper scripts (quick_check, list_devices) will not be available.', scriptsDir);
end

% Add to MATLAB path
addpath(fullfile(pwd, srcDir));
addpath(genpath(fullfile(pwd, utilsDir))); % Recursive: includes setup/, display/, etc.
if exist(scriptsDir, 'dir')
    addpath(fullfile(pwd, scriptsDir));
end

% Return canonical paths
paths = struct();
paths.utils = fullfile(pwd, utilsDir);
paths.src = fullfile(pwd, srcDir);
paths.scripts = fullfile(pwd, scriptsDir);
paths.root = pwd;

end
