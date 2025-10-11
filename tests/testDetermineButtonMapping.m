classdef testDetermineButtonMapping < matlab.unittest.TestCase
    methods(Test)
        function testEvenSubOddRun(testCase)
            params.respKey1Code = 1; params.respKey2Code = 2;
            params.respInst1 = 'A'; params.respInst2 = 'B';
            m = determineButtonMapping(params, 2, 1);
            testCase.verifyEqual(m.mapNumber, 1);
            testCase.verifyEqual(m.respKey1Code, 1);
            testCase.verifyEqual(m.respKey2Code, 2);
        end
        function testEvenSubEvenRun(testCase)
            params.respKey1Code = 1; params.respKey2Code = 2;
            params.respInst1 = 'A'; params.respInst2 = 'B';
            m = determineButtonMapping(params, 2, 2);
            testCase.verifyEqual(m.mapNumber, 2);
            testCase.verifyEqual(m.respKey1Code, 2);
            testCase.verifyEqual(m.respKey2Code, 1);
        end
        function testOddSubOddRun(testCase)
            params.respKey1Code = 1; params.respKey2Code = 2;
            params.respInst1 = 'A'; params.respInst2 = 'B';
            m = determineButtonMapping(params, 1, 1);
            testCase.verifyEqual(m.mapNumber, 2);
        end
        function testDeterministicOutput(testCase)
            % Verify output is deterministic (same inputs -> same outputs)
            % Important for caching: call once per run, not per trial
            params.respKey1Code = 102; params.respKey2Code = 106;
            params.respInst1 = 'left'; params.respInst2 = 'right';

            % Call multiple times with same inputs
            m1 = determineButtonMapping(params, 5, 3);
            m2 = determineButtonMapping(params, 5, 3);
            m3 = determineButtonMapping(params, 5, 3);

            % All should be identical
            testCase.verifyEqual(m1.mapNumber, m2.mapNumber);
            testCase.verifyEqual(m1.respKey1Code, m2.respKey1Code);
            testCase.verifyEqual(m2.mapNumber, m3.mapNumber);
            testCase.verifyEqual(m2.respKey1Code, m3.respKey1Code);
        end
        function testAllFieldsPresent(testCase)
            % Verify all required output fields exist
            params.respKey1Code = 49; params.respKey2Code = 50;
            params.respInst1 = 'one'; params.respInst2 = 'two';
            m = determineButtonMapping(params, 4, 2);

            testCase.verifyTrue(isfield(m, 'mapNumber'));
            testCase.verifyTrue(isfield(m, 'respKey1Code'));
            testCase.verifyTrue(isfield(m, 'respKey2Code'));
            testCase.verifyTrue(isfield(m, 'respInst1'));
            testCase.verifyTrue(isfield(m, 'respInst2'));
        end
    end
end

