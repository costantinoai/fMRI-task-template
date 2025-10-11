function validateTrialList(trialList)
%VALIDATETRIALLIST Validate that non-fixation stimuli files exist.
%   Errors early with actionable message on the first missing file.

% Extract stimuli paths
stims = {trialList.stimuli};

% Detect absolute vs relative path usage
isAbs = false(size(stims));
for i = 1:numel(stims)
    s = stims{i};
    if strcmp(s, 'fixation'), continue, end
    % Absolute on UNIX starts with '/', on Windows drive letter 'C:' (case-insensitive)
    if ~isempty(s) && (startsWith(s, filesep) || ~isempty(regexp(s, '^[A-Za-z]:', 'once')))
        isAbs(i) = true;
    end
end
if any(isAbs)
    error('Stimuli:AbsolutePathNotAllowed', ['Absolute stimulus paths are not allowed. ', ...
        'Use repo-relative paths like ./src/stimuli/your_image.jpg.']);
end
for i = 1:numel(stims)
    s = stims{i};
    if strcmp(s, 'fixation')
        continue
    end
    if exist(s, 'file') ~= 2
        error('Stimuli:NotFound', 'Stimulus file not found: %s (trial %d). Fix the path in src/list_of_stimuli.tsv.', s, i);
    end
end

end
