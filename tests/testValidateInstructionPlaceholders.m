classdef testValidateInstructionPlaceholders < matlab.unittest.TestCase
    methods(Test)
        function testExactlyTwo(testCase)
            addpath(genpath('./utils'));
            p = struct();
            p.instructionsText1 = 'Press () for left';
            p.instructionsText2 = 'Press () for right';
            validateInstructionPlaceholders(p); % no error
        end
        function testTooMany(testCase)
            addpath(genpath('./utils'));
            p = struct();
            p.instructionsText1 = '() () ()';
            testCase.verifyError(@() validateInstructionPlaceholders(p), 'Instructions:PlaceholderCount');
        end
        function testTooFew(testCase)
            addpath(genpath('./utils'));
            p = struct();
            p.instructionsText1 = 'no placeholders here';
            testCase.verifyError(@() validateInstructionPlaceholders(p), 'Instructions:PlaceholderCount');
        end
    end
end

