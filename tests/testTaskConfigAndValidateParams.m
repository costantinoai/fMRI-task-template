classdef testTaskConfigAndValidateParams < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function changeToRepoRoot(testCase)
            % Change to repo root before each test
            testDir = fileparts(mfilename('fullpath'));
            repoRoot = fileparts(testDir);
            oldDir = cd(repoRoot);
            testCase.addTeardown(@() cd(oldDir));
        end
    end

    methods(Test)
        function testLoadAndValidate(testCase)
            addpath(genpath('./utils')); addpath('./src');
            fmriMode = false;
            params = TaskConfig.load(fullfile('src','config.m'), fmriMode);
            validateParams(params, fmriMode);
            % Check for unified button keys (new structure)
            testCase.verifyTrue(isfield(params, 'buttons') || isfield(params, 'respKeyPC1Code'), ...
                'Should have buttons or respKeyPC1Code field');
            testCase.verifyTrue(isfield(params, 'escapeKeyCode'));
            testCase.verifyTrue(isfield(params, 'numRuns'));
        end
    end
end
