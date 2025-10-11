# fMRI Task Template — Detailed Project Plan and TODOs

This plan defines what we want to achieve, why, and how. It includes explicit inputs/outputs for new APIs so contributors can implement tests and features with confidence. All work must preserve output invariants (filenames, TSV format/order, .mat variables, timing semantics).

## Vision (Why)

- Robust by default: A template that runs reliably on scanner/PC, with solid logging and timing, and clear errors.
- Easy to adapt: Study authors customize a handful of well-documented functions (e.g., how to build trials, render instructions, show a trial/fixation) instead of wading through plumbing.
- Testable: Non-GUI integration tests validate core flows; unit tests protect utilities; CI catches regressions early.

## Stable Guardrails (Must Not Change)

- File outputs under `data/sub-XX/` (name and layout).
- `logEvent` TSV header and column order; event names and semantics.
- `.mat` variables and structures saved by `saveAndClose`.
- Flip order and timing arithmetic; computed `idealStimOnset` / `ACTUAL_ONSET` semantics.

## Milestones

1) Comprehensive Tests (unit + integration, PTB-free when possible)
2) Prep & Show Abstractions (single entrypoints, fewer moving parts for studies)
3) Utility Consolidation (structure, naming, API docs, extension hooks)
4) Project Structure & Naming Conventions (clear layout and rules)
5) Pre‑Run Summary & Configuration Logging (visible, reproducible context)

## 1) Comprehensive Tests (What and How)

Rationale: Ensure “happy path” and edge cases stay stable; protect invariants.

- Config and params
  - [x] `TaskConfig.load('src/config.m')` happy path returns a struct with required fields. (testTaskConfigAndValidateParams.m)
  - [x] Missing config file -> `Config:NotFound`. (testTaskConfigAndValidateParams.m)
  - [x] Wrong file type -> `Config:InvalidType`. (testTaskConfigAndValidateParams.m)
  - [x] Non-struct return -> `Config:InvalidReturn`. (testTaskConfigAndValidateParams.m)
  - [x] `validateParams`: required fields, ranges, missing keys, missing stim list -> proper identifiers. (testValidateParamsNumeric.m, testTaskConfigAndValidateParams.m)

- Trial list generation
  - [x] `makeTrialList`: correct total size for given `numRuns` x `numRepetitions`. (testMakeTrialList.m)
  - [x] Even split across runs; `Params:InvalidRuns` on non-divisible. (testMakeTrialList.m)
  - [x] External `run` column is preserved. (testMakeTrialListExternalRun.m)
  - [x] Randomization `'run'` keeps per-run counts; `'all'` shuffles across runs. (testMakeTrialListRandomization.m)
  - [x] Mapping cache used (one mapping per run). (testDetermineButtonMapping.m - deterministic output verified)

- Images and stimuli
  - [x] `loadImages` handles last-item fixation without errors. (testLoadImages.m)
  - [x] `resizeStim` respects `pixelSize` vs `visualUnits` size semantics (unit-only checks). (testResizeStimPPD.m)
  - [x] No error on small subset preload in quick_check flow. (testQuickCheckIntegration.m)

- Logging (file format invariants)
  - [x] Golden header test for `logEvent` TSV line: exact tab order and labels. (testLogEventGolden.m)
  - [x] A row with numeric `EVENT_ID` stays numeric in TSV (no pretty formatting leaks). (testLogEventGolden.m)
  - [x] `createLogFile` naming pattern: datetime + sub/run + task. (testLogEventAndCreateLogFile.m)
  - [ ] `flipAndLog` writes `FLIP` row with correct EXP/ACT/DELTA placeholders (logic-only assertions without real flips). (Deferred - requires PTB mocking)

- Timing helpers
  - [x] `adjustFixationDuration`: equality branch returns `params.fixDur`; handles positive/negative drift. (testAdjustFixationDuration.m)
  - [x] `convertVisualUnits`: round-trip deg->px->deg within tolerance with default geometry; geometry-on path produces finite values (no NaNs). (testConvertVisualUnits.m)

- Input handling (mocked PTB)
  - [ ] `createInputQueues` input validation errors on invalid indices; accepts [] -> default. (Deferred - requires PTB)
  - [ ] `logKeyPressDual` same-device path: with synthetic event masks, logs trigger + response (order by time); no duplicate RESP for trigger code. (Deferred - requires PTB mocking)
  - [x] Debounce behavior: repeated same code within window suppressed; across window logged. (testShouldSuppress.m)
  - [ ] Escape path raises `ScriptExecution:ManuallyAborted` and logs `RESP Escape` once. (Deferred - requires PTB)

- End-to-end debug run (headless harness)
  - [ ] Skipped per user request (Milestone 1.3 excluded)

Notes: Where direct PTB interaction is required, prefer dependency injection (e.g., function handles for flip, queue read) to make components testable.

## 2) Prep & Show Abstractions (What and Why)

Rationale: Reduce boilerplate and centralize common operations; give a single, easy-to-edit place for each on-screen action so studies can customize behavior without touching plumbing.

2.1 Prep Functions (Study-agnostic)

- `prepPathsAndAdd`: Verify `utils/`, `src/` exist; add to path; return canonical paths.
- `prepareSubjectRun`: Build `in` with `subNum`, `runNum`, `timestamp`, `resDir`.
- `initLogging`: Create log file handle or console; write header.
- `initScreen`: Wrap `setupScreen` + `configScreenCol`; compute `PPD` with/without geometry.
- `finalizeRun`: Save data (`saveAndClose`), close PTB objects.

2.2 Show Orchestration (Overridable Single Entry Points)

- `showInstructions(win, params, in, respInst1, respInst2, dbg)`: One entrypoint to render instructions, flip+log, and wait for “continue” key(s). Internally calls display + input logger; returns when user continues. Study authors can override this to change instruction visuals/flow.
- `showTriggerWait(win, params, in, dbg)`: Render trigger-wait text, flip+log, and consume triggers according to policy (single/double/window). Single place to tweak trigger UX.
- `showTrial(win, params, in, runTrials(i), runImMat(i), dbg)`: Show stimulus, flip+log, collect first response during stim window; returns pressedKey if any. Encapsulate stimulus draw + response logging in one modifiable function.
- `showFixation(win, params, in, duration, dbg)`: Draw fixation, flip+log, and log keys during fixation (or no-op on keys if desired). Make it easy to change fixation style/behavior.
- `showCustomScreen(win, name, renderFn, duration, inputPolicy, dbg)`: Minimal framework for arbitrary custom screens with consistent logging.

Acceptance:
- fMRI_task.m delegates to the above “show*” functions; study authors only need to change/show functions or pass alternative renderers.
- No changes to flip order or log formatting.

Acceptance:
- `fMRI_task.m` becomes smaller and clearly separates study-specific sections (instructions text, run structure) from plumbing.
- Output invariants preserved (no change to logs or `.mat`).

Implementation tips:
- Place new helpers under `utils/prep/` or `utils/runtime/` to keep scope clear.
- Keep function signatures explicit; avoid hidden global state.
- Fail early with clear `error(id, msg)` identifiers.

## 3) Utility Consolidation (What and How)

Rationale: Reduce cognitive overhead, improve consistency, and make extension predictable.

3.1 Structure & Naming
- Group related functions by domain: `utils/io/*`, `utils/input/*`, `utils/screen/*`, `utils/trials/*`, `utils/runtime/*`.
- Standardize names (verbs + nouns), e.g., `initScreen`, `initLogging`, `finalizeRun`, `readStimList`, `buildTrialList`.

3.2 Error Identifiers & Messages
- Use consistent families: `Params:*`, `File:*`, `Input:*`, `PTB:*`, `Config:*`.
- Messages include remediation (what to change, where).

3.3 Docs & API
- Each public function has: Purpose; Inputs/Outputs; Error conditions; Example.
- README: “Customize your study” section listing all hooks, with minimal code samples.

3.4 Input Options (Nice-to-have)
- Keys-of-interest filtering to reduce queue noise on some devices.
- Optional side-channel logger (markers), reusing `logEvent` formatting.

Acceptance for Milestone 3:
- Utilities moved and documented; public APIs stable.
- Hooks cover typical study customization needs (instructions, trial flow, custom screens).

## Backlog — Concrete TODOs (Ready to Pick Up)

- Tests
  - [x] Add golden test for `logEvent` header + a few rows (TSV). (testLogEventGolden.m - COMPLETED)
  - [x] Add integration test wrapper for `quick_check` logic (no PTB). (testQuickCheckIntegration.m - COMPLETED)
  - [x] Add tests: `adjustFixationDuration`, `determineButtonMapping` cache, `shouldSuppress`. (testAdjustFixationDuration.m, testDetermineButtonMapping.m, testShouldSuppress.m - COMPLETED)
  - [x] Add trial list tests for external `run` column, randomization modes. (testMakeTrialListExternalRun.m, testMakeTrialListRandomization.m - COMPLETED)
  - [x] Add conversion tests for `convertVisualUnits` with geometry on/off. (testConvertVisualUnits.m - COMPLETED)

- Prep abstractions
  - [ ] Create `utils/runtime/prepPathsAndAdd.m`.
  - [ ] Create `utils/runtime/prepareSubjectRun.m`.
  - [ ] Create `utils/runtime/initLogging.m`.
  - [ ] Create `utils/screen/initScreen.m` (wraps setup + colors + PPD).
  - [ ] Create `utils/runtime/finalizeRun.m` (wraps saveAndClose + cleanup).
  - [ ] Refactor `fMRI_task.m` to use new prep functions (no timing change).

- Consolidation
  - [x] Restructure utilities into workflow-aligned folders; update imports. (COMPLETED - setup/, display/, recording/, hardware/, lib/)
  - [ ] Add headers and consistent error identifiers to public utilities. (In progress - partially done)
  - [ ] Define extension hooks for trial builder, instructions, and feedback. (Pending)
  - [ ] Document public API and extension points in README. (Partially done - structure documented)
  
- Project structure & naming
  - [x] Create workflow-aligned folders under `utils/` and move functions accordingly. (COMPLETED - setup/, display/, recording/, hardware/, lib/)
  - [x] Enforce one public function per file; rename any outliers. (Already compliant)
  - [x] Add naming rules and structure diagram to README. (COMPLETED - workflow-aligned structure documented)
  - [ ] Add a linter/check script to validate file locations and names (lightweight). (Optional - deferred)

- Pre‑run summary & config logging
  - [ ] Implement `utils/runtime/printRunSummary.m` (console render + TSV `INFO` rows + sidecar file).
  - [ ] Integrate pre-run summary into `fMRI_task.m` right after logging initialization and before `FLIP Instr`.
  - [ ] Add tests around generation of `INFO` rows and presence of sidecar file.

- CI & Dev ergonomics
  - [ ] Expose keys-of-interest filtering to reduce queue noise on some devices.
  - [ ] Optional separate logger for side-channel inputs (e.g., markers), reusing the same log formatting.

- Developer ergonomics
  - [ ] Provide a minimal example study demonstrating how to override trial builder and instructions.
  - [ ] Add a `scripts/dev_smoke.m` to run a deterministic short run in debug with no outputs (mock images).

Notes for Contributors
- Preserve output invariants; keep PRs small and focused.
- Update function headers and error identifiers when touching utilities.
- Provide reproduction and acceptance steps in PR descriptions.
