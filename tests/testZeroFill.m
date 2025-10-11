classdef testZeroFill < matlab.unittest.TestCase
    methods(Test)
        function testBasic(testCase)
            import matlab.unittest.constraints.IsEqualTo
            testCase.verifyThat(zeroFill(4,2), IsEqualTo('04'));
            testCase.verifyThat(zeroFill(1,1), IsEqualTo('1'));
            testCase.verifyThat(zeroFill(32,5), IsEqualTo('00032'));
        end
    end
end

