classdef testQuickCheckIntegration < matlab.unittest.TestCase
    % testQuickCheckIntegration - Integration test for quick_check workflow
    %   Validates the complete config -> params -> trial list -> image subset flow
    %   without opening PTB windows. Tests the same logic as scripts/quick_check.m

    methods(TestMethodSetup)
        function changeToRepoRoot(testCase)
            % Change to repo root before each test
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);
            oldDir = cd(repoRoot);
            testCase.addTeardown(@() cd(oldDir));
        end
    end

    methods(Test)
        function testCompleteWorkflow(testCase)
            % Full integration: config load, validation, trial list, image subset
            addpath(genpath('./utils'));
            addpath('./src');
            addpath('./scripts');

            utilsDir = './utils';
            srcDir = './src';
            cfgPath = fullfile(srcDir, 'config.m');
            stimListPath = fullfile(srcDir, 'list_of_stimuli.tsv');

            % Verify folders and files exist
            testCase.verifyTrue(exist(utilsDir, 'dir') == 7, 'utils folder must exist');
            testCase.verifyTrue(exist(srcDir, 'dir') == 7, 'src folder must exist');
            testCase.verifyTrue(exist(cfgPath, 'file') == 2, 'src/config.m must exist');
            testCase.verifyTrue(exist(stimListPath, 'file') == 2, 'src/list_of_stimuli.tsv must exist');

            % Load config in PC/dev mode
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            % Validate params (should not error)
            validateParams(params, fmriMode);

            % Create minimal input struct
            in = struct();
            in.subNum = 1;
            in.runNum = 1;
            in.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss'));

            % Build trial list
            trialList = makeTrialList(params, in);
            testCase.verifyNotEmpty(trialList, 'Trial list should not be empty');

            % Verify run distribution
            trialsPerRun = numel(trialList) / params.numRuns;
            testCase.verifyEqual(mod(numel(trialList), params.numRuns), 0, ...
                'Trials must divide evenly across runs');
            testCase.verifyGreaterThan(trialsPerRun, 0);

            % Preload image subset (first 2 non-fixation trials)
            nonFix = find(~strcmp({trialList.stimuli}, 'fixation'));
            if ~isempty(nonFix)
                subsetIdx = nonFix(1:min(2, numel(nonFix)));
                imSubset = loadImages(trialList(subsetIdx), params);

                % Verify images loaded
                testCase.verifyNotEmpty(imSubset, 'Image subset should not be empty');
                testCase.verifyEqual(numel(imSubset.image), numel(subsetIdx), ...
                    'Should load exactly the requested number of images');
            end
        end

        function testConfigFieldsPresent(testCase)
            % Verify required config fields
            addpath(genpath('./utils'));
            addpath('./src');

            cfgPath = fullfile('./src', 'config.m');
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            requiredFields = {'stimDur', 'fixDur', 'prePost', 'taskName', ...
                'numRuns', 'stimListFile', 'numRepetitions'};
            for i = 1:numel(requiredFields)
                testCase.verifyTrue(isfield(params, requiredFields{i}), ...
                    sprintf('Config must include field: %s', requiredFields{i}));
            end
        end

        function testTrialListStructure(testCase)
            % Verify trial list has expected fields
            addpath(genpath('./utils'));
            addpath('./src');

            cfgPath = fullfile('./src', 'config.m');
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            in = struct();
            in.subNum = 1;
            in.runNum = 1;

            trialList = makeTrialList(params, in);

            % Verify key fields exist
            expectedFields = {'stimuli', 'run', 'trialNb', 'idealStimOnset'};
            for i = 1:numel(expectedFields)
                testCase.verifyTrue(isfield(trialList, expectedFields{i}), ...
                    sprintf('Trial list must include field: %s', expectedFields{i}));
            end

            % Verify run numbers are valid
            runs = [trialList.run];
            testCase.verifyGreaterThanOrEqual(min(runs), 1);
            testCase.verifyLessThanOrEqual(max(runs), params.numRuns);
        end

        function testImageLoadSubset(testCase)
            % Test that image loading works with subset (no PTB required)
            addpath(genpath('./utils'));
            addpath('./src');

            cfgPath = fullfile('./src', 'config.m');
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            in = struct();
            in.subNum = 1;
            in.runNum = 1;

            trialList = makeTrialList(params, in);

            % Find non-fixation trials
            nonFix = find(~strcmp({trialList.stimuli}, 'fixation'));

            if ~isempty(nonFix)
                % Load just first trial
                subsetIdx = nonFix(1);
                imSubset = loadImages(trialList(subsetIdx), params);

                testCase.verifyEqual(numel(imSubset.image), 1, 'Should load 1 image');
                testCase.verifyNotEmpty(imSubset.image(1).im, 'Image data should not be empty');
            end
        end

        function testResizeModeConsistency(testCase)
            % Verify resize mode is set correctly
            addpath(genpath('./utils'));
            addpath('./src');

            cfgPath = fullfile('./src', 'config.m');
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            if isfield(params, 'resize') && params.resize
                testCase.verifyTrue(isfield(params, 'resizeMode'), ...
                    'When resize=true, resizeMode must be specified');

                validModes = {'visualUnits', 'pixelSize'};
                testCase.verifyTrue(ismember(params.resizeMode, validModes), ...
                    sprintf('resizeMode must be one of: %s', strjoin(validModes, ', ')));
            end
        end

        function testStimListFileReadable(testCase)
            % Verify stimulus list file can be read
            addpath(genpath('./utils'));
            addpath('./src');

            cfgPath = fullfile('./src', 'config.m');
            fmriMode = false;
            params = TaskConfig.load(cfgPath, fmriMode);

            stimListPath = params.stimListFile;
            testCase.verifyTrue(exist(stimListPath, 'file') == 2, ...
                'Stimulus list file must exist');

            % Read and verify structure
            opts = detectImportOptions(stimListPath, 'FileType', 'text', 'Delimiter', '\t');
            try
                opts.VariableNamingRule = 'preserve';
            catch
                % Older MATLAB versions
            end
            stimTable = readtable(stimListPath, opts);

            testCase.verifyTrue(ismember('stimuli', stimTable.Properties.VariableNames), ...
                'Stimulus list must contain a "stimuli" column');
            testCase.verifyGreaterThan(height(stimTable), 0, ...
                'Stimulus list must have at least one row');
        end
    end
end
