classdef testResizeStimPPD < matlab.unittest.TestCase
    methods(Test)
        function testPPDResize(testCase)
            addpath(genpath('./utils'));
            img = zeros(10,20,3,'uint8');
            params.resizeMode = 'visualUnits';
            params.PPD = 50; % px/deg
            params.useScreenGeometry = true;
            params.outWidth = 2; % deg
            params.outHeight = 1; % deg
            resized = resizeStim(img, params);
            sz = size(resized);
            testCase.verifyEqual(sz(2), 100); % 2 deg * 50 px/deg
            testCase.verifyEqual(sz(1), 50);  % 1 deg * 50 px/deg
        end
    end
end

