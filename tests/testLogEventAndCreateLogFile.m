classdef testLogEventAndCreateLogFile < matlab.unittest.TestCase
    methods(Test)
        function testCreateAndWrite(testCase)
            addpath('./utils');
            params.taskName = 'unittest';
            in.resDir = tempname;
            mkdir(in.resDir);
            in.subNum = 1; in.runNum = 1;
            logFile = createLogFile(params, in);
            testCase.onFailure(@() fclose(logFile));
            logEvent(logFile, 'EVENT_TYPE','EVENT_NAME','DATETIME','EXP','ACT','DELTA','ID');
            fclose(logFile);
            files = dir(fullfile(in.resDir, '*_task-unittest_log.tsv'));
            testCase.verifyGreaterThan(numel(files), 0);
        end
    end
end

