function trialList = makeTrialList(params, in)
% MAKETRIALLIST - Generate a list of trials based on provided parameters and input data.
%
%   trialList = MAKETRIALLIT(params, in) generates a list of trials using
%   parameters stored in the 'params' structure and input data stored in
%   the 'in' structure. It reads a stimulus list file, duplicates the list
%   based on the specified number of repetitions, randomizes trials as
%   required, adds run numbers, calculates ideal stimulus onset times, and
%   fills the trial list structure with relevant information.
%   It also keeps any extra variable contained in the .tsv file containing
%   the list of trials that you provide with 'params.stimListFile', and 
%   saves it with its original name in the output.
%
%   Input:
%       - params: A structure containing parameters required to generate
%                 the trial list. It must include fields: 'stimListFile',
%                 'numRuns', 'prePost', 'trialDur', 'numRepetitions',
%                 'stimRandomization'.
%       - in: A structure containing input data, such as subject number.
%
%   Output:
%       - trialList: A structure array containing information about each trial,
%                    including trial number, run number, button mapping,
%                    subject number, ideal stimulus onset time, and placeholders
%                    for subject response and actual stimulus onset.
%
%   Example:
%       params.stimListFile = 'stimuli.tsv';
%       params.numRuns = 4;
%       params.prePost = 2;
%       params.trialDur = 4;
%       params.numRepetitions = 2;
%       params.stimRandomization = 'run';
%       in.subNum = 1;
%       trialList = makeTrialList(params, in);
% 
%   Author
%   Tim Maniquet [7/3/24]

% Check if the required fields are present in the params structure
requiredFields = {'stimListFile', 'numRepetitions', 'numRuns', 'prePost', 'trialDur'};
missingFields = setdiff(requiredFields, fieldnames(params));
if ~isempty(missingFields)
    error('makeTrialList:paramsMissing', 'Required field(s) %s missing in the params structure.', strjoin(missingFields, ', '));
end


% Fetch the stimulus list file and read it robustly
try
    opts = detectImportOptions(params.stimListFile, 'FileType','text', 'Delimiter','\t');
    % Preserve original header names (e.g., 'stimuli') without modification
    try
        opts.VariableNamingRule = 'preserve';
    catch
        % Older MATLAB versions may not support VariableNamingRule; continue
    end
    % Set all variables to string to avoid unexpected type coercions
    try
        opts = setvartype(opts, opts.VariableNames, 'string');
    catch
        % If not supported, proceed with defaults
    end
    stimListTable = readtable(params.stimListFile, opts);
catch exception
    error('StimList:ReadFailed', ['Failed to read stimuli list %s: %s. ', ...
        'Ensure it is a tab-delimited text file with a header row.'], params.stimListFile, exception.message);
end

% Verify required column
if ~ismember('stimuli', stimListTable.Properties.VariableNames)
    error('StimList:MissingColumn', ['The trial list must contain a column named ''stimuli''. ', ...
        'Edit %s to include a ''stimuli'' column.'], params.stimListFile);
end

% Duplicate the list of stimuli based on the declared number of repetitions
stimList = repmat(stimListTable, params.numRepetitions, 1);

% Check if we have an external run column
hasExternalRun = ismember('run', stimList.Properties.VariableNames);

% If no external run column, validate divisibility and add run numbers
if ~hasExternalRun
    % If the total number of trials isn't divisible by the number of runs, raise error
    if mod(height(stimList), params.numRuns) ~= 0
        error('makeTrialList:InvalidRuns', ['Your list of %d trials cannot be divided into %d runs of equal length. ', ...
            'Adjust either numRuns, numRepetitions, or the stimulus list length to ensure equal runs.'], ...
            height(stimList), params.numRuns);
    end

    % Calculate how many trials we have per run
    trialsPerRun = floor(height(stimList) / params.numRuns);

    % Make a list of run numbers corresponding to the trials
    runList = repelem(1:params.numRuns, trialsPerRun)';
    % Convert the runList to a table
    runTable = array2table(runList, 'VariableNames', {'run'});
    % Concatenate the runTable with the stimList table
    stimList = [stimList, runTable];
else
    % External run column exists - validate it makes sense with params.numRuns
    % Calculate trials per run for onset calculations
    trialsPerRun = floor(height(stimList) / params.numRuns);
end

% Randomize trials if required, per run or across the task
if isfield(params, 'stimRandomization')
    if strcmp(params.stimRandomization, 'run')
        % Randomize within each run
        for i = 1:params.numRuns
            % Find the index of the trials of the current run
            idx = 1 + (trialsPerRun * (i-1)) : trialsPerRun + (trialsPerRun * (i-1));
            % Create a new random index for these trials
            randIdx = idx(randperm(length(idx)));
            % Re-attribute the run rows randomly
            stimList(idx,:) = stimList(randIdx,:);
        end
    elseif strcmp(params.stimRandomization, 'all')
        % Create a random index for all stimuli
        randIdx = randperm(height(stimList));
        % Randomize the rows across all runs
        stimList = stimList(randIdx, :);
    end
end

% Extract run list AFTER randomization (so it matches shuffled order)
runList = stimList.run;
% Calculate the ideal stimulus onset times for one run
stimOnsetRun= params.prePost:params.trialDur: ...
    (trialsPerRun*params.trialDur)+(params.prePost-params.trialDur);
% Make a list to extend to the complete trial list
stimOnsetList = stimOnsetRun;
for i = 2:params.numRuns
    stimOnsetList = [stimOnsetList stimOnsetRun];
end

% Initiate the trial list as a structure and fill it with information
trialList = table2struct(stimList);

% Precompute mapping per run to avoid repeated compute
% Use containers.Map to handle arbitrary run numbers (not just 1:N)
uniqueRuns = unique(runList);
mapCache = containers.Map('KeyType', 'double', 'ValueType', 'any');
for r = uniqueRuns'
    runNumDouble = double(r);  % Ensure numeric type
    mapCache(runNumDouble) = determineButtonMapping(params, in.subNum, runNumDouble);
end

% Add relevant columns to the trial list structure
for i = 1:numel(trialList)
    % Declare a trial number
    trialList(i).trialNb = i;
    % Declare a run number (already in struct from table2struct, but ensure consistency)
    trialList(i).run = double(runList(i));
    % Declare a button mapping based on subject and run number (from cache)
    map = mapCache(trialList(i).run);
    trialList(i).butMap    = map.mapNumber;
    trialList(i).respKey1Code = map.respKey1Code;
    trialList(i).respKey2Code = map.respKey2Code;
    trialList(i).respInst1 = map.respInst1;
    trialList(i).respInst2 = map.respInst2;
    % Declare a subject number
    trialList(i).subNum = in.subNum;
    % Declare the ideal stimulus onset times
    trialList(i).idealStimOnset = stimOnsetList(i);
    % Declare a placeholder for subject response
    trialList(i).response = NaN;
    % Declare a placeholder for actual stimulus onset
    trialList(i).stimOnset= NaN;
end

end
