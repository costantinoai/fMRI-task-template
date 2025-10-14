# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an **fMRI task template** for MATLAB using Psychtoolbox (PTB). It runs one experimental run at a time, with precise timing control, comprehensive event logging, and dual-queue input handling for simultaneous trigger and response detection.

### Template Philosophy

**Purpose**: Enable less-experienced neuroscientists to quickly build reliable visual fMRI experiments without becoming PTB experts.

**Design principles**:
1. **Low cognitive load** - Main script (`fMRI_task.m`) focuses on task logic, not boilerplate
2. **Explicit workflow** - Each major step is a separate, clearly-named function call
3. **Hidden complexity** - Screen setup, debug modes, input queues wrapped in utilities
4. **Study-specific flexibility** - Easy to customize what matters (timing, stimuli, trial structure)
5. **Robust defaults** - Works out-of-box for typical visual studies

**Target users**: Lab members running visual experiments (block or event-related designs) who need to customize timing, stimuli, and basic trial structure, but don't want to deal with PTB internals.

**Key principle**: Output invariants are sacred. Never alter log file format (headers, column order, event names), file naming patterns, or `.mat` variable structures.

## Commands

### Testing and Validation
```matlab
% Run all tests (from repo root)
run_all_tests

% Quick configuration check (no PTB window)
scripts/quick_check

% Test individual components
runtests('tests/testMakeTrialList.m')
runtests('tests/testAdjustFixationDuration.m')
```

### Running the Task
```matlab
% Debug mode (windowed, no save)
% Edit fMRI_task.m: debugMode = true, fmriMode = false
fMRI_task

% Production mode (scanner)
% Edit fMRI_task.m: debugMode = false, fmriMode = true
fMRI_task
```

### Utility Scripts
```matlab
% List all input devices (helpful for device ID binding)
scripts/list_devices

% Detect button codes interactively
scripts/detect_button_codes

% Pretty-print log file (TSV with aligned columns)
scripts/pretty_log('data/sub-01/..._log.tsv')
```

## Architecture

### Critical Data Flow
1. **Configuration**: `src/config.m` returns a struct → `TaskConfig.load` validates and produces `params`
2. **Trial list**: `makeTrialList` reads `src/list_of_stimuli.tsv`, applies repetitions/randomization, assigns run numbers
3. **Timing**: Each event has `idealStimOnset` (zero-aligned to run start); `adjustFixationDuration` compensates for drift
4. **Logging**: All flips, key presses, and errors logged via `logEvent` → `createLogFile` manages TSV output
5. **Input**: Dual queues (`createInputQueues`) → `logKeyPressDual` polls both trigger and response devices, logs all events by timestamp
6. **Output**: Per-run `.mat` (contains `params`, `in`, `runTrials`, `runImMat`) + `_log.tsv`

### Main Script Structure (`fMRI_task.m`)
- **Setup** (lines 30-100): Mode flags, path checks, config load, param validation
- **Subject/run input** (lines ~100-150): Prompts, directory creation, button mapping
- **Screen & logging** (lines ~150-220): PTB init, screen setup, log file creation
- **Trial list & images** (lines ~220-280): Build trial list, load/resize images
- **Instructions** (lines ~280-320): Display instructions, wait for user to continue
- **Trigger wait** (lines ~320-360): Wait for scanner trigger (policy: 'single', 'double', or 'window')
- **Pre-run fixation** (lines ~360-380): Show fixation for `params.prePost` seconds
- **Trial loop** (lines ~380-480): For each trial: show stimulus, collect response, show fixation (with drift compensation)
- **Post-run fixation** (lines ~480-500): Final fixation period
- **Save & cleanup** (lines ~500+): Write `.mat` file, close PTB, restore input

### Utilities Organization (Workflow-Aligned)

The `utils/` directory is organized by **researcher workflow** rather than technical domains. Scientists should rarely need to modify these utilities.

**Setup** (`utils/setup/`) - Configure before run starts
- `initializeSession` - One-shot: load config, validate params, setup paths
- `promptSubjectRun` - Get subject/run numbers (or defaults in debug)
- `prepareSession` - Create session metadata struct, output directory
- `makeTrialList` - Build trial list from stimulus TSV with repetitions/randomization
- `loadImages` - Preload and resize all images
- `TaskConfig`, `validateParams`, `determineButtonMapping` - Support functions

**Hardware** (`utils/hardware/`) - PTB initialization (hidden from main script)
- `initPTB` - Clean PTB state
- `createInputQueues` - Setup dual queues for trigger/response
- `openScreen` - Open window, configure colors, compute PPD
- `listDevices` - Helper to find device IDs

**Display** (`utils/display/`) - Visual presentation (customizable)
- `showInstructions` - Display instructions, wait for continue
- `waitForTrigger` - Display trigger wait, consume scanner triggers
- `showTrialStimulus` - High-level: display stimulus, flip, log with drift warnings
- `showFixationPeriod` - High-level: display fixation, flip, log, capture input
- `displayTrial` - Low-level: render stimulus or fixation to back buffer
- `displayFixation` - Low-level: draw fixation element (study-specific: edit in config or override)
- `drawDebugOverlay` - Optional debug text overlay

**Recording** (`utils/recording/`) - Logging and input (hidden from main script)
- `createLogFile` - Open log file, write TSV header
- `logEvent` - Write event row (FLIP, RESP, INFO, ERROR)
- `waitAndCaptureInput` - Wait and log all keypresses during period
- `logKeyPressDual` - Poll dual queues, apply debouncing
- `saveAndClose` - Save .mat, close log, cleanup PTB

**Lib** (`utils/lib/`) - Generic helpers
- `adjustFixationDuration` - Drift compensation
- `convertVisualUnits` - Deg ↔ px conversions
- `getTrialImage` - Safe image extraction with bounds checking
- `dateTimeStr`, `resizeStim`, `shouldSuppress` - Utilities

**What scientists typically customize**:
1. `src/config.m` - Timing, key codes, instructions text
2. `src/list_of_stimuli.tsv` - Trial stimuli and metadata
3. Trial loop in `fMRI_task.m` - For feedback, rating scales, etc.
4. `showTrialStimulus` or `showFixationPeriod` - To change trial display behavior
5. `displayFixation` or `displayTrial` - For custom visual elements (lower-level)

**Note**: All subdirectories are automatically added to MATLAB path via `addpath(genpath('utils'))`

## Key Constraints

### Output Invariants (Never Change)
1. **Log file format**: Header row and column order from `logEvent` (EVENT_TYPE, EVENT_NAME, EVENT_ID, TRIAL, EXP_ONSET, ACTUAL_ONSET, DELTA, MSG)
2. **File naming**: `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME_log.tsv` and `.mat`
3. **Event names**: `Instr`, `TgrWait`, `Pre-fix`, `Stim`, `Fix`, `Post-fix`, `RESP`, `FLIP`, `INFO`, `ERROR`
4. **`.mat` variables**: `params`, `in`, `runTrials`, `runImMat` (fields within these structures)
5. **Timing semantics**: `idealStimOnset` computation, `ACTUAL_ONSET` alignment to script start, drift compensation logic

### Timing Arithmetic
- All `idealStimOnset` values are zero-aligned to run start (`runStart` timestamp)
- Logged `ACTUAL_ONSET` is aligned to script start (`in.scriptStart`) for full session context
- `adjustFixationDuration` corrects next fixation duration by `delta = actualOnset - idealStimOnset`
- Equality case: when `delta == 0`, return `params.fixDur` unchanged
- Do not alter flip order or introduce extra flips

### Input Handling
- **Key codes**: Always use decimal codes (e.g., 102 for 'f', 106 for 'j', 53 for '5')
- **Dual queues**: Separate trigger and response queues to capture simultaneous events
- **Device binding**: `deviceIDs.trigger` and `deviceIDs.response` in `src/config.m` map to PsychHID indices
- **Debounce**: `shouldSuppress` suppresses repeated keys within `debounceWindowMs`
- **Escape**: ESC key (27) aborts run, logs `RESP Escape`, raises `ScriptExecution:ManuallyAborted`

### Configuration (`src/config.m`)
- Returns a struct; `TaskConfig.load(cfgPath, fmriMode)` validates and applies mode selection
- Required fields: `stimDur`, `fixDur`, `prePost`, `taskName`, `numRuns`, `stimListFile`, `numRepetitions`
- Mode-specific codes: `buttonsFMRI`, `triggerKeyMRICode` (fmriMode=true) vs `buttonsPC`, `triggerKeyPCCode` (fmriMode=false)
- Placeholders in instructions: Must include exactly two `()` across all `instructionsTextN` lines

## Development Guidelines

### Simplifying the Main Script

The main script (`fMRI_task.m`) should be **readable by non-programmers**. Follow these principles:

1. **Hide boilerplate** - Wrap screen setup, debug mode logic, device initialization in single-call functions
2. **One function per workflow step** - E.g., `initializeSession`, `promptSubjectRun`, `showInstructions`, `waitForTrigger`
3. **No nested conditionals for modes** - Mode selection happens in utilities, not main script
4. **Explicit trial loop** - Keep trial loop visible and easy to modify (this is where studies differ most)
5. **Meaningful names** - Function names should match what scientists think they're doing ("show", "wait", "capture", not "renderBuffer" or "pollQueue")

**Anti-patterns to avoid**:
- Inline PTB calls that could be wrapped (e.g., `Screen('FillRect')` → `displayFixation`)
- Debug mode conditionals scattered throughout (wrap in functions instead)
- Long comment blocks explaining PTB internals (use function names as documentation)
- Proliferation of similar functions (e.g., `displayInstructions1`, `displayInstructions2` - parameterize instead)

### When Adding Features
1. **Plan first**: Use TODO.md milestone structure to define acceptance criteria
2. **Write tests first**: Add unit tests in `tests/` before implementation; use `runtests` to validate
3. **Preserve outputs**: Compare log files before/after changes (same seed) to verify stability
4. **Error handling**: Use namespaced identifiers (`Params:*`, `File:*`, `Input:*`, `PTB:*`) and actionable messages
5. **Documentation**: Update API.md, function headers, and add inline comments only for non-obvious logic

### When Refactoring
- **Minimal diffs**: Change one thing at a time
- **No timing changes**: Preserve flip order, onset calculations, and duration logic
- **No output changes**: Run debug mode before/after; compare TSV headers and event sequences
- **DRY principle**: Extract repeated logic into helpers, but keep `utils/` study-agnostic
- **Test coverage**: Add tests before refactoring to catch regressions

### Study-Specific vs Generic

**Study-specific** (lives in `fMRI_task.m` or `src/config.m`):
- Instructions text and placeholders
- Fixation style, size, and position
- Button mapping policy (counterbalancing)
- Task structure (trial loop modifications, feedback, rating scales)
- Custom trial list generation (blocking, adaptive designs)

**Generic** (lives in `utils/`):
- PTB initialization and screen setup
- Input queue management and debouncing
- Logging infrastructure (TSV format, file creation)
- Trial list mechanics (repetitions, randomization)
- Visual unit conversions and timing compensation

**Rule of thumb**: If every study in the lab will use it identically, it's generic. If some studies will customize it, make it easy to override.

### Testing Strategy
- **Unit tests** (`tests/`): Pure functions without PTB (e.g., `adjustFixationDuration`, `makeTrialList`, `convertVisualUnits`)
- **Integration tests**: `scripts/quick_check` validates config + trial list + subset image load without PTB windows
- **Smoke tests**: `scripts/dev_smoke` runs 2 deterministic trials for fast iteration
- **Invariant tests**: `scripts/check_invariants.sh` verifies TSV format, file naming unchanged

### Test Coverage Assessment

**Current status** (67 tests, 100% pass rate):
- ✅ **Strong coverage**: Timing helpers, conversions, button mapping, logging format
- ✅ **Good coverage**: Trial list generation, session prep, parameter validation
- ✅ **Fixed**: All boundary condition tests, external run preservation, golden format tests
- ⚠️ **Deferred**: PTB-dependent tests (input queues, flip timing) require mocking framework
- ⚠️ **Deferred**: End-to-end headless harness (out of scope)

## Common Pitfalls

1. **String vs numeric key codes**: Always use decimals (e.g., 102 not 'f'); logs format them at write time
2. **Button mapping caching**: `determineButtonMapping` is called once per run and stored in `runTrials`; don't call per trial
3. **Image preload with fixation trials**: Last item in stimulus list may be "fixation"; guard `im` usage in `loadImages`
4. **Instruction placeholders**: Must have exactly two `()` across all instruction lines; validated by `validateInstructionPlaceholders`
5. **Screen geometry**: `convertVisualUnits` uses hardcoded defaults unless `useScreenGeometry=true` and `scrDist/scrWidth` provided
6. **Trigger policy**: MRI scanners may send double triggers; configure `triggerPolicy` ('single', 'double', 'window') per site

## Project Status (Current Branch: dev/template-hardening)

**Template is feature-complete and production-ready.** All major refactoring phases complete.

**Completed milestones**:
1. ✅ Comprehensive testing (100% pass rate, 67 tests)
2. ✅ Prep & Show abstractions (workflow functions reduce boilerplate)
3. ✅ Utility consolidation (5 workflow-aligned folders, consistent APIs)
4. ✅ Trial loop simplification (wrapper functions reduce cognitive load)

## Quick Start Checklist

1. Set MATLAB working directory to repo root
2. Configure `src/config.m`: timing, task name, runs, key codes, device IDs
3. Prepare `src/list_of_stimuli.tsv` with `stimuli` column (and optional metadata columns)
4. Add image files to `src/stimuli/`
5. Run `scripts/quick_check` to validate config + trial list
6. Set `debugMode=true` in `fMRI_task.m` and run to test windowed
7. Set `debugMode=false, fmriMode=true` for scanner runs

## Additional Resources

- **API.md**: Complete function reference organized by workflow stage
- **README.md**: User guide with configuration, trial lists, customization examples
- **AGENTS.md**: Contributor guide with coding standards and verification checklist
- **TODO.md**: Project roadmap with milestones and task breakdown

## Current State Summary (October 2025)

**Main script**: 231 lines (was 541 before refactoring, -57% reduction)
- ✅ Boilerplate consolidated into workflow functions
- ✅ Trial loop reduced from 85 → 46 lines (-46% cognitive load)
- ✅ Clear separation: setup → hardware init → trial loop → save
- ✅ Comments focus on "what" and "why", not PTB internals
- ✅ Each operation is one clear function call

**Utilities**: 34 functions across 5 workflow-aligned directories
- ✅ Each major step is one function call (e.g., `initializeSession`, `showTrialStimulus`)
- ✅ High-level wrappers (`showTrialStimulus`, `showFixationPeriod`) reduce boilerplate
- ✅ Low-level functions (`displayTrial`, `displayFixation`) remain accessible for customization
- ✅ Consistent error identifiers and comprehensive help headers
- ✅ Mode selection (debug/fmri) hidden in utilities

**Testing**: 67 tests, 100% pass rate
- ✅ All core utilities well-covered (timing, conversions, trial lists, logging)
- ✅ All edge cases fixed (boundary conditions, external runs, golden format)
- ✅ Integration tests validate config + trial list workflows
- ⚠️ PTB-dependent tests deferred (require mocking framework, out of scope)

**Documentation**: 3 core files + API reference
- ✅ CLAUDE.md: Template philosophy, development guidelines, workflow architecture
- ✅ API.md: Complete function reference organized by workflow stage
- ✅ README.md: User-facing guide with examples and customization patterns
- ✅ AGENTS.md: Contributor guide with coding standards

**Template is production-ready.** No additional features planned.
