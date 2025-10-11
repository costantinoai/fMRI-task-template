# Customization Examples

This document shows concrete examples of common customizations for the fMRI task template.

## Overview

Most studies will customize one or more of these aspects:
1. **Trial list generation** - Custom conditions, counterbalancing, blocking
2. **Instructions** - Different text, visuals, or layout
3. **Stimulus presentation** - Feedback, different trial types, response-contingent displays
4. **Timing** - Variable ISI, jittered durations
5. **Input handling** - Multi-button responses, rating scales

## Example 1: Adding Visual Feedback

**Goal**: Show "Correct!" or "Wrong!" after each response.

**What to change**: Modify the trial loop in `fMRI_task.m` to add feedback display after response collection.

**Code** (insert after line ~311 in fMRI_task.m, after response is recorded):

```matlab
%% Optional: Show feedback
if isfield(runTrials(i), 'correctAnswer')
    % Determine if response was correct
    isCorrect = (runTrials(i).response == runTrials(i).correctAnswer);

    % Draw feedback text
    Screen('FillRect', win, in.gray);
    if isCorrect
        feedbackText = 'Correct!';
        feedbackColor = [0 255 0];  % Green
    elseif isnan(runTrials(i).response)
        feedbackText = 'Too slow!';
        feedbackColor = [255 165 0];  % Orange
    else
        feedbackText = 'Wrong';
        feedbackColor = [255 0 0];  % Red
    end

    Screen('TextSize', win, 48);
    DrawFormattedText(win, feedbackText, 'center', 'center', feedbackColor);

    % Show feedback for 500ms
    VBL = Screen('Flip', win);
    logEvent(logFile, 'FLIP', 'Feedback', dateTimeStr, '-', VBL - in.scriptStart, '-', feedbackText);
    WaitSecs(0.5);

    % Store accuracy in trial list
    runTrials(i).accuracy = isCorrect;
end
```

**Trial list requirement**: Add `correctAnswer` field to your `src/list_of_stimuli.tsv`:
```
stimuli	correctAnswer
./src/stimuli/inside_1.jpg	102
./src/stimuli/outside_1.jpg	106
```

## Example 2: Custom Trial List with Blocking

**Goal**: Create a blocked design with 3 conditions, 4 blocks per run.

**What to change**: Create custom `src/makeTrialListCustom.m` and call it instead of `makeTrialList`.

**File**: `src/makeTrialListCustom.m`

```matlab
function trialList = makeTrialListCustom(params, in)
% MAKETRIALLISTCUSTOM Generate blocked design trial list.
%
% Creates 3 conditions (A, B, C) in 4 blocks per run.
% Each block contains 8 trials of one condition.

% Block structure: [A A A A A A A A] [B B B B B B B B] [C C C C C C C C] [A A A A A A A A]
trialsPerBlock = 8;
blocksPerRun = 4;
conditions = {'condA', 'condB', 'condC', 'condA'};  % Block order

% Read base stimuli
stimListFile = fullfile(params.srcDir, params.stimListFile);
stimTable = readtable(stimListFile, 'FileType', 'text', 'Delimiter', '\t');

% Filter by condition
trialList = [];
trialNb = 1;

for run = 1:params.numRuns
    for blockIdx = 1:blocksPerRun
        cond = conditions{blockIdx};

        % Get stimuli for this condition
        condStims = stimTable(strcmp(stimTable.condition, cond), :);

        % Sample with replacement if needed
        blockTrials = condStims(randi(height(condStims), trialsPerBlock, 1), :);

        % Convert to trial structs
        for t = 1:trialsPerBlock
            trial.trialNb = trialNb;
            trial.run = run;
            trial.block = blockIdx;
            trial.condition = cond;
            trial.stimuli = blockTrials.stimuli{t};
            trial.correctAnswer = blockTrials.correctAnswer(t);

            % Compute ideal onset (8s per trial, including stim + fix)
            trial.idealStimOnset = (trialNb - 1) * (params.stimDur + params.fixDur);

            % Add button mapping
            trial.respKey1Code = params.respKey1Code;
            trial.respKey2Code = params.respKey2Code;
            trial.respInst1 = 'inside';
            trial.respInst2 = 'outside';

            trialList = [trialList; trial];
            trialNb = trialNb + 1;
        end
    end
end

% Convert to struct array
trialList = struct2table(trialList);
trialList = table2struct(trialList);

end
```

**Integration**: In `fMRI_task.m`, replace line ~131:
```matlab
% OLD:
trialList = makeTrialList(params, in);

% NEW:
trialList = makeTrialListCustom(params, in);
```

## Example 3: Custom Instructions with Images

**Goal**: Show a diagram alongside instruction text.

**What to change**: Create custom `displayInstructionsCustom.m` in `src/`.

**File**: `src/displayInstructionsCustom.m`

```matlab
function displayInstructionsCustom(win, params, in, respInst1, respInst2)
% DISPLAYINSTRUCTIONSCUSTOM Show instructions with visual diagram.

% Load instruction image
instrImagePath = fullfile(params.srcDir, 'instructions_diagram.png');
instrImage = imread(instrImagePath);
instrTexture = Screen('MakeTexture', win, instrImage);

% Get screen dimensions
[screenXpixels, screenYpixels] = Screen('WindowSize', win);

% Draw image in upper half
imageRect = CenterRectOnPointd([0 0 size(instrImage, 2) size(instrImage, 1)], ...
    screenXpixels/2, screenYpixels/3);
Screen('DrawTexture', win, instrTexture, [], imageRect);

% Draw text in lower half
Screen('TextSize', win, params.textSize);
Screen('TextFont', win, params.textFont);

instructionText = sprintf(...
    '%s\n\n%s: %s\n%s: %s\n\n%s', ...
    params.instructionsText1, ...
    params.instructionsText2, respInst1, ...
    params.instructionsText3, respInst2, ...
    params.instructionsText4);

DrawFormattedText(win, instructionText, 'center', screenYpixels * 0.65, in.black);

% Clean up texture
Screen('Close', instrTexture);

end
```

**Integration**: In `fMRI_task.m`, modify `showInstructions.m` to call your custom function, or directly replace line ~29 in `utils/display/showInstructions.m`:

```matlab
% Call custom instructions renderer
displayInstructionsCustom(win, params, in, respInst1, respInst2);
```

## Example 4: Variable ISI (Jittered Timing)

**Goal**: Add random jitter to fixation duration for event-related designs.

**What to change**: Modify fixation duration calculation in trial loop.

**Code** (replace line ~287 in fMRI_task.m):

```matlab
% OLD:
fixDur = adjustFixationDuration(runTrials, i, params);

% NEW: Add jitter from exponential distribution
baseFixDur = adjustFixationDuration(runTrials, i, params);
jitterMean = 2.0;  % Mean jitter in seconds
jitter = exprnd(jitterMean);  % Exponential distribution
fixDur = baseFixDur + jitter;

% Optional: Log jitter for analysis
logEvent(logFile, 'INFO', 'Jitter', dateTimeStr, '-', '-', '-', ...
    sprintf('Trial %d jitter: %.3fs', i, jitter));
```

**Note**: For true event-related designs, you should pre-compute jittered timings in `makeTrialList` to ensure total run time is predictable.

## Example 5: Rating Scale Response

**Goal**: Collect 1-5 rating instead of binary response.

**What to change**: Modify response collection and add rating scale visual.

**Code** (replace response collection section ~261-279 in fMRI_task.m):

```matlab
%% Response collection with rating scale
% Draw rating scale
Screen('FillRect', win, in.gray);
DrawFormattedText(win, 'Rate your confidence: 1 (low) to 5 (high)', ...
    'center', screenYpixels * 0.3, in.black);

% Draw scale boxes
numRatings = 5;
boxWidth = 80;
boxHeight = 80;
spacing = 20;
totalWidth = numRatings * boxWidth + (numRatings-1) * spacing;
startX = (screenXpixels - totalWidth) / 2;

for r = 1:numRatings
    boxX = startX + (r-1) * (boxWidth + spacing);
    boxY = screenYpixels * 0.5;
    boxRect = [boxX, boxY, boxX + boxWidth, boxY + boxHeight];

    Screen('FrameRect', win, in.black, boxRect, 3);
    DrawFormattedText(win, num2str(r), boxX + boxWidth/2 - 10, ...
        boxY + boxHeight/2 - 10, in.black);
end

VBL = Screen('Flip', win);

% Wait for rating (keys 1-5)
ratingKeys = [49, 50, 51, 52, 53];  % '1' through '5' key codes
trialStart = GetSecs;
rating = NaN;

while (GetSecs - trialStart) <= (params.stimDur * dbg.slowMoFactor)
    [pressed, ~, keyCode] = KbCheck(inputDevs.response);
    if pressed
        pressedCode = find(keyCode, 1);
        if ismember(pressedCode, ratingKeys)
            rating = pressedCode - 48;  % Convert keycode to 1-5
            logEvent(logFile, 'RESP', 'Rating', dateTimeStr, '-', ...
                GetSecs - in.scriptStart, '-', rating);
            break;
        end
    end
end

runTrials(i).rating = rating;
```

**Configuration**: Add to `src/config.m`:
```matlab
params.ratingKeys = [49, 50, 51, 52, 53];  % 1-5 keys
```

## Example 6: Counterbalancing Response Mappings Across Subjects

**Goal**: Alternate which button means "inside" vs "outside" based on subject number.

**What to change**: Modify button mapping in `src/config.m`.

**Code** (add to `src/config.m`):

```matlab
% Counterbalanced button mapping based on subject parity
if mod(subNum, 2) == 0
    % Even subjects: F=inside, J=outside
    params.buttonMapMode = 'standard';
else
    % Odd subjects: F=outside, J=inside (reversed)
    params.buttonMapMode = 'reversed';
end
```

Then modify `determineButtonMapping` or handle in fMRI_task.m after subject input:

```matlab
% Apply counterbalancing
if mod(in.subNum, 2) == 1 && params.buttonMapMode == 'reversed'
    % Swap response instructions
    temp = respInst1;
    respInst1 = respInst2;
    respInst2 = temp;

    % Swap codes
    temp = respKey1Code;
    respKey1Code = respKey2Code;
    respKey2Code = temp;
end
```

## Summary: Common Customization Points

| Aspect | File to Edit | Function/Section |
|--------|-------------|------------------|
| Trial structure | `src/makeTrialListCustom.m` | Custom trial list generator |
| Instructions | `src/displayInstructionsCustom.m` | Custom instruction renderer |
| Stimulus display | `fMRI_task.m` line ~235 | `displayTrial` call or custom |
| Feedback | `fMRI_task.m` after line ~311 | Post-response section |
| Timing/jitter | `fMRI_task.m` line ~287 | Fixation duration calc |
| Response type | `fMRI_task.m` line ~261-279 | Response collection section |
| Button mapping | `src/config.m` + `fMRI_task.m` | Button code assignment |
| Debug overlay | `fMRI_task.m` throughout | All `if dbg.overlay` blocks |

## Tips for Clean Customization

1. **Keep study logic in `src/` or main script**: Don't modify `utils/` functions
2. **Use config for study parameters**: Add fields to `src/config.m` instead of hardcoding
3. **Log custom events**: Use `logEvent(logFile, 'INFO', 'YourEvent', ...)` for analysis
4. **Test in debug mode**: Set `debugMode=true` for windowed, no-save testing
5. **Use dev_smoke**: Run `scripts/dev_smoke` for quick iteration (2 trials only)
6. **Preserve timing semantics**: Keep `idealStimOnset` calculations unchanged for drift compensation

## Getting Help

- See `README.md` for architecture overview
- See `CLAUDE.md` for development guidelines
- Check existing utilities in `utils/` before writing custom code
- Run `scripts/list_devices` to inspect input device IDs
- Run `scripts/quick_check` to validate config without PTB
