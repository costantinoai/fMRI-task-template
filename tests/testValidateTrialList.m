classdef testValidateTrialList < matlab.unittest.TestCase
    methods(Test)
        function testMissingStimFile(testCase)
            addpath('./utils');
            tl = struct('stimuli', {'./src/stimuli/this_file_does_not_exist.jpg'});
            testCase.verifyError(@() validateTrialList(tl), 'Stimuli:NotFound');
        end
        function testOK(testCase)
            addpath('./utils'); addpath('./src');
            tbl = readtable('src/list_of_stimuli.tsv', 'FileType','text','Delimiter','\t');
            i = find(~strcmp(tbl.stimuli,'fixation'),1,'first');
            tl = table2struct(tbl(i,:));
            validateTrialList(tl); % should not error
        end
    end
end

