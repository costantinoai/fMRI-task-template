# fMRI Task Template — Improvement Roadmap

**Generated**: October 2025
**Current branch**: `dev/template-hardening`
**Status**: Template is functional and well-structured; focus now on polish and edge case fixes

---

## Executive Summary

### Current State
- ✅ **Main script simplified**: 272 lines (was 541), boilerplate consolidated
- ✅ **Clear architecture**: 31 utilities in 5 workflow-aligned directories
- ✅ **Good test coverage**: 66% tests passing, core utilities well-covered
- ✅ **Complete documentation**: API reference, user guide, contributor guide, project plan

### Priorities
1. **Fix failing tests** (24 edge case failures) - improves reliability
2. **Further main script simplification** - reduce cognitive load for scientists
3. **Pre-run summary logging** - better reproducibility and debugging
4. **Minor polish** - memory hygiene, documentation cleanup

---

## Phase 1: Test Battery Cleanup (High Priority)

**Goal**: Achieve 95%+ test pass rate, document remaining gaps

### 1.1 Fix Boundary Condition Tests (1-2 hours)

**Issue**: Several tests fail on exact boundary conditions or edge cases

**Failing tests**:
- `testShouldSuppress/testExactWindowBoundary` - Boundary at exactly debounce window
- `testMakeTrialList/testNotDivisible` - Non-divisible trial counts
- `testMakeTrialListRandomization/testNoRandomization` - Omitted randomization field
- `testMakeTrialListExternalRun/testExternalRunPreserved` - External run column handling

**Action items**:
1. Review `shouldSuppress.m` logic for `<=` vs `<` comparison at boundary
2. Review `makeTrialList.m` divisibility check (use `~=` not `== 0`)
3. Add proper handling for omitted `stimRandomization` field
4. Fix external run column preservation in `makeTrialList.m`

**Acceptance**: All 4 test groups pass without errors

---

### 1.2 Complete Golden Test Assertions (30 min)

**Issue**: `testLogEventGolden/testHeaderFormat` passes but may have incomplete assertions

**Action items**:
1. Review golden test to ensure header tab count and exact column names verified
2. Add assertions for column order (not just presence)
3. Verify tab character (not spaces) between columns

**Acceptance**: Golden test explicitly checks all header invariants

---

### 1.3 Document PTB-Dependent Test Status (30 min)

**Issue**: Some tests fail/error due to PTB dependencies (queues, flips)

**Action items**:
1. Add `% REQUIRES PTB` comment to tests that need real PTB
2. Update test file headers explaining why some tests are skipped
3. Add note in CLAUDE.md about PTB mocking strategy for future

**Acceptance**: Clear documentation of which tests require PTB and why

---

## Phase 2: Main Script Simplification (Medium Priority)

**Goal**: Reduce main script below 250 lines, increase readability

### 2.1 Extract Trial Loop Boilerplate (1-2 hours)

**Current state**: Trial loop (lines 144-230 in fMRI_task.m) has repetitive setup code

**Opportunity**: Extract common patterns into helper functions

**Proposed changes**:
```matlab
% Current (many lines):
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

% Proposed (2-3 lines):
currentImage = getTrialImage(runImMat, i);
[VBL, actualStimOnset] = showTrialStimulus(win, winRect, params, in, currentImage, ...
    runTrials(i), logFile, debugMode, dbg);
```

**Functions to create**:
1. `getTrialImage(runImMat, trialIdx)` - Safe image extraction with bounds checking
2. `showTrialStimulus(...)` - Combines FillRect + displayTrial + optional overlay + Flip + logEvent
3. `showTrialFixation(...)` - Similar wrapper for fixation periods

**Benefits**:
- Trial loop becomes ~30 lines (from ~85)
- Easier to see trial structure at a glance
- Scientists can override display functions without touching loop

**Risks**:
- Must not change flip order or timing
- More indirection (tradeoff: explicitness vs conciseness)

**Acceptance**:
- Main script < 250 lines
- No change to log output (verify with check_invariants.sh)
- No timing changes (compare deltas before/after)

---

### 2.2 Consider Consolidating Fixation Display (30 min)

**Current state**: Three places call fixation display with similar patterns

**Opportunity**: Create single `showFixationPeriod` that handles FillRect + displayFixation + Flip + logEvent

**Proposed**:
```matlab
% Instead of:
Screen('FillRect', win, in.gray);
displayFixation(win, winRect, params, in);
if debugMode && dbg.overlay
    drawDebugOverlay(win, sprintf('Pre-fix | sub-%02d run-%02d', in.subNum, in.runNum), in);
end
VBL = Screen('Flip', win);
logEvent(logFile, 'FLIP', params.eventNames.preFix, dateTimeStr, '-', VBL - in.scriptStart, '-', '-');
runStart = VBL;
preRunTime = runStart - in.scriptStart;

% Use:
[VBL, runStart, preRunTime] = showFixationPeriod(win, winRect, params, in, ...
    'preFix', logFile, debugMode, dbg);
```

**Decision point**: Does this improve or obscure? Get feedback from lab members.

---

## Phase 3: Pre-Run Summary Logging (Medium Priority)

**Goal**: Log complete session configuration for reproducibility

### 3.1 Create Pre-Run Summary Function (2-3 hours)

**Purpose**: Log all relevant config parameters at start of each run

**Implementation**:
1. Create `utils/recording/logRunSummary.m`
2. Call after logging initialization, before instructions
3. Write as `INFO` rows in TSV log file
4. Optionally create sidecar JSON file with full params struct

**What to log**:
- Task metadata: taskName, subNum, runNum, timestamp
- Timing: stimDur, fixDur, prePost, numTrials
- Device codes: respKeysCode, triggerKeyCode, escapeKeyCode
- Screen geometry: resolution, PPD, frameRate
- Mode flags: debugMode, fmriMode, triggerPolicy
- Trial list info: numRepetitions, randomization, external run column presence
- Version info: MATLAB version, PTB version, template commit hash

**Output format** (TSV INFO rows):
```
INFO	Config	taskName	-	-	-	-	myexp
INFO	Config	stimDur	-	-	-	-	1
INFO	Config	fixDur	-	-	-	-	1
INFO	Screen	resolution	-	-	-	-	1920x1080
INFO	Screen	PPD	-	-	-	-	47.3
...
```

**Optional sidecar** (JSON):
```
data/sub-01/2025-10-12-14-30_sub-01_run-01_task-myexp_config.json
```

**Acceptance**:
- Summary logged at start of every run
- No impact on timing (logs before trigger wait)
- Easy to parse for analysis scripts

---

## Phase 4: Minor Polish (Low Priority)

### 4.1 Memory Hygiene - Close Textures (30 min)

**Issue**: `displayTrial.m` closes textures immediately (good), but could be more explicit

**Action**: Already done! Current code (line 52 in displayTrial.m):
```matlab
Screen('Close', imTexture);
```

**Verify**: Check if any other texture creation sites need cleanup. Search for `MakeTexture`.

---

### 4.2 Screen Setup Documentation (30 min)

**Issue**: Comments in `openScreen.m` may not match actual skipSyncTests behavior

**Action**:
1. Review `openScreen.m` skipSyncTests logic
2. Update comments to match actual behavior
3. Clarify when sync tests are skipped (debug vs release)

---

### 4.3 Function Header Examples (1-2 hours)

**Issue**: Some function headers have minimal or outdated examples

**Action**:
1. Review all 31 utility functions
2. Add/update "Example:" section in headers
3. Ensure examples show actual usage from fMRI_task.m

**Priority functions**:
- `waitAndCaptureInput`
- `logKeyPressDual`
- `adjustFixationDuration`
- `makeTrialList`

---

## Phase 5: Nice-to-Have Features (Future)

### 5.1 Keys-of-Interest Filtering (Optional)

**Purpose**: Reduce log noise on devices with many keys

**Design**:
```matlab
% In config.m:
cfg.keysOfInterest = [102, 106, 53, 27];  % Only log these codes

% In logKeyPressDual.m:
if ~isempty(params.keysOfInterest)
    if ~ismember(keyCode, params.keysOfInterest)
        continue;  % Skip logging
    end
end
```

**Use case**: Button boxes that send spurious codes, trigger artifacts

**Acceptance**: Optional feature, off by default, preserves all behavior when omitted

---

### 5.2 Side-Channel Marker Logging (Optional)

**Purpose**: Log parallel event markers (e.g., photodiode, eye tracker sync)

**Design**:
- Reuse `logEvent` TSV format
- Separate function `logMarker(logFile, markerType, markerValue, timestamp)`
- Scientists add calls in trial loop as needed

**Not a priority**: Scientists can already call `logEvent` directly

---

## Deferred Items (Out of Scope)

### PTB Mocking Framework
**Why deferred**: Requires significant infrastructure investment, low ROI for current needs
**Alternative**: Keep core utilities PTB-free where possible (already done for most)

### Headless End-to-End Tests
**Why deferred**: Milestone 1.3 excluded per project plan
**Alternative**: Use `scripts/dev_smoke` and manual verification

### Perfect Test Coverage
**Why deferred**: 66% coverage is good for a template, diminishing returns beyond 80%
**Priority**: Fix critical path tests, document gaps

---

## Summary of Actionable TODOs

### Immediate (Next Session)
1. ✅ Fix boundary condition test failures (shouldSuppress, makeTrialList) - 1h
2. ✅ Fix external run column preservation tests - 30min
3. ✅ Complete golden test assertions - 30min
4. ✅ Document PTB-dependent test status - 30min

### Short Term (Next Week)
5. ✅ Extract trial loop boilerplate (showTrialStimulus, showTrialFixation) - 2h
6. ✅ Consider fixation period consolidation (showFixationPeriod) - 30min
7. ✅ Review and simplify main script below 250 lines - 1h

### Medium Term (Next Month)
8. ✅ Implement pre-run summary logging - 3h
9. ✅ Screen setup documentation cleanup - 30min
10. ✅ Function header examples update - 2h

### Nice-to-Have (Future)
11. ⏸️ Keys-of-interest filtering (if requested by lab)
12. ⏸️ Side-channel marker logging (if needed)

---

## How to Use This Roadmap

**For contributors**:
- Pick items from "Immediate" or "Short Term" sections
- Check TODO.md for milestone alignment
- Run `scripts/check_invariants.sh` after changes
- Update this roadmap when priorities change

**For lab members**:
- Request features via GitHub issues
- Provide feedback on proposed simplifications (Section 2.2)
- Report bugs or edge cases not covered by tests

**For maintainers**:
- Review this quarterly
- Archive completed items
- Adjust priorities based on lab needs

---

## Success Metrics

**By end of current phase**:
- [ ] 95%+ test pass rate
- [ ] Main script < 250 lines
- [ ] Pre-run summary logging implemented
- [ ] All documentation up to date

**Long-term health**:
- Scientists can customize tasks without editing utils/
- New lab members onboard within 1 day
- No output format regressions across versions
- Template serves as reference for other labs
