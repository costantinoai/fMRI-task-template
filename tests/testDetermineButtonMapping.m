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
    end
end

