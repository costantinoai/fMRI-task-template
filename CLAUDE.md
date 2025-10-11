# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an fMRI task template for MATLAB using Psychtoolbox (PTB). It runs one experimental run at a time, with precise timing control, comprehensive event logging, and dual-queue input handling for simultaneous trigger and response detection.

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

The `utils/` directory is organized by **researcher workflow** rather than technical domains:

- **`utils/setup/`** - Experiment configuration & trial design
  - `TaskConfig`, `validateParams`, `validateInstructionPlaceholders`
  - `makeTrialList`, `validateTrialList`, `determineButtonMapping`
  - `loadImages`

- **`utils/display/`** - Screen rendering & visual presentation
  - `displayInstructions`, `displayTrial`, `displayFixation`
  - `flipAndLog`, `resizeStim`

- **`utils/recording/`** - Data logging & response tracking
  - `createLogFile`, `logEvent`, `saveAndClose`
  - `logKeyPressDual`, `shouldSuppress`

- **`utils/hardware/`** - PTB initialization & device management
  - `initializePTB`, `setupScreen`, `configScreenCol`
  - `createInputQueues`, `listDevices`

- **`utils/lib/`** - Generic helper utilities
  - `dateTimeStr`, `zeroFill`, `convertVisualUnits`, `adjustFixationDuration`

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

### When Adding Features
1. **Plan first**: Use TODO.md milestone structure to define acceptance criteria
2. **Write tests**: Add unit tests in `tests/` before implementation; use `runtests` to validate
3. **Preserve outputs**: Compare log files before/after changes (same seed) to verify stability
4. **Error handling**: Use namespaced identifiers (`Params:*`, `File:*`, `Input:*`, `PTB:*`) and actionable messages
5. **Documentation**: Update function headers with Purpose/Inputs/Outputs/Errors; add inline comments for non-obvious logic

### When Refactoring
- Minimal diffs: Change one thing at a time
- No timing changes: Preserve flip order, onset calculations, and duration logic
- No output changes: Run debug mode before/after; compare TSV headers and event sequences
- DRY principle: Extract repeated logic into helpers, but keep `utils/` study-agnostic

### Study-Specific vs Generic
- **Study-specific** (lives in `fMRI_task.m` or `src/config.m`): Instructions text, fixation style, button mapping policy, task structure
- **Generic** (lives in `utils/`): Rendering primitives, logging, input queues, trial list mechanics, converters

### Testing Strategy
- **Unit tests** (in `tests/`): Pure functions without PTB (e.g., `adjustFixationDuration`, `makeTrialList`, `convertVisualUnits`)
- **Integration tests**: Use `scripts/quick_check` to validate config + trial list + subset image load without opening windows
- **End-to-end**: Future milestone includes headless harness with PTB stubs for full run simulation

## Common Pitfalls

1. **String vs numeric key codes**: Always use decimals (e.g., 102 not 'f'); logs format them at write time
2. **Button mapping caching**: `determineButtonMapping` is called once per run and stored in `runTrials`; don't call per trial
3. **Image preload with fixation trials**: Last item in stimulus list may be "fixation"; guard `im` usage in `loadImages`
4. **Instruction placeholders**: Must have exactly two `()` across all instruction lines; validated by `validateInstructionPlaceholders`
5. **Screen geometry**: `convertVisualUnits` uses hardcoded defaults unless `useScreenGeometry=true` and `scrDist/scrWidth` provided
6. **Trigger policy**: MRI scanners may send double triggers; configure `triggerPolicy` ('single', 'double', 'window') per site

## Project Status (Current Branch: dev/template-hardening)

See TODO.md for detailed milestones. Current focus:
1. Comprehensive testing (unit + integration + headless end-to-end)
2. Prep & Show abstractions (single entry points for instructions, trial, fixation)
3. Utility consolidation (domain folders, consistent naming, extension hooks)
4. Pre-run summary logging (visible config + sidecar JSON)

### Known Issues (from AGENTS.md)
- Some equality edge cases in timing functions need explicit handling
- Minor memory leaks from unclosed textures (non-critical but can accumulate)
- Comments vs behavior mismatches in screen setup (documentation debt)

## Quick Start Checklist

1. Set MATLAB working directory to repo root
2. Configure `src/config.m`: timing, task name, runs, key codes, device IDs
3. Prepare `src/list_of_stimuli.tsv` with `stimuli` column (and optional metadata columns)
4. Add image files to `src/stimuli/`
5. Run `scripts/quick_check` to validate config + trial list
6. Set `debugMode=true` in `fMRI_task.m` and run to test windowed
7. Set `debugMode=false, fmriMode=true` for scanner runs

## Additional Resources

- **README.md**: Comprehensive user guide with trial list, randomization, output format, timing logic
- **AGENTS.md**: Contributor guide with coding standards, backlog, and verification checklist
- **TODO.md**: Detailed project plan with milestones, acceptance criteria, and task breakdown
