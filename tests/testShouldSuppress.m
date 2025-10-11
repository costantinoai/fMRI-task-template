classdef testShouldSuppress < matlab.unittest.TestCase
    methods(Test)
        function testNoDebounce(testCase)
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.001, 0));
        end
        function testSuppressWithinWindow(testCase)
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyTrue(shouldSuppress(last, 10, 1.05, 0.1));
        end
        function testDoNotSuppressDifferentKey(testCase)
            last = struct('code', 11, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.05, 0.1));
        end
        function testDoNotSuppressOutsideWindow(testCase)
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.2, 0.1));
        end
    end
end

