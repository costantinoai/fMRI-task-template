# fMRI Task Template — Project Status

**Last updated**: October 2025
**Status**: ✅ **Production-ready**

---

## Template Philosophy

This template prioritizes **low cognitive load** for experimenters who need to build reliable fMRI tasks without becoming PTB experts.

**Core principles**:
1. **Workflow-oriented**: Each major step in the main script is one clear function call
2. **No boilerplate**: PTB complexity hidden in utilities, main script stays clean
3. **Easy to change**: Experimenters customize config, trial lists, and trial loop—not utilities
4. **Output invariants**: Log format, file naming, timing semantics never change

---

## Milestones

### ✅ Phase 1: Core Infrastructure (Complete)
- **Testing**: 67 tests, 100% pass rate
- **Utilities**: 34 functions across 5 workflow-aligned directories
- **Documentation**: Complete API reference, user guide, contributor guide

### ✅ Phase 2: Main Script Simplification (Complete)
- **Main script**: Reduced from 541 → 231 lines (-57%)
- **Trial loop**: Reduced from 85 → 46 lines (-46%)
- **Wrapper functions**: Created `showTrialStimulus`, `showFixationPeriod`, `getTrialImage`
- **Result**: Each operation is one clear, tidy function call

---

## Current Architecture

### Main Script (`fMRI_task.m`, 231 lines)

```matlab
% Session initialization
[params, in] = initializeSession(debugMode, fmriMode);
[in, dbg] = promptSubjectRun(params, debugMode, fmriMode, in);
in = prepareSession(params, in, debugMode);

% Hardware & logging
[win, winRect, in, inputDevs] = initializeHardware(params, in, debugMode, dbg);
logFile = createLogFile(in, debugMode, dbg);
logEvent(logFile, 'START', '-', dateTimeStr, '-', GetSecs - in.scriptStart, '-', '-');

% Trial preparation
trialList = makeTrialList(params);
imMat = loadImages(params, in, trialList);

% Instructions & trigger
showInstructions(win, winRect, params, in, logFile, inputDevs, respInst1, respInst2, debugMode, dbg);
waitForTrigger(win, winRect, params, in, logFile, inputDevs, debugMode, dbg);

% Trial loop
for i = 1:length(runTrials)
    % Show stimulus
    currentImage = getTrialImage(runImMat, i);
    [VBL, actualStimOnset] = showTrialStimulus(win, winRect, params, in, currentImage, ...
        runTrials(i), i, logFile, debugMode, dbg);
    runTrials(i).stimOnset = actualStimOnset;

    % Collect response
    [pressedKey, in, dbg] = waitAndCaptureInput(...);
    runTrials(i).response = pressedKey;

    % Show fixation
    fixDur = adjustFixationDuration(runTrials, i, params);
    [VBL, lateResponse, in, dbg] = showFixationPeriod(win, winRect, params, in, fixDur, ...
        logFile, inputDevs, debugMode, dbg);
end

% Cleanup
finalizeRun(params, in, logFile, runTrials, runImMat, debugMode);
```

**Philosophy**: Every line is either initialization, a single workflow step, or cleanup. No PTB primitives, no nested conditionals, no boilerplate.

### Utilities Organization (Workflow-Aligned)

```
utils/
├── setup/          # Configuration before run starts
│   ├── initializeSession.m
│   ├── promptSubjectRun.m
│   ├── prepareSession.m
│   ├── makeTrialList.m
│   └── loadImages.m
├── hardware/       # PTB initialization (hidden from main script)
│   ├── initPTB.m
│   ├── openScreen.m
│   └── createInputQueues.m
├── display/        # Visual presentation (customizable)
│   ├── showInstructions.m
│   ├── showTrialStimulus.m      # High-level wrapper
│   ├── showFixationPeriod.m     # High-level wrapper
│   ├── displayTrial.m           # Low-level primitive
│   └── displayFixation.m        # Low-level primitive
├── recording/      # Logging and input (hidden from main script)
│   ├── createLogFile.m
│   ├── logEvent.m
│   └── waitAndCaptureInput.m
└── lib/            # Generic helpers
    ├── adjustFixationDuration.m
    ├── getTrialImage.m          # Safe image extraction
    └── convertVisualUnits.m
```

**Philosophy**: Functions grouped by workflow stage, not technical domain. Scientists rarely edit utilities—they customize config and trial loop.

---

## What Scientists Customize

### Level 1: Configuration (90% of studies)
Edit `src/config.m` and `src/list_of_stimuli.tsv`:
- Timing parameters (`stimDur`, `fixDur`, `prePost`)
- Response key codes
- Instructions text
- Trial stimuli and metadata

### Level 2: Trial Loop Logic (Most common)
Edit trial loop in `fMRI_task.m` (lines ~144-190):
- Add feedback displays
- Add rating scales
- Conditional trial behavior

### Level 3: Display Behavior (Override wrappers)
Override `showTrialStimulus` or `showFixationPeriod` for:
- Custom stimulus rendering
- Non-standard timing
- Special visual effects

### Level 4: Trial List Generation
Create `src/makeTrialListCustom.m` for:
- Blocked designs
- Adaptive procedures
- Complex counterbalancing

**Key principle**: Customization happens in `src/` or main script, never in `utils/`.

---

## Output Invariants (Never Change)

These guarantee backward compatibility for analysis scripts:

1. **Log file format**: TSV with columns `EVENT_TYPE, EVENT_NAME, EVENT_ID, TRIAL, EXP_ONSET, ACTUAL_ONSET, DELTA, MSG`
2. **File naming**: `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME_log.tsv` and `.mat`
3. **Event names**: `Instr`, `TgrWait`, `Pre-fix`, `Stim`, `Fix`, `Post-fix`, `RESP`, `INFO`, `ERROR`
4. **`.mat` variables**: `params`, `in`, `runTrials`, `runImMat`
5. **Timing semantics**: `idealStimOnset` zero-aligned to run start, drift compensation logic

---

## Testing Strategy

**Current status**: 67 tests, 100% pass rate

- **Unit tests**: Pure functions (timing helpers, conversions, trial list generation)
- **Integration tests**: Config validation, trial list workflows (via `scripts/quick_check`)
- **Smoke tests**: Fast 2-trial deterministic runs (via `scripts/dev_smoke`)
- **Deferred**: PTB-dependent tests (require mocking framework, out of scope)

**Run tests**: `matlab -batch "addpath(genpath('.')); run_all_tests"`

---

## Development Guidelines

### When Adding Features

1. **Preserve outputs**: Compare log files before/after changes (same seed)
2. **Write tests first**: Add unit tests in `tests/` before implementation
3. **One thing at a time**: Minimal diffs, clear commit messages
4. **Update docs**: API.md for new functions, README.md for new workflows

### When Customizing for a Study

1. **Start with config**: Most needs met by `src/config.m` parameters
2. **Keep logic visible**: Study-specific code in main script, not hidden in utilities
3. **Test incrementally**: Run `debugMode=true` after each change
4. **Use dev tools**: `scripts/quick_check` for validation, `scripts/dev_smoke` for fast iteration

### Coding Standards

1. **One function per file**: Named after filename
2. **Error IDs**: Namespace:Specific (e.g., `Params:MissingField`)
3. **Function headers**: Purpose, Inputs, Outputs, Example, See also
4. **Workflow-aligned naming**: `showTrialStimulus`, not `renderAndFlipStimulus`

---

## Repository Structure

```
.
├── fMRI_task.m           # ⭐ Main script (231 lines)
├── src/
│   ├── config.m          # Experiment configuration
│   ├── list_of_stimuli.tsv
│   └── stimuli/
├── utils/                # 34 workflow-aligned functions
│   ├── setup/
│   ├── hardware/
│   ├── display/
│   ├── recording/
│   └── lib/
├── tests/                # 67 tests (100% pass rate)
├── scripts/              # Validation and debugging tools
│   ├── quick_check.m
│   ├── dev_smoke.m
│   └── list_devices.m
├── data/                 # Auto-created output directory
└── docs/
    ├── README.md         # User guide
    ├── API.md            # Function reference
    ├── CLAUDE.md         # AI assistant guide
    └── AGENTS.md         # Contributor guide
```

---

## Quick Start

1. **Configure**: Edit `src/config.m` (timing, key codes, instructions)
2. **Prepare stimuli**: Add images to `src/stimuli/`, list in `src/list_of_stimuli.tsv`
3. **Validate**: Run `scripts/quick_check` to verify configuration
4. **Test**: Set `debugMode=true` in `fMRI_task.m`, run `fMRI_task`
5. **Run**: Set `debugMode=false, fmriMode=true` for scanner

---

## No Future Development Needed

Template is complete and production-ready. No additional features planned.

**Focus**: Use it, adapt it for studies, report bugs if found.
