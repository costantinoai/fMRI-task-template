function trialList = makeTrialListBlocked(params, in)
% MAKETRIALLISTBLOCKED Generate blocked design trial list.
%
%   Creates trial list with 3 conditions organized into 4 blocks per run.
%   Block order is fixed (A→B→C→A) but can be customized.
%
% Design Parameters:
%   - 3 conditions (condA, condB, condC)
%   - 4 blocks per run
%   - 12 trials per block (adjustable)
%   - Fixed block order (customizable)
%
% Inputs:
%   params - Experiment parameters (must include stimListFile)
%   in     - Session info (runNum)
%
% Outputs:
%   trialList - Struct array with fields:
%               trialNb, run, block, condition, stimuli, idealStimOnset,
%               respKey1Code, respKey2Code, respInst1, respInst2
%
% Customization:
%   - Change trialsPerBlock for different block lengths
%   - Modify blockOrder for different condition sequences
%   - Add randomization within blocks
%
% Example:
%   trialList = makeTrialListBlocked(params, in);
%
% See also: makeTrialList
%
% Author: fMRI Task Template Team
% Last updated: 2025

% Block design parameters
trialsPerBlock = 12;  % Trials per block
blocksPerRun = 4;     % Blocks per run
blockOrder = {'condA', 'condB', 'condC', 'condA'};  % Fixed order

% Read stimulus list
stimListFile = fullfile(params.srcDir, params.stimListFile);
stimTable = readtable(stimListFile, 'FileType', 'text', 'Delimiter', '\t');

% Validate condition column exists
if ~ismember('condition', stimTable.Properties.VariableNames)
    error('TrialList:MissingCondition', ...
        ['Stimulus list must have "condition" column for blocked design.\n', ...
         'Expected columns: stimuli, condition\n', ...
         'Example row: ./src/stimuli/cat.jpg	condA']);
end

% Initialize trial list
trialList = [];
trialNb = 1;

% Generate trials for each run
for run = 1:params.numRuns
    % Generate trials for each block
    for blockIdx = 1:blocksPerRun
        condName = blockOrder{blockIdx};

        % Get stimuli for this condition
        condStims = stimTable(strcmp(stimTable.condition, condName), :);

        if height(condStims) == 0
            error('TrialList:NoStimuli', ...
                'No stimuli found for condition "%s". Check list_of_stimuli.tsv', condName);
        end

        % Sample trials for this block (with replacement if needed)
        if height(condStims) >= trialsPerBlock
            % Enough unique stimuli - sample without replacement
            blockStims = condStims(randperm(height(condStims), trialsPerBlock), :);
        else
            % Not enough - sample with replacement
            indices = randi(height(condStims), trialsPerBlock, 1);
            blockStims = condStims(indices, :);
        end

        % Create trial structs for this block
        for t = 1:trialsPerBlock
            trial.trialNb = trialNb;
            trial.run = run;
            trial.block = blockIdx;
            trial.condition = condName;
            trial.stimuli = blockStims.stimuli{t};

            % Compute ideal onset (cumulative time from run start)
            % Each trial: stimDur + fixDur
            trialDur = params.stimDur + params.fixDur;
            trial.idealStimOnset = (trialNb - 1 - (run-1)*trialsPerBlock*blocksPerRun) * trialDur;

            % Add button mapping (fixed or from config)
            trial.respKey1Code = params.respKey1Code;
            trial.respKey2Code = params.respKey2Code;
            trial.respInst1 = 'response 1';
            trial.respInst2 = 'response 2';

            % Optional: Add correctAnswer if needed
            if ismember('correctAnswer', blockStims.Properties.VariableNames)
                trial.correctAnswer = blockStims.correctAnswer(t);
            end

            trialList = [trialList; trial];
            trialNb = trialNb + 1;
        end
    end
end

% Convert to struct array
trialList = struct2table(trialList);
trialList = table2struct(trialList);

fprintf('Generated blocked design: %d runs × %d blocks × %d trials = %d total trials\n', ...
    params.numRuns, blocksPerRun, trialsPerBlock, numel(trialList));

end
