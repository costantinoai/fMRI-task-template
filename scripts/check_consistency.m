function check_consistency()
% CHECK_CONSISTENCY Verify code consistency across the project.
%
%   Checks for:
%   - Naming conventions (function name matches filename)
%   - File organization (correct utils/ subdirectory)
%   - Error identifier format (Domain:Specific pattern)
%   - Required function headers
%   - Output invariant preservation
%
% Usage:
%   check_consistency()  % Run from repo root
%
% Exit codes:
%   0 - All checks passed
%   1 - One or more checks failed
%
% Author: fMRI Task Template Team
% Last updated: 2025

fprintf('=== Code Consistency Check ===\n\n');

passedChecks = 0;
failedChecks = 0;

%% Check 1: Function names match filenames
fprintf('[1/6] Checking function/filename consistency...\n');
mFiles = dir('utils/**/*.m');

for i = 1:numel(mFiles)
    filePath = fullfile(mFiles(i).folder, mFiles(i).name);
    [~, fileName, ~] = fileparts(mFiles(i).name);

    % Read first function line
    fid = fopen(filePath, 'r');
    if fid == -1, continue; end

    firstLine = '';
    while isempty(regexp(firstLine, '^function', 'once'))
        firstLine = fgetl(fid);
        if ~ischar(firstLine), break; end
    end
    fclose(fid);

    % Extract function name
    tokens = regexp(firstLine, 'function\s+(?:\[.*\]\s*=\s*|\w+\s*=\s*)?(\w+)\s*\(', 'tokens');
    if ~isempty(tokens)
        funcName = tokens{1}{1};
        if ~strcmp(funcName, fileName)
            fprintf('  ❌ Mismatch: %s defines function %s\n', mFiles(i).name, funcName);
            failedChecks = failedChecks + 1;
        end
    end
end
passedChecks = passedChecks + 1;
fprintf('  ✓ Function names checked\n\n');

%% Check 2: File organization
fprintf('[2/6] Checking file organization...\n');
expectedDirs = {'utils/setup', 'utils/display', 'utils/recording', 'utils/hardware', 'utils/lib'};

for i = 1:numel(expectedDirs)
    if ~exist(expectedDirs{i}, 'dir')
        fprintf('  ❌ Missing directory: %s\n', expectedDirs{i});
        failedChecks = failedChecks + 1;
    end
end
passedChecks = passedChecks + 1;
fprintf('  ✓ Directory structure verified\n\n');

%% Check 3: Error identifier format
fprintf('[3/6] Checking error identifier format...\n');
mFiles = [dir('utils/**/*.m'); dir('fMRI_task.m')];

badIdentifiers = {};
for i = 1:numel(mFiles)
    filePath = fullfile(mFiles(i).folder, mFiles(i).name);
    content = fileread(filePath);

    % Find all error() calls
    errors = regexp(content, 'error\(''([^'']+)''', 'tokens');
    for j = 1:numel(errors)
        identifier = errors{j}{1};
        % Check format: Domain:Specific
        if ~isempty(regexp(identifier, '^\w+:\w+$', 'once'))
            % Valid format
        else
            badIdentifiers{end+1} = sprintf('%s: %s', mFiles(i).name, identifier);
        end
    end
end

if ~isempty(badIdentifiers)
    fprintf('  ❌ Invalid error identifiers found:\n');
    for i = 1:numel(badIdentifiers)
        fprintf('    %s\n', badIdentifiers{i});
    end
    failedChecks = failedChecks + 1;
else
    passedChecks = passedChecks + 1;
    fprintf('  ✓ Error identifiers follow Domain:Specific pattern\n\n');
end

%% Check 4: Required headers
fprintf('[4/6] Checking function headers...\n');
mFiles = dir('utils/**/*.m');

missingHeaders = {};
for i = 1:numel(mFiles)
    filePath = fullfile(mFiles(i).folder, mFiles(i).name);
    content = fileread(filePath);

    % Check for basic header structure
    if ~contains(content, '% Inputs:') && ~contains(content, '% Input:')
        missingHeaders{end+1} = mFiles(i).name;
    end
end

if ~isempty(missingHeaders)
    fprintf('  ⚠️  Functions missing headers:\n');
    for i = 1:numel(missingHeaders)
        fprintf('    %s\n', missingHeaders{i});
    end
    fprintf('  (Warning only - not counted as failure)\n\n');
else
    passedChecks = passedChecks + 1;
    fprintf('  ✓ All functions have headers\n\n');
end

%% Check 5: Output invariants
fprintf('[5/6] Checking output invariants...\n');
invariantFiles = {'utils/recording/logEvent.m', 'utils/recording/createLogFile.m', 'utils/recording/saveAndClose.m'};

allExist = true;
for i = 1:numel(invariantFiles)
    if ~exist(invariantFiles{i}, 'file')
        fprintf('  ❌ Missing critical file: %s\n', invariantFiles{i});
        allExist = false;
    end
end

if allExist
    % Check logEvent header
    logEventContent = fileread('utils/recording/logEvent.m');
    if ~contains(logEventContent, 'EVENT_TYPE') || ...
       ~contains(logEventContent, 'EVENT_NAME') || ...
       ~contains(logEventContent, 'ACTUAL_ONSET')
        fprintf('  ❌ logEvent header format may have changed\n');
        failedChecks = failedChecks + 1;
    else
        passedChecks = passedChecks + 1;
        fprintf('  ✓ Output invariants preserved\n\n');
    end
else
    failedChecks = failedChecks + 1;
end

%% Check 6: Test coverage
fprintf('[6/6] Checking test coverage...\n');
testFiles = dir('tests/test*.m');
utilFiles = dir('utils/**/*.m');

fprintf('  Found %d test files for %d utility files\n', numel(testFiles), numel(utilFiles));
if numel(testFiles) < numel(utilFiles) * 0.5
    fprintf('  ⚠️  Test coverage may be low (<%d%% files tested)\n', 50);
else
    fprintf('  ✓ Reasonable test coverage\n');
end
passedChecks = passedChecks + 1;

%% Summary
fprintf('\n=== Summary ===\n');
fprintf('Passed: %d\n', passedChecks);
fprintf('Failed: %d\n', failedChecks);

if failedChecks == 0
    fprintf('\n✅ All consistency checks passed!\n');
    exit(0);
else
    fprintf('\n❌ %d checks failed. Please fix before committing.\n', failedChecks);
    exit(1);
end

end
