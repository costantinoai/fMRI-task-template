classdef testMakeTrialList < matlab.unittest.TestCase
    methods(Test)
        function testDivisible(testCase)
            addpath(genpath('./utils')); addpath('./src');
            params = struct();
            params.stimListFile = 'src/list_of_stimuli.tsv';
            params.numRepetitions = 1;
            params.numRuns = 2;
            params.prePost = 1;
            params.stimDur = 0.5;
            params.fixDur = 0.5;
            params.trialDur = params.stimDur + params.fixDur;
            params.stimRandomization = 'run';
            % Minimal key mapping for determineButtonMapping
            params.respKey1Code = 49; params.respKey2Code = 50; % '1','2'
            params.respInst1 = 'left'; params.respInst2 = 'right';
            in.subNum = 1; in.runNum = 1;
            tl = makeTrialList(params, in);
            testCase.verifyGreaterThan(numel(tl), 0);
            runs = [tl.run];
            testCase.verifyEqual(min(runs), 1);
            testCase.verifyEqual(max(runs), params.numRuns);
        end
        function testNotDivisible(testCase)
            addpath(genpath('./utils')); addpath('./src');
            params = struct();
            params.stimListFile = 'src/list_of_stimuli.tsv';
            params.numRepetitions = 1;
            params.numRuns = 5; % 24 stimuli not divisible by 5
            params.prePost = 1; params.stimDur = 0.5; params.fixDur = 0.5; params.trialDur = 1;
            params.respKey1Code = 49; params.respKey2Code = 50; params.respInst1='L'; params.respInst2='R';
            in.subNum = 1;
            testCase.verifyError(@() makeTrialList(params, in), 'makeTrialList:InvalidRuns');
        end
    end
end

