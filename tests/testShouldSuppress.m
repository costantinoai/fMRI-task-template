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
        function testEmptyLastLog(testCase)
            % No previous key logged
            testCase.verifyFalse(shouldSuppress([], 10, 1.0, 0.1));
        end
        function testExactWindowBoundary(testCase)
            % At exact debounce boundary (inclusive)
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyTrue(shouldSuppress(last, 10, 1.1, 0.1));
        end
        function testJustOutsideWindow(testCase)
            % Just outside debounce window
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.1001, 0.1));
        end
        function testZeroDebounceAlwaysAllows(testCase)
            % Zero debounce means never suppress (even same key)
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.001, 0));
        end
        function testNegativeDebounceAlwaysAllows(testCase)
            % Negative debounce treated as disabled
            last = struct('code', 10, 'time', 1.0);
            testCase.verifyFalse(shouldSuppress(last, 10, 1.001, -0.05));
        end
    end
end

