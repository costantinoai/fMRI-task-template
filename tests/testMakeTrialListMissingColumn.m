classdef testMakeTrialListMissingColumn < matlab.unittest.TestCase
    methods(Test)
        function testMissingStimuliColumn(testCase)
            addpath('./utils');
            % Create a temp TSV without 'stimuli' column
            tmp = [tempname '.tsv'];
            fid = fopen(tmp,'w');
            fprintf(fid, 'foo\tbar\n');
            fprintf(fid, 'a\tb\n');
            fclose(fid);
            params.stimListFile = tmp;
            params.numRepetitions = 1; params.numRuns = 1;
            params.prePost = 1; params.stimDur = 0.5; params.fixDur = 0.5; params.trialDur = 1;
            params.stimRandomization = 'run';
            params.respKey1Code = 49; params.respKey2Code = 50; params.respInst1='L'; params.respInst2='R';
            in.subNum = 1;
            testCase.verifyError(@() makeTrialList(params, in), 'StimList:MissingColumn');
        end
    end
end

