classdef testLogEventGolden < matlab.unittest.TestCase
    % testLogEventGolden - Golden test for logEvent TSV output format
    %   Validates that the TSV header and row format remain stable.
    %   Output invariants: column order, tab separators, numeric precision.

    methods(Test)
        function testHeaderFormat(testCase)
            % Verify exact TSV header line format
            addpath(genpath('./utils'));

            tmpFile = tempname;
            fid = fopen(tmpFile, 'w');
            testCase.onFailure(@() fclose(fid));

            % Write header (first row convention)
            logEvent(fid, 'EVENT_TYPE', 'EVENT_NAME', 'DATETIME', 'EXP_ONSET', 'ACTUAL_ONSET', 'DELTA', 'EVENT_ID');
            fclose(fid);

            % Read and verify
            content = fileread(tmpFile);
            delete(tmpFile);

            expectedHeader = 'EVENT_TYPE\tEVENT_NAME\tDATETIME\tEXP_ONSET\tACTUAL_ONSET\tDELTA\tEVENT_ID';
            actualHeader = strtrim(content);

            testCase.verifyEqual(actualHeader, expectedHeader, ...
                'TSV header format must match exactly (output invariant)');
        end

        function testRowFormatFlip(testCase)
            % Verify FLIP row formatting with numeric values
            addpath(genpath('./utils'));

            tmpFile = tempname;
            fid = fopen(tmpFile, 'w');
            testCase.onFailure(@() fclose(fid));

            % Write a typical FLIP row
            logEvent(fid, 'FLIP', 'Stim', '2024-03-15-14-30', 12.500000, 12.540000, 0.040000, 'image1');
            fclose(fid);

            % Read and verify structure
            content = fileread(tmpFile);
            delete(tmpFile);

            % Check tab count (should be 6 tabs for 7 columns)
            tabCount = sum(content == sprintf('\t'));
            testCase.verifyEqual(tabCount, 6, 'Must have exactly 6 tabs');

            % Split and verify column presence
            cols = strsplit(strtrim(content), '\t');
            testCase.verifyEqual(numel(cols), 7, 'Must have exactly 7 columns');
            testCase.verifyEqual(cols{1}, 'FLIP');
            testCase.verifyEqual(cols{2}, 'Stim');
            testCase.verifyEqual(cols{3}, '2024-03-15-14-30');

            % Verify numeric columns are numeric strings
            expOnset = str2double(cols{4});
            actOnset = str2double(cols{5});
            delta = str2double(cols{6});
            testCase.verifyFalse(isnan(expOnset), 'EXP_ONSET must be numeric');
            testCase.verifyFalse(isnan(actOnset), 'ACTUAL_ONSET must be numeric');
            testCase.verifyFalse(isnan(delta), 'DELTA must be numeric');
        end

        function testRowFormatResp(testCase)
            % Verify RESP row with numeric EVENT_ID
            addpath(genpath('./utils'));

            tmpFile = tempname;
            fid = fopen(tmpFile, 'w');
            testCase.onFailure(@() fclose(fid));

            % Write a RESP row with numeric event ID
            logEvent(fid, 'RESP', 'key1', '2024-03-15-14-31', 13.200000, 13.210000, 0.010000, 102);
            fclose(fid);

            content = fileread(tmpFile);
            delete(tmpFile);

            cols = strsplit(strtrim(content), '\t');
            testCase.verifyEqual(cols{1}, 'RESP');
            testCase.verifyEqual(cols{2}, 'key1');

            % EVENT_ID should be numeric (as %f format)
            eventID = str2double(cols{7});
            testCase.verifyFalse(isnan(eventID), 'Numeric EVENT_ID must be written as number');
            testCase.verifyEqual(eventID, 102, 'RelTol', 1e-6);
        end

        function testRowFormatInfo(testCase)
            % Verify INFO row with string EVENT_ID
            addpath(genpath('./utils'));

            tmpFile = tempname;
            fid = fopen(tmpFile, 'w');
            testCase.onFailure(@() fclose(fid));

            % Write an INFO row with placeholders
            logEvent(fid, 'INFO', 'Config', '-', '-', '-', '-', 'params.numRuns=2');
            fclose(fid);

            content = fileread(tmpFile);
            delete(tmpFile);

            cols = strsplit(strtrim(content), '\t');
            testCase.verifyEqual(cols{1}, 'INFO');
            testCase.verifyEqual(cols{4}, '-', 'EXP_ONSET placeholder');
            testCase.verifyEqual(cols{5}, '-', 'ACTUAL_ONSET placeholder');
            testCase.verifyEqual(cols{6}, '-', 'DELTA placeholder');
            testCase.verifyEqual(cols{7}, 'params.numRuns=2', 'String EVENT_ID preserved');
        end

        function testMultipleRows(testCase)
            % Verify header + multiple rows maintain consistent format
            addpath(genpath('./utils'));

            tmpFile = tempname;
            fid = fopen(tmpFile, 'w');
            testCase.onFailure(@() fclose(fid));

            % Write header and several rows
            logEvent(fid, 'EVENT_TYPE', 'EVENT_NAME', 'DATETIME', 'EXP_ONSET', 'ACTUAL_ONSET', 'DELTA', 'EVENT_ID');
            logEvent(fid, 'INFO', 'Start', '2024-03-15-14-30', '-', '-', '-', 'run=1');
            logEvent(fid, 'FLIP', 'Instr', '2024-03-15-14-31', 0.0, 0.123, 0.123, 'instructions');
            logEvent(fid, 'RESP', 'Continue', '2024-03-15-14-32', 1.5, 1.543, 0.043, 102);
            logEvent(fid, 'FLIP', 'Stim', '2024-03-15-14-33', 10.0, 10.002, 0.002, 'image1');
            fclose(fid);

            % Read all lines
            content = fileread(tmpFile);
            delete(tmpFile);

            lines = strsplit(content, '\n');
            lines = lines(~cellfun('isempty', lines)); % Remove empty

            testCase.verifyEqual(numel(lines), 5, 'Should have 5 lines (header + 4 rows)');

            % Verify all lines have same number of tabs
            for i = 1:numel(lines)
                tabCount = sum(lines{i} == sprintf('\t'));
                testCase.verifyEqual(tabCount, 6, sprintf('Line %d must have 6 tabs', i));
            end
        end
    end
end
