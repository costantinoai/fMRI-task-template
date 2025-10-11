classdef testAdjustFixationDuration < matlab.unittest.TestCase
    methods(Test)
        function testAhead(testCase)
            params.fixDur = 1.0;
            rt.run = 1; rt.trialNb = 1; rt.idealStimOnset = 10; rt.stimOnset = 9.9;
            runTrials = rt;
            out = adjustFixationDuration(runTrials, 1, params);
            testCase.verifyGreaterThan(out, params.fixDur);
        end
        function testBehind(testCase)
            params.fixDur = 1.0;
            rt.run = 1; rt.trialNb = 1; rt.idealStimOnset = 10; rt.stimOnset = 10.1;
            runTrials = rt;
            out = adjustFixationDuration(runTrials, 1, params);
            testCase.verifyLessThan(out, params.fixDur);
        end
        function testEqual(testCase)
            params.fixDur = 1.0;
            rt.run = 1; rt.trialNb = 1; rt.idealStimOnset = 10; rt.stimOnset = 10.0;
            runTrials = rt;
            out = adjustFixationDuration(runTrials, 1, params);
            testCase.verifyEqual(out, params.fixDur);
        end
    end
end

