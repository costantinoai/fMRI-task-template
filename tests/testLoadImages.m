classdef testLoadImages < matlab.unittest.TestCase
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
        function testSubsetLoad(testCase)
            addpath(genpath('./utils')); addpath('./src');
            % Build a tiny trialList of 2 non-fixation images
            tbl = readtable('src/list_of_stimuli.tsv', 'FileType','text','Delimiter','\t');
            nonfix = ~strcmp(tbl.stimuli, 'fixation');
            tbl2 = tbl(find(nonfix,2,'first'),:);
            tl = table2struct(tbl2);
            params.resize = false;
            imMat = loadImages(tl, params);
            testCase.verifyEqual(numel(imMat.image), height(tbl2));
        end
    end
end

