classdef testTaskConfigAndValidateParams < matlab.unittest.TestCase
    methods(Test)
        function testLoadAndValidate(testCase)
            addpath(genpath('./utils')); addpath('./src');
            fmriMode = false;
            params = TaskConfig.load(fullfile('src','config.m'), fmriMode);
            validateParams(params, fmriMode);
            testCase.verifyTrue(isfield(params, 'respKeyPC1Code'));
            testCase.verifyTrue(isfield(params, 'escapeKeyCode'));
            testCase.verifyTrue(isfield(params, 'numRuns'));
        end
    end
end
