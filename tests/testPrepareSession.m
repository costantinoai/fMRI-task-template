classdef testPrepareSession < matlab.unittest.TestCase
    % testPrepareSession - Test prepareSession setup helper
    %   Validates session struct creation, validation, and directory handling

    methods(Test)
        function testHappyPath(testCase)
            addpath(genpath('./utils'));

            % Test normal execution
            subNum = 5;
            runNum = 2;
            debugMode = true; % Don't create actual directory

            in = prepareSession(subNum, runNum, debugMode);

            % Verify struct fields
            testCase.verifyEqual(in.subNum, 5);
            testCase.verifyEqual(in.runNum, 2);
            testCase.verifyTrue(isfield(in, 'timestamp'));
            testCase.verifyTrue(isfield(in, 'resDir'));

            % Verify timestamp format
            testCase.verifyMatches(in.timestamp, '\d{4}-\d{2}-\d{2}_\d{6}');

            % Verify resDir path format
            testCase.verifyMatches(in.resDir, 'data/sub-05$');
        end

        function testZeroPadding(testCase)
            addpath(genpath('./utils'));

            % Test subject number zero-padding
            in = prepareSession(3, 1, true);
            testCase.verifyMatches(in.resDir, 'sub-03$');

            in = prepareSession(42, 1, true);
            testCase.verifyMatches(in.resDir, 'sub-42$');

            in = prepareSession(1, 1, true);
            testCase.verifyMatches(in.resDir, 'sub-01$');
        end

        function testInvalidSubNum(testCase)
            addpath(genpath('./utils'));

            % Negative number
            testCase.verifyError(@() prepareSession(-1, 1, true), 'Session:InvalidSubNum');

            % Zero
            testCase.verifyError(@() prepareSession(0, 1, true), 'Session:InvalidSubNum');

            % Non-integer
            testCase.verifyError(@() prepareSession(1.5, 1, true), 'Session:InvalidSubNum');

            % String
            testCase.verifyError(@() prepareSession('1', 1, true), 'Session:InvalidSubNum');
        end

        function testInvalidRunNum(testCase)
            addpath(genpath('./utils'));

            % Negative number
            testCase.verifyError(@() prepareSession(1, -1, true), 'Session:InvalidRunNum');

            % Zero
            testCase.verifyError(@() prepareSession(1, 0, true), 'Session:InvalidRunNum');

            % Non-integer
            testCase.verifyError(@() prepareSession(1, 2.5, true), 'Session:InvalidRunNum');

            % String
            testCase.verifyError(@() prepareSession(1, '2', true), 'Session:InvalidRunNum');
        end

        function testDirectoryCreation(testCase)
            addpath(genpath('./utils'));

            % Test directory creation in non-debug mode
            % Use high subject number to avoid conflicts
            subNum = 999;
            runNum = 1;
            debugMode = false;

            in = prepareSession(subNum, runNum, debugMode);

            % Directory should be created
            testCase.verifyTrue(exist(in.resDir, 'dir') == 7, ...
                'Directory should be created when debugMode=false');

            % Cleanup
            rmdir(in.resDir);
        end

        function testDebugModeNoDirectory(testCase)
            addpath(genpath('./utils'));

            % Test that debug mode does not create directory
            subNum = 998;
            runNum = 1;
            debugMode = true;

            % Make sure directory doesn't exist
            testResDir = fullfile(pwd, 'data', 'sub-998');
            if exist(testResDir, 'dir')
                rmdir(testResDir);
            end

            in = prepareSession(subNum, runNum, debugMode);

            % Directory should NOT be created in debug mode
            testCase.verifyFalse(exist(in.resDir, 'dir') == 7, ...
                'Directory should not be created when debugMode=true');
        end

        function testTimestampUnique(testCase)
            addpath(genpath('./utils'));

            % Create two sessions quickly
            in1 = prepareSession(1, 1, true);
            pause(0.01); % Small delay to ensure different timestamps
            in2 = prepareSession(1, 1, true);

            % Timestamps should be strings
            testCase.verifyClass(in1.timestamp, 'char');
            testCase.verifyClass(in2.timestamp, 'char');

            % Timestamps should be non-empty
            testCase.verifyNotEmpty(in1.timestamp);
            testCase.verifyNotEmpty(in2.timestamp);
        end
    end
end
