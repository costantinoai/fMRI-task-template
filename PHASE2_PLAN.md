# Phase 2: Main Script Simplification Plan

**Generated**: October 2025
**Branch**: `dev/template-hardening`
**Prerequisites**: Phase 1 complete (test fixes, 76.5% pass rate)

---

## Overview

**Goal**: Reduce main script cognitive load by extracting trial loop boilerplate into clearly-named wrapper functions.

**Target**: Main script < 250 lines (currently 272)
**Benefit**: Scientists can focus on trial structure, not PTB details
**Risk**: Must preserve exact timing and flip order

---

## Current State Analysis

### Main Script Structure (`fMRI_task.m`, 272 lines)

**Well-factored sections** (leave as-is):
- Lines 30-54: Mode flags and session init - ✅ Already clean
- Lines 56-67: Trial list and images - ✅ One function call each
- Lines 69-92: Hardware initialization - ✅ Three clear steps
- Lines 114-120: Instructions and trigger wait - ✅ Single-function calls

**Boilerplate-heavy section** (target for simplification):
- **Lines 144-230: Trial loop** (~85 lines, can reduce to ~40)
  - Lines 158-182: Stimulus display + flip + log (24 lines → 3 lines)
  - Lines 206-223: Fixation display + flip + log (17 lines → 3 lines)
  - Lines 232-244: Post-run fixation (similar pattern)

---

## Proposed Changes

###  1. Extract Stimulus Display Boilerplate

**Current code** (lines 158-182, 24 lines):
```matlab
Screen('FillRect', win, in.gray);
if ~isempty(runImMat) && i <= numel(runImMat)
    currentImage = runImMat(i);
else
    currentImage = [];
end
displayTrial(params, in, currentImage, runTrials(i), 1, win, winRect);
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Trial %d | %s', i, runTrials(i).stimuli), in);
end
VBL = Screen('Flip', win);
actualStimOnset = VBL - in.scriptStart;
logEvent(logFile, 'FLIP', params.eventNames.stimulus, dateTimeStr, ...
    runTrials(i).idealStimOnset, actualStimOnset, ...
    actualStimOnset - runTrials(i).idealStimOnset, runTrials(i).stimuli);
runTrials(i).stimOnset = actualStimOnset;
if debugMode && dbg.warnOnDrift
    drift = (actualStimOnset - runTrials(i).idealStimOnset) * 1000;
    if abs(drift) > dbg.driftWarnMs
        logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
            sprintf('Trial %d drifted %.1f ms', i, drift));
    end
end
```

**Proposed replacement** (3 lines):
```matlab
currentImage = getTrialImage(runImMat, i);
[VBL, actualOnset] = showTrialStimulus(win, winRect, params, in, currentImage, ...
    runTrials(i), i, logFile, debugMode, dbg);
runTrials(i).stimOnset = actualOnset;
```

**New function**: `utils/display/showTrialStimulus.m`
```matlab
function [VBL, actualOnset] = showTrialStimulus(win, winRect, params, in, image, trial, trialIdx, logFile, debugMode, dbg)
% SHOWTRIAL STIMULUS Display stimulus, flip, log timing, and optionally warn on drift
%
% Inputs:
%   win, winRect - PTB window
%   params       - Experiment parameters
%   in           - Session info (scriptStart, gray, colors)
%   image        - Preloaded image or []
%   trial        - Trial struct with idealStimOnset, stimuli
%   trialIdx     - Trial index (for debug overlay and warnings)
%   logFile      - Log file handle
%   debugMode    - Enable debug features
%   dbg          - Debug options (overlay, warnOnDrift, etc.)
%
% Outputs:
%   VBL          - Flip timestamp
%   actualOnset  - Onset relative to script start
%
% Example:
%   [VBL, onset] = showTrialStimulus(win, winRect, params, in, img, trial, 5, logFile, true, dbg);

% Fill background
Screen('FillRect', win, in.gray);

% Display trial content (stimulus or fixation)
displayTrial(params, in, image, trial, 1, win, winRect);

% Optional debug overlay
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Trial %d | %s', trialIdx, trial.stimuli), in);
end

% Flip and record timing
VBL = Screen('Flip', win);
actualOnset = VBL - in.scriptStart;

% Log flip event with timing delta
logEvent(logFile, 'FLIP', params.eventNames.stimulus, dateTimeStr, ...
    trial.idealStimOnset, actualOnset, ...
    actualOnset - trial.idealStimOnset, trial.stimuli);

% Optional drift warning
if debugMode && dbg.warnOnDrift
    drift = (actualOnset - trial.idealStimOnset) * 1000; % ms
    if abs(drift) > dbg.driftWarnMs
        logEvent(logFile, 'WARN', 'Drift', dateTimeStr, '-', '-', '-', ...
            sprintf('Trial %d drifted %.1f ms', trialIdx, drift));
    end
end

end
```

---

### 2. Extract Fixation Display Boilerplate

**Current code** (lines 206-223, 17 lines):
```matlab
Screen('FillRect', win, in.gray);
displayFixation(win, winRect, params, in);
fixDur = adjustFixationDuration(runTrials, i, params);
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Fixation (%.2fs)', fixDur * dbg.slowMoFactor), in);
end
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', params.eventNames.fixation, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');
[additionalKey, in, dbg] = waitAndCaptureInput(params, in, logFile, fixDur, inputDevs, debugMode, dbg);
if isnan(runTrials(i).response) && ~isempty(additionalKey)
    runTrials(i).response = additionalKey;
end
```

**Proposed replacement** (3 lines):
```matlab
fixDur = adjustFixationDuration(runTrials, i, params);
[VBL, lateResponse, in, dbg] = showFixationPeriod(win, winRect, params, in, fixDur, ...
    logFile, inputDevs, debugMode, dbg);
if isnan(runTrials(i).response) && ~isempty(lateResponse)
    runTrials(i).response = lateResponse;
end
```

**New function**: `utils/display/showFixationPeriod.m`
```matlab
function [VBL, keyPressed, in, dbg] = showFixationPeriod(win, winRect, params, in, duration, logFile, inputDevs, debugMode, dbg)
% SHOWFIXATIONPERIOD Display fixation, flip, log, and capture input during period
%
% Inputs:
%   win, winRect - PTB window
%   params       - Experiment parameters
%   in           - Session info
%   duration     - Fixation duration in seconds
%   logFile      - Log file handle
%   inputDevs    - Input queues
%   debugMode    - Enable debug features
%   dbg          - Debug options
%
% Outputs:
%   VBL          - Flip timestamp
%   keyPressed   - Key code if pressed during fixation, else []
%   in           - Updated session info
%   dbg          - Updated debug options
%
% Example:
%   [VBL, key, in, dbg] = showFixationPeriod(win, winRect, params, in, 1.5, logFile, inputDevs, false, dbg);

% Fill background and draw fixation
Screen('FillRect', win, in.gray);
displayFixation(win, winRect, params, in);

% Optional debug overlay
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Fixation (%.2fs)', duration * dbg.slowMoFactor), in);
end

% Flip and log
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', params.eventNames.fixation, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');

% Wait and capture input
[keyPressed, in, dbg] = waitAndCaptureInput(params, in, logFile, duration, inputDevs, debugMode, dbg);

end
```

---

### 3. Extract Helper Function

**New function**: `utils/lib/getTrialImage.m`
```matlab
function image = getTrialImage(runImMat, trialIdx)
% GETTRIALIMAGE Safely extract trial image from preloaded matrix
%
% Handles empty matrices and out-of-bounds indices gracefully.
%
% Inputs:
%   runImMat  - Cell array or struct array of preloaded images
%   trialIdx  - Trial index (1-based)
%
% Outputs:
%   image     - Image matrix/struct or [] if not available
%
% Example:
%   img = getTrialImage(runImMat, 5);

if isempty(runImMat) || trialIdx > numel(runImMat)
    image = [];
else
    image = runImMat(trialIdx);
end

end
```

---

## Implementation Steps

### Step 1: Create New Functions (30 min)
1. Create `utils/display/showTrialStimulus.m` with full header
2. Create `utils/display/showFixationPeriod.m` with full header
3. Create `utils/lib/getTrialImage.m` with full header
4. Add all three to API.md

### Step 2: Update Main Script (20 min)
1. Replace stimulus display block (lines 158-182) with 3-line call
2. Replace fixation display block (lines 206-223) with 4-line call
3. Do same for pre-run and post-run fixations (lines 122-142, 232-244)

### Step 3: Verify Invariants (20 min)
1. Run in debug mode, verify window displays correctly
2. Run `scripts/check_invariants.sh` - TSV format unchanged
3. Compare log file before/after (same seed) - identical FLIP rows
4. Compare timing deltas before/after - no drift introduced

### Step 4: Update Documentation (10 min)
1. Update API.md with new functions
2. Update CLAUDE.md "Main Script Structure" section
3. Update README.md example customization

---

## Expected Outcome

**Before**: 272 lines, trial loop spans 85 lines
**After**: ~235 lines, trial loop spans ~40 lines

**Line count breakdown**:
- Remove 24 lines (stimulus display) → +15 lines (function + headers) = -9 net
- Remove 17 lines (fixation display) → +12 lines (function + headers) = -5 net
- Remove 10 lines (helper) → +5 lines (function) = -5 net
- **Total savings**: ~20 lines in main script
- **Readability improvement**: Trial loop logic much clearer

**Trial loop becomes**:
```matlab
for i = 1:length(runTrials)
    % Timing setup
    trialStart = GetSecs;
    runTrials(i).idealStimOnset = preRunTime + runTrials(i).idealStimOnset;

    % Show stimulus
    currentImage = getTrialImage(runImMat, i);
    [VBL, actualOnset] = showTrialStimulus(win, winRect, params, in, currentImage, ...
        runTrials(i), i, logFile, debugMode, dbg);
    runTrials(i).stimOnset = actualOnset;

    % Collect response during stimulus
    [pressedKey, in, dbg] = waitAndCaptureInput(params, in, logFile, params.stimDur, inputDevs, debugMode, dbg);
    if ~isempty(pressedKey)
        runTrials(i).response = pressedKey;
    else
        runTrials(i).response = NaN;
    end

    % Show fixation
    fixDur = adjustFixationDuration(runTrials, i, params);
    [VBL, lateResponse, in, dbg] = showFixationPeriod(win, winRect, params, in, fixDur, ...
        logFile, inputDevs, debugMode, dbg);
    if isnan(runTrials(i).response) && ~isempty(lateResponse)
        runTrials(i).response = lateResponse;
    end
end
```

**Much easier to understand**:
- "Show stimulus" - one function
- "Collect response" - one function
- "Show fixation" - one function

---

## Risks & Mitigation

### Risk 1: Timing Changes
**Mitigation**:
- No new flips introduced
- All GetSecs calls preserved
- Same order of operations
- Verify with log file comparison

### Risk 2: Hidden Complexity
**Mitigation**:
- Function names clearly describe what they do
- Headers include full parameter documentation
- API.md provides quick reference
- Original patterns still visible in wrapper functions

### Risk 3: Scientists Need to Override
**Mitigation**:
- Wrappers are just convenience - can bypass by copying original code
- Wrappers accept all parameters explicitly (no hidden state)
- CLAUDE.md documents when/how to override

---

## Alternative Considered (Rejected)

### Option: Create "Trial Display Manager" Class
**Why rejected**:
- Over-engineering for a template
- MATLAB classes add cognitive load
- Scientists less familiar with OOP
- Prefer explicit function calls

### Option: Consolidate ALL fixations into one function
**Why rejected**:
- Pre-run, inter-trial, and post-run fixations have different contexts
- Would need many conditional flags
- Loses clarity ("which fixation am I looking at?")

---

## Success Criteria

- [ ] Main script < 250 lines
- [ ] Trial loop < 45 lines
- [ ] Zero changes to log TSV format (verified by check_invariants.sh)
- [ ] Timing deltas identical to before (±1ms acceptable, floating point)
- [ ] API.md updated with 3 new functions
- [ ] All existing tests still pass

---

## Future Enhancements (Out of Scope for Phase 2)

- Pre-run fixation could also use `showFixationPeriod` (needs special handling for runStart)
- Could add `showBlankScreen` for custom inter-block periods
- Could parameterize overlay text format

---

## Timeline

- **Step 1**: 30 min - Create new functions
- **Step 2**: 20 min - Update main script
- **Step 3**: 20 min - Verify invariants
- **Step 4**: 10 min - Update docs

**Total**: ~80 minutes (1.5 hours)

---

## Questions for User Before Starting

1. **Naming preference**: `showTrialStimulus` vs `displayAndLogStimulus` vs `presentTrialStimulus`?
2. **Scope**: Also simplify pre-run/post-run fixations, or leave those explicit?
3. **Priority**: Do this before or after remaining test fixes?

Default answers if not specified:
1. Use `showTrialStimulus` (matches existing `showInstructions`)
2. Simplify all fixation displays consistently
3. Do Phase 2 now (tests at 76% is good enough; remaining failures are edge cases)
