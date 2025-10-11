function tests = testInitLogging
% TESTINITLOGGING Unit tests for initLogging function.
tests = functiontests(localfunctions);
end

function testConsoleLogging(testCase)
% Test that debugMode=true with writeLogs=false returns stdout handle (1)
params.taskName = 'test';
in.subNum = 1;
in.runNum = 1;
in.timestamp = '2025-01-01-12-00';
in.resDir = tempdir;

dbg.writeLogs = false;
debugMode = true;

logFile = initLogging(params, in, debugMode, dbg);

% Should return stdout handle
verifyEqual(testCase, logFile, 1);
end

function testFileLogging(testCase)
% Test that debugMode=false creates actual log file
params.taskName = 'test';
params.srcDir = './src';
in.subNum = 99;
in.runNum = 1;
in.timestamp = '2025-01-01-12-00';
in.resDir = tempdir;

dbg.writeLogs = true;
debugMode = false;

% Create log file
logFile = initLogging(params, in, debugMode, dbg);

% Should return FID (not 1)
verifyNotEqual(testCase, logFile, 1);
verifyGreaterThan(testCase, logFile, 2); % FID > 2

% Check file exists
expectedPattern = fullfile(in.resDir, '*_log.tsv');
files = dir(expectedPattern);
verifyNotEmpty(testCase, files);

% Clean up
if logFile > 2
    fclose(logFile);
end
for i = 1:numel(files)
    delete(fullfile(in.resDir, files(i).name));
end
end

function testHeaderWritten(testCase)
% Test that TSV header is written to log file
params.taskName = 'test';
params.srcDir = './src';
in.subNum = 99;
in.runNum = 1;
in.timestamp = '2025-01-01-12-00';
in.resDir = tempdir;

dbg.writeLogs = true;
debugMode = false;

% Create log file
logFile = initLogging(params, in, debugMode, dbg);

% Close file to flush
if logFile > 2
    fclose(logFile);
end

% Read file and check header
logFiles = dir(fullfile(in.resDir, '*_log.tsv'));
verifyNotEmpty(testCase, logFiles);

logPath = fullfile(in.resDir, logFiles(1).name);
fid = fopen(logPath, 'r');
headerLine = fgetl(fid);
fclose(fid);

% Check header contains expected columns
verifyTrue(testCase, contains(headerLine, 'EVENT_TYPE'));
verifyTrue(testCase, contains(headerLine, 'EVENT_NAME'));
verifyTrue(testCase, contains(headerLine, 'DATETIME'));
verifyTrue(testCase, contains(headerLine, 'EXP_ONSET'));
verifyTrue(testCase, contains(headerLine, 'ACTUAL_ONSET'));

% Clean up
delete(logPath);
end
