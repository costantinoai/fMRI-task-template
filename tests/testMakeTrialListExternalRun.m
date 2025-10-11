classdef testMakeTrialListExternalRun < matlab.unittest.TestCase
    % testMakeTrialListExternalRun - Test preservation of external run column
    %   Validates that when list_of_stimuli.tsv includes a 'run' column,
    %   makeTrialList preserves it instead of generating run numbers.

    methods(Test)
        function testExternalRunPreserved(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % Create a temporary TSV with explicit run column
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\trun\n');
            fprintf(fid, 'img1.png\t1\n');
            fprintf(fid, 'img2.png\t1\n');
            fprintf(fid, 'img3.png\t2\n');
            fprintf(fid, 'img4.png\t2\n');
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
            in.subNum = 1;

            tl = makeTrialList(params, in);

            % Verify external run numbers are preserved
            runs = [tl.run];
            testCase.verifyEqual(runs(1), 1, 'First trial should be run 1');
            testCase.verifyEqual(runs(2), 1, 'Second trial should be run 1');
            testCase.verifyEqual(runs(3), 2, 'Third trial should be run 2');
            testCase.verifyEqual(runs(4), 2, 'Fourth trial should be run 2');

            rmdir(tmpDir, 's');
        end

        function testNoRunColumnGeneratesRuns(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % Create a temporary TSV without run column
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\n');
            fprintf(fid, 'img1.png\n');
            fprintf(fid, 'img2.png\n');
            fprintf(fid, 'img3.png\n');
            fprintf(fid, 'img4.png\n');
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
            in.subNum = 1;

            tl = makeTrialList(params, in);

            % Verify runs are auto-generated evenly
            runs = [tl.run];
            testCase.verifyEqual(runs(1), 1);
            testCase.verifyEqual(runs(2), 1);
            testCase.verifyEqual(runs(3), 2);
            testCase.verifyEqual(runs(4), 2);

            rmdir(tmpDir, 's');
        end

        function testExternalRunWithRepetitions(testCase)
            addpath(genpath('./utils')); addpath('./src');

            % External run column should be duplicated with repetitions
            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.onFailure(@() rmdir(tmpDir, 's'));

            tmpTsv = fullfile(tmpDir, 'test_stim.tsv');
            fid = fopen(tmpTsv, 'w');
            fprintf(fid, 'stimuli\trun\n');
            fprintf(fid, 'img1.png\t1\n');
            fprintf(fid, 'img2.png\t2\n');
            fclose(fid);

            params = struct();
            params.stimListFile = tmpTsv;
            params.numRepetitions = 2; % Repeat twice
            params.numRuns = 2;
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = 1;
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'L'; params.respInst2 = 'R';
            in.subNum = 1;

            tl = makeTrialList(params, in);

            % Should have 4 trials total (2 stimuli x 2 repetitions)
            testCase.verifyEqual(numel(tl), 4);

            % External run pattern should be replicated
            runs = [tl.run];
            testCase.verifyEqual(sum(runs == 1), 2, 'Should have 2 run-1 trials');
            testCase.verifyEqual(sum(runs == 2), 2, 'Should have 2 run-2 trials');

            rmdir(tmpDir, 's');
        end
    end
end
