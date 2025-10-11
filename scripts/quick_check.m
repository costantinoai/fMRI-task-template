function quick_check()
% QUICK_CHECK Minimal validation of the fMRI task template without opening PTB windows.
%   - Verifies presence of required folders and files
%   - Loads MATLAB config via TaskConfig
%   - Generates a trial list and preloads a small image subset
%   - Prints a brief summary to the console
%
% Usage: run `quick_check` from the repo root in MATLAB.

clc;
fprintf('=== fMRI task template: quick check ===\n');

% Paths
utilsDir = './utils';
srcDir   = './src';
cfgPath  = fullfile(srcDir, 'config.m');
stimList = fullfile(srcDir, 'list_of_stimuli.tsv');

% Check folders
assert(exist(utilsDir, 'dir') == 7, 'Missing utils folder');
assert(exist(srcDir, 'dir') == 7, 'Missing src folder');

% Add to path
addpath(genpath(utilsDir)); % Recursively add utils/ subdirectories
addpath(srcDir);

% Check files
assert(exist(cfgPath,'file')==2, 'Missing src/config.m');
assert(exist(stimList, 'file') == 2, 'Missing src/list_of_stimuli.tsv');

% Load config (PC/dev mode)
fmriMode = false;
params = TaskConfig.load(cfgPath, fmriMode);
validateParams(params, fmriMode);

% Minimal in-struct
in = struct();
in.subNum = 1; in.runNum = 1; in.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));

% Build trial list
trialList = makeTrialList(params, in);
assert(~isempty(trialList), 'Empty trial list');

% Preview run split
trialsPerRun = numel(trialList) / params.numRuns;
fprintf('Config OK. Trials: %d (%d/run), Runs: %d\n', numel(trialList), trialsPerRun, params.numRuns);

% Preload a small subset of images (first 2 non-fixation trials). This
% reduces overall memory usage while still catching common I/O problems.
nonFix = find(~strcmp({trialList.stimuli}, 'fixation'));
subsetIdx = nonFix(1:min(2, numel(nonFix)));
imSubset = loadImages(trialList(subsetIdx), params); %#ok<NASGU>
modeStr = 'n/a';
if isfield(params,'resizeMode'), modeStr = params.resizeMode; end
fprintf('Image loading OK (subset %d). Resize=%d, Mode=%s\n', numel(subsetIdx), params.resize, modeStr);

% Key codes summary
if isfield(params, 'respKeysCode')
    fprintf('Response key codes (decimal): [%s]\n', num2str(params.respKeysCode));
end
if isfield(params, 'buttonDecimalCodes')
    fprintf('Button decimal codes (up to 10): [%s]\n', num2str(params.buttonDecimalCodes));
end

fprintf('Quick check completed successfully.\n');

end
