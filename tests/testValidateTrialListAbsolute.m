classdef testValidateTrialListAbsolute < matlab.unittest.TestCase
    methods(Test)
        function testAbsolutePathNotAllowed(testCase)
            addpath('./utils');
            absPath = fullfile(pwd,'src','stimuli','animal_sheep.jpg');
            tl = struct('stimuli', {absPath});
            testCase.verifyError(@() validateTrialList(tl), 'Stimuli:AbsolutePathNotAllowed');
        end
    end
end

