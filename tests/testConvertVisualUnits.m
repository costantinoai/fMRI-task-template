classdef testConvertVisualUnits < matlab.unittest.TestCase
    methods(Test)
        function testRoundTripDeg(testCase)
            x = 5; % deg
            px = convertVisualUnits(x, 'deg', 'px');
            back = convertVisualUnits(px, 'px', 'deg');
            testCase.verifyLessThan(abs(back - x), 1e-6);
        end
        function testPxToDegConsistency(testCase)
            px = 100;
            deg = convertVisualUnits(px, 'px', 'deg');
            testCase.verifyGreaterThan(deg, 0);
        end
    end
end

