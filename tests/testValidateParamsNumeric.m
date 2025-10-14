classdef testValidateParamsNumeric < matlab.unittest.TestCase
    methods(Test)
        function testNumericOnlyKeys(testCase)
            addpath(genpath('./utils'));
            params = struct();
            params.stimDur=1; params.fixDur=1; params.prePost=1; params.taskName='x';
            params.resize=true; params.numRuns=1; params.stimListFile='src/list_of_stimuli.tsv';
            params.numRepetitions=1; params.fixSize=0.5; params.fixType='round';
            params.textSize=10; params.textFont='Helv'; params.triggerWaitText='...';
            params.scrDistMRI=1; params.scrWidthMRI=1; params.scrDistPC=1; params.scrWidthPC=1;
            params.respInst1='L'; params.respInst2='R';
            params.escapeKeyCode = 27;
            % Bad: string code instead of numeric
            params.respKeyPC1Code = 'f'; params.respKeyPC2Code = 106; params.triggerKeyPCCode = 116;
            params.respKey1Code = 'f'; params.respKey2Code = 106; params.triggerKeyCode = 116; % Unified keys
            params.buttons = [102, 106]; % Buttons array required
            fmriMode=false;
            testCase.verifyError(@() validateParams(params, fmriMode), 'Params:InvalidValue');
        end
    end
end

