classdef testMakeTrialListRandomization < matlab.unittest.TestCase
    % testMakeTrialListRandomization - Test trial randomization modes
    %   Validates 'run' (within-run randomization) vs 'all' (across-run randomization)
    %   and ensures no randomization when stimRandomization is absent.

    methods(Test)
        function testNoRandomization(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % Create deterministic stimuli list
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\n');
            fprintf(fid, 'A\n');
            fprintf(fid, 'B\n');
            fprintf(fid, 'C\n');
            fprintf(fid, 'D\n');
            fclose(fid);

            params = struct();
            params.stimListFile = tmpTsv;
            params.numRepetitions = 1;
            params.numRuns = 2;
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = 1;
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'L'; params.respInst2 = 'R';
            % No stimRandomization field
            in.subNum = 1;

            tl = makeTrialList(params, in);

            % Order should be preserved (convert to char for comparison)
            stims = {tl.stimuli};
            testCase.verifyEqual(char(stims{1}), 'A');
            testCase.verifyEqual(char(stims{2}), 'B');
            testCase.verifyEqual(char(stims{3}), 'C');
            testCase.verifyEqual(char(stims{4}), 'D');

            rmdir(tmpDir, 's');
        end

        function testRandomizationRun(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % Test 'run' mode: randomize within each run
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\n');
            for i = 1:20
                fprintf(fid, 'img%d\n', i);
            end
            fclose(fid);

            params = struct();
            params.stimListFile = tmpTsv;
            params.numRepetitions = 1;
            params.numRuns = 2; % 10 trials per run
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = 1;
            params.stimRandomization = 'run';
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'L'; params.respInst2 = 'R';
            in.subNum = 1;

            % Run multiple times to ensure randomization occurs
            differentOrders = false;
            firstOrder = {};
            for attempt = 1:5
                tl = makeTrialList(params, in);
                stims = {tl.stimuli};
                if isempty(firstOrder)
                    firstOrder = stims;
                elseif ~isequal(firstOrder, stims)
                    differentOrders = true;
                    break;
                end
            end

            testCase.verifyTrue(differentOrders, ...
                'Randomization should produce different orders across runs');

            % Verify run counts preserved (10 trials per run)
            tl = makeTrialList(params, in);
            runs = [tl.run];
            testCase.verifyEqual(sum(runs == 1), 10);
            testCase.verifyEqual(sum(runs == 2), 10);

            rmdir(tmpDir, 's');
        end

        function testRandomizationAll(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % Test 'all' mode: randomize across all runs
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\n');
            for i = 1:20
                fprintf(fid, 'img%d\n', i);
            end
            fclose(fid);

            params = struct();
            params.stimListFile = tmpTsv;
            params.numRepetitions = 1;
            params.numRuns = 2;
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = 1;
            params.stimRandomization = 'all'; % Randomize across all runs
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'L'; params.respInst2 = 'R';
            in.subNum = 1;

            % Run multiple times to ensure randomization occurs
            differentOrders = false;
            firstOrder = {};
            for attempt = 1:5
                tl = makeTrialList(params, in);
                stims = {tl.stimuli};
                if isempty(firstOrder)
                    firstOrder = stims;
                elseif ~isequal(firstOrder, stims)
                    differentOrders = true;
                    break;
                end
            end

            testCase.verifyTrue(differentOrders, ...
                'Randomization across all runs should produce different orders');

            % Verify total trial count
            tl = makeTrialList(params, in);
            testCase.verifyEqual(numel(tl), 20);

            rmdir(tmpDir, 's');
        end

        function testRunModePreservesPerRunCounts(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % With 'run' randomization, each run should have equal trials
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\tcondition\n');
            fprintf(fid, 'A\tX\n');
            fprintf(fid, 'B\tY\n');
            fprintf(fid, 'C\tX\n');
            fprintf(fid, 'D\tY\n');
            fprintf(fid, 'E\tX\n');
            fprintf(fid, 'F\tY\n');
            fclose(fid);

            params = struct();
            params.stimListFile = tmpTsv;
            params.numRepetitions = 1;
            params.numRuns = 2; % 3 trials per run
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = 1;
            params.stimRandomization = 'run';
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'L'; params.respInst2 = 'R';
            in.subNum = 1;

            tl = makeTrialList(params, in);

            % Each run should have exactly 3 trials
            runs = [tl.run];
            testCase.verifyEqual(sum(runs == 1), 3);
            testCase.verifyEqual(sum(runs == 2), 3);

            rmdir(tmpDir, 's');
        end
    end
end
