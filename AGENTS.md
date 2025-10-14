# fMRI Task Template — Contributor Guide

This guide is for developers improving the template infrastructure. If you're a scientist customizing this for your study, see README.md instead.

## Project Goals

### Primary Goals
1. **Beginner-friendly** - Scientists with minimal MATLAB/PTB experience can build reliable scanner tasks
2. **Low cognitive load** - Main script is readable, with complexity hidden in utilities
3. **Robust by default** - Works reliably on scanner and PC with minimal configuration
4. **Output stability** - Never break existing log files, naming conventions, or timing behavior

### Non-Goals
- ❌ Supporting non-visual paradigms (auditory, multi-modal require different architecture)
- ❌ Real-time adaptive designs (would complicate timing guarantees)
- ❌ Advanced PTB features (movies, shaders, etc. - let scientists add these themselves)
- ❌ Perfect abstraction - prefer explicit workflow over over-engineered generalization

## Sacred Invariants (Never Change)

These outputs must remain exactly stable across versions:

1. **File naming**: `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME_log.tsv` and `.mat`
2. **TSV format**: Header row and column order from `logEvent` unchanged
3. **Event names**: `Instr`, `TgrWait`, `Pre-fix`, `Stim`, `Fix`, `Post-fix`, `RESP`, `FLIP`, `INFO`, `ERROR`
4. **`.mat` variables**: `params`, `in`, `runTrials`, `runImMat` fields unchanged
5. **Timing semantics**: `idealStimOnset` computation, drift compensation logic
6. **ACTUAL_ONSET alignment**: All onsets logged relative to `in.scriptStart`

## Quickstart (Developers)

- Requirements: MATLAB (R2020b+ recommended), Psychtoolbox 3, access to a local display.
- Main entrypoint: `fMRI_task.m` (one run per invocation).
- Configure before running: set `debugMode`, `fmriMode` at the top of `fMRI_task.m`.
- Assets and parameters:
- `src/config.m` defines `params.*` variables (loaded via `TaskConfig.load`).
  - `src/list_of_stimuli.tsv` provides stimuli and optional columns (e.g., `setting`).
  - Stimuli under `src/stimuli/`.
- Outputs (debugMode == false): under `data/sub-XX/`
  - `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME_log.tsv`
  - `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME.mat`

## Repository Structure (Responsibilities)

- `fMRI_task.m`: orchestrates the run lifecycle, logging, timing control.
- `utils/`:
  - Environment & screen: `initializePTB`, `setupScreen`, `configScreenCol`.
  - Input & logging: `createInputQueues`, `logKeyPressDual`, `flipAndLog`, `logEvent`, `createLogFile`, `detectKeyboard`.
  - Trials & stimuli: `makeTrialList`, `loadImages`, `displayTrial`, `displayFixation`, `resizeStim`.
  - Parameters & helpers: `TaskConfig`, `validateParams`, `convertVisualUnits`, `dateTimeStr`, `zeroFill`, `determineButtonMapping`, `adjustFixationDuration`, `saveAndClose`.
- `src/`: MATLAB config, stimuli and README figures.

## Coding Standards

- Function style
  - One public function per `.m` file, named after the file.
  - Start with a clear help block (purpose, inputs/outputs, examples).
  - Validate inputs at the top; fail early with `error(identifier, message)`.
  - Avoid hidden state; pass `params`, `in`, and handles explicitly.

- Error handling
  - Use meaningful identifiers: e.g., `Params:MissingField`, `Input:InvalidMode`.
  - Provide actionable remediation in error messages (what is wrong and how to fix).
  - In the top‑level script, keep the try/catch that logs the extended stack trace.

- Logging
  - Never alter `logEvent` output formatting or header order.
  - Log all flips and key events; error logs must include full stack traces.

- DRY (avoid duplication)
  - Prefer single implementations parameterized with options (e.g., keyboardID) over platform‑specific copies.
  - Extract repeated logic into helpers where practical.

- Timing & determinism
  - Do not change timing arithmetic or flip order when refactoring.
  - When fixing bugs, keep the computed `idealStimOnset`/`ACTUAL_ONSET` semantics intact.

## Study‑Specific vs Generic Code

- Keep study‑specific choices in the main script (`fMRI_task.m`) and config (`src/config.m`):
  - Instructions text and placeholders
  - Fixation style/size and any custom overlays
  - Button mapping policy (which side corresponds to which instruction)
  - Run structure (number of runs, repetitions, trial timing)

- Keep utilities in `utils/` study‑agnostic:
  - Rendering primitives, logging, input queues, trial list mechanics, converters
  - Utilities must not hard‑code study semantics (e.g., “inside/outside”)

- Rule of thumb: if it’s likely to change per study, surface it in `fMRI_task.m` or config; if it’s plumbing, keep it in `utils/`.

## Commenting & Documentation Style

- Audience: MATLAB users with little/no PTB or neuro‑experiments background.
- In `fMRI_task.m`, prefer step‑by‑step inline comments explaining why each block exists (screen init, timing, logging, responses, flips).
- In `utils/`, include a concise header help block, argument validation notes, and 1–2 inline comments at tricky spots (e.g., queue polling, conversions).
- Use consistent section headers (e.g., `%% INSTRUCTIONS`) and short summaries.

## Branching & Workflow

- Branching model
  - Default branch: `main`
  - Development branches: `dev/<topic>`, e.g., `dev/template-hardening` (current)

- Commits
  - Small, focused commits with imperative messages: “Fix key logging on Windows”
  - Reference the acceptance criteria from the backlog items where applicable.

- Reviews
  - Use this AGENTS.md for expectations; verify output invariants before merging.

## Running and Debugging

- `debugMode == true`:
  - Runs in a windowed mode; does not write outputs.
  - Use to iterate on task logic and instruction rendering.
- `fmriMode == true`:
  - Uses MRI screen distance/width and MRI buttons.
- Device IDs: Configure `deviceIDs.trigger` and `deviceIDs.response` in `src/config.m` to bind queues to specific devices (works across OSes). Dual queues ensure simultaneous trigger+button presses are both logged.

If keyboard input becomes unresponsive after a crash, re‑enable with `ListenChar(0)`.

## Current State (October 2025)

### What's Working Well
- ✅ **Main script**: Reduced from 541 → 272 lines via consolidation
- ✅ **Utilities**: 31 functions in workflow-aligned directories
- ✅ **Testing**: 71 tests with 66% pass rate covering core utilities
- ✅ **Documentation**: API.md, README, CLAUDE, TODO all up to date
- ✅ **Timing**: Drift compensation, dual queues, comprehensive logging
- ✅ **Robustness**: Config validation, error identifiers, failsafe cleanup

### Known Issues

**Test failures** (24 tests, mostly edge cases):
- Boundary condition bugs (shouldSuppress, makeTrialList divisibility edge cases)
- External run column preservation needs fixes
- Golden header test assertion incomplete
- PTB-dependent tests skipped (requires mocking framework)

**Documentation debt**:
- Screen setup comments don't match behavior (SkipSyncTests)
- Some function headers need examples updated

**Nice-to-have improvements**:
- Texture closing in displayTrial (memory hygiene)
- Pre-run summary logging (Milestone 5)
- Keys-of-interest filtering for noisy devices

## Output Invariants (Must Not Change)

- File naming schema in `data/sub-XX/` (time tag, subject/run, task name).
- `logEvent` header and row formatting, including event names and column order.
- `.mat` variable names and structures saved by `saveAndClose`.
- Event timing semantics and deltas in the logs.

## Backlog (Proposed)

The following tasks are proposed to improve reliability, simplicity, and maintainability while preserving outputs exactly. Each item includes constraints and acceptance criteria.

- Configuration system
- MATLAB configuration via `src/config.m` loaded by `TaskConfig.load`. Constraint: do not change outputs or parameter names consumed by the task. Acceptance: task runs identically to previous defaults.
  - Add a dedicated validator `validateParams(params, fmriMode)` that checks presence, type, and valid ranges; fail early with actionable errors. Acceptance: identical behavior on valid configs; clearer failures on invalid configs.

- Numeric key codes and mappings
  - Represent keys internally as decimal key codes (HID/OS key codes), not characters; avoid ambiguous conversions. Keep log text unchanged by formatting codes at log time exactly as today. Acceptance: identical log lines; internal representation uses numeric codes.
- Provide a canonical key map stored in code or config struct with decimal codes for: digits (up to 10 buttons) and colors `r,b,g,y` for supported devices. Allow selecting a subset per device/box. Acceptance: one source of truth; mappings selectable via config without changing logs.
  - Config: support up to 10 buttons via labels (e.g., "1".."10") and/or `buttonDecimalCodes` override to directly use device codes (e.g., 53 for '5'). Acceptance: both forms supported; no change in logs.

- Dual input queues (no missed simultaneous events)
  - Create separate queues for scanner triggers and response buttons (configurable device indices). Poll both and log all events, merging by timestamp so simultaneous trigger+button presses are both recorded. Constraint: do not alter event names or columns. Acceptance: reproduce a scenario with simultaneous events and confirm both are logged in order.

- Reliability: key logging
  - Use a single dual‑queue logger (`logKeyPressDual`) with device selection via config; no platform‑specific duplication. Acceptance: works on macOS and Windows; identical logs for the same inputs.

- Reliability: timing helpers
  - Handle equality branch in `adjustFixationDuration` (return `params.fixDur` when on time). Acceptance: no NaNs/empties; logs unchanged where equality did not previously occur.

- Correctness: trial list
  - Fix divisibility check to `if mod(height(stimList), params.numRuns) ~= 0`, with a clear `Params:InvalidRuns` error identifier. Acceptance: same behavior when divisible; meaningful error when not.
  - Cache `determineButtonMapping` per (sub,run) to avoid 4 calls per trial; add micro‑benchmark in comments. Acceptance: no behavior change; simpler code.

- Robustness: image loading
  - Guard the `im` usage after loop to avoid errors when last item is a fixation; set `params.imWidth/Height` only when applicable and avoid side effects (or document as no‑op). Acceptance: behavior unchanged; no error when list ends with fixation.

- Instructions
  - In `fMRI_task.m`, take `respInst1/2` from the first trial of the run (no `unique`). Acceptance: instruction rendering unchanged in typical cases; remove accidental cell outputs.

- Screen setup
  - Align `SkipSyncTests` documentation and intent with current numeric values (do not flip actual values to avoid timing changes). Acceptance: comments updated; behavior unchanged.

- Memory hygiene
  - Close transient textures in `displayTrial` after `Screen('DrawTexture', ...)`/flip. Acceptance: memory usage improved; no change in visual output or logs.

- Error messages
  - Standardize identifiers/messages across `utils/*`: missing fields use `*:ParamsMissing`, missing files `File:NotFound`, invalid mode `Input:InvalidMode`. Acceptance: clearer errors; no change when no error occurs.

- Developer ergonomics
  - Replace interactive directory prompts in `fMRI_task.m` with clear fail‑early errors that instruct how to fix; keep current default behavior if paths exist. Acceptance: non‑interactive by default; same behavior on valid setups.

- Documentation
  - Clarify parameter expectations in `README.md` (e.g., `respInst*` types, use of placeholders) and Mac notes; add short “first run” checklist. Acceptance: docs updated; code unchanged.
  - Add `scripts/quick_check.m` instructions to README; ensure it validates config, trial list, and a small image subset without opening PTB windows. Acceptance: script runs and reports status.
  - Add an educational commenting pass to `fMRI_task.m` and key utils (`logKeyPress`, `setupScreen`, `displayTrial`) for PTB newcomers. Acceptance: more inline comments; no functional changes.

- Optional (guarded by flags, off by default)
  - Add a `STRICT_VALIDATION` flag to perform additional runtime checks without changing output (default off). Acceptance: when off, behavior unchanged; when on, better diagnostics.
  - Add `preloadImages` boolean (default true) to allow on-demand image loading for large datasets (memory-friendly). Acceptance: when true, behavior unchanged; when false, identical outputs with lower peak memory.
  - Add `useScreenGeometry` (default false) to compute deg↔px from actual screen geometry; requires `scrDist`, `scrWidth`, and optional `scrHeight`. Acceptance: when false, behavior unchanged; when true, conversions use measured geometry without altering log formats.

- Centralization & simplification
  - Extract general logic from `fMRI_task.m` (e.g., run segmentation, instruction prep, event flip+log) into helpers to reduce duplication; ensure no timing changes. Acceptance: smaller main script; same flips/logs.
  - Replace brittle constructs with built‑ins or clearer logic (e.g., correct `mod` checks, use early returns, prefer `ismember`/string arrays with exact matching). Acceptance: behavior unchanged on valid input; fewer edge‑case bugs.
  - Surface study‑specific toggles at the top of `fMRI_task.m` (e.g., fixation style, instructions, mapping policy) with clear comments; ensure `utils/` remain study‑agnostic. Acceptance: easier onboarding; unchanged behavior.

## Implementation Notes

- When refactoring, prefer minimal diffs and preserve public function signatures.
- Use `error(id, msg)` over `disp` for fatal conditions; log via `logEvent` where applicable before raising.
- Avoid changing numeric precision/rounding that could impact logged values.
- Do not change `dateTimeStr` format or consumption sites.

## Verification Checklist (Pre‑merge)

- Run in `debugMode == true` for one run: no outputs written; screen and instruction rendering OK.
- Run in `debugMode == false` for one run: logs and `.mat` files created under the expected `data/sub-XX/` folder; header and event rows unchanged.
- Compare logs before/after refactor for the same seed (where feasible) to ensure stable formatting and event names.
- Confirm escape key still aborts with the same log lines prior to error.

## Contributing

- Open a PR against the current `dev/*` branch with the backlog item in the title.
- Describe how output invariants were preserved and how you validated changes.
