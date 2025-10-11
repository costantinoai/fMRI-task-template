# fMRI Task Template — Project TODOs and Plan

This document outlines the next development steps to strengthen the template while preserving output invariants. It is organized for a future contributor/LLM to pick up and execute in small PRs.

## Guardrails (Must Remain Stable)

- Filenames and folder layout under `data/`.
- Log header, row formatting, event names, and column order as produced by `logEvent`.
- `.mat` file content structure and variable names (`params`, `in`, `runTrials`, `runImMat`).
- Event timing semantics and flip ordering.

## Milestones

1) Test Coverage Expansion (unit + integration).
2) Prep/Boilerplate Abstraction (reduce duplication; stable boundaries).
3) Utilities Consolidation (names, structure, API, docs).

## 1) Tests: Overall Workflow and Utilities

Goal: Add targeted tests to ensure the “happy path” is stable and detect regressions early. Keep tests non‑GUI (no PTB windows) whenever possible.

- Integration tests (non-PTB)
  - quick_check smoke test wrapper that asserts:
    - `TaskConfig.load('src/config.m')` succeeds.
    - `validateParams` passes with default config.
    - `makeTrialList` produces expected count and fields.
    - `loadImages` loads a small subset without PTB.
  - Acceptance: 100% pass on CI; no PTB window required.

- Log formatting tests
  - Golden test for `logEvent` header+row format. Compare against a canonical string (tab-separated; invariant order).
  - Verify integer-like `EVENT_ID` prints as-is in TSV (we keep pretty console outside of file scope).

- Trial list tests
  - Randomization modes: `'run'` vs `'all'` (distribution, run counts).
  - Divisibility error path (`Params:InvalidRuns`).
  - Respect externally provided `run` column.
  - Placeholders present in instruction fields (covered by `validateInstructionPlaceholders`).

- Utilities tests (add as needed)
  - `adjustFixationDuration`: equality branch, negative drift, large drift.
  - `convertVisualUnits`: stable conversions with/without geometry.
  - `resizeStim`: size preservation policy across `pixelSize`/`visualUnits`.
  - `determineButtonMapping`: mapping cache correctness and run alternation.
  - `shouldSuppress`: debounce windows edge cases.

- Input mapping tests (mocked)
  - Shape-only tests around `createInputQueues` argument validation.
  - Ensure same-device safety path is exercised in `logKeyPressDual` with synthetic masks.

Notes: Do not require PTB in CI; where PTB calls are unavoidable, abstract or mock.

## 2) Abstract Standard Prep Operations

Goal: Move repeated, study-agnostic boilerplate into helpers so the main script is shorter and more editable where it matters (study-specific bits).

Target extractions (no timing changes):

- `prepPathsAndAdd`: Verify `utils/`, `src/` exist; add to path; return canonical paths.
- `prepareSubjectRun`: Build `in` with `subNum`, `runNum`, `timestamp`, `resDir`.
- `initLogging`: Create log file handle or console; write header.
- `initScreen`: Wrap `setupScreen` + `configScreenCol`; compute `PPD` with/without geometry.
- `finalizeRun`: Save data (`saveAndClose`), close PTB objects.

Acceptance:
- `fMRI_task.m` becomes smaller and clearly separates study-specific sections (instructions text, run structure) from plumbing.
- Output invariants preserved (no change to logs or `.mat`).

Implementation tips:
- Place new helpers under `utils/prep/` or `utils/runtime/` to keep scope clear.
- Keep function signatures explicit; avoid hidden global state.
- Fail early with clear `error(id, msg)` identifiers.

## 3) Merge and Consolidate Utilities

Goal: A tidy, consistent utility layer that is robust and easy to extend.

Naming and structure
- Group related functions by domain: `utils/io/*`, `utils/input/*`, `utils/screen/*`, `utils/trials/*`, `utils/runtime/*`.
- Standardize names (verbs + nouns), e.g., `initScreen`, `initLogging`, `finalizeRun`, `readStimList`, `buildTrialList`.

API surface & stability
- Define “public” utilities (used by main script and studies) vs “internal” helpers.
- Add short header docs (purpose, inputs, outputs, examples) for public utilities.
- Standardize error identifiers: `Params:*`, `File:*`, `Input:*`, `PTB:*`.

Configuration & extension points
- Keep study-specific decisions in `src/config.m` and the main script.
- Provide hooks where study authors can override behavior:
  - Trial generation: allow passing a custom `buildTrials(params, in)` function.
  - Instructions: compose from config + optional study function `renderInstructions(win, params, in)`.
  - Accuracy/feedback: add optional callbacks invoked at run-time.

Documentation
- Update README with a “Customize your study” section pointing to hooks and stable utilities.
- Add a short “Public API of utilities” appendix with expected inputs/outputs.

Acceptance:
- Utilities have consistent, documented interfaces.
- Main script clearly shows the places to customize (instructions, trial logic, run structure).

## Backlog — Concrete TODOs

- Tests
  - [ ] Add golden test for `logEvent` header + a few rows (TSV).
  - [ ] Add integration test wrapper for `quick_check` logic (no PTB).
  - [ ] Add tests: `adjustFixationDuration`, `determineButtonMapping` cache, `shouldSuppress`.
  - [ ] Add trial list tests for external `run` column, randomization modes.
  - [ ] Add conversion tests for `convertVisualUnits` with geometry on/off.

- Prep abstractions
  - [ ] Create `utils/runtime/prepPathsAndAdd.m`.
  - [ ] Create `utils/runtime/prepareSubjectRun.m`.
  - [ ] Create `utils/runtime/initLogging.m`.
  - [ ] Create `utils/screen/initScreen.m` (wraps setup + colors + PPD).
  - [ ] Create `utils/runtime/finalizeRun.m` (wraps saveAndClose + cleanup).
  - [ ] Refactor `fMRI_task.m` to use new prep functions (no timing change).

- Consolidation
  - [ ] Restructure utilities into domain folders; update imports.
  - [ ] Add headers and consistent error identifiers to public utilities.
  - [ ] Define extension hooks for trial builder, instructions, and feedback.
  - [ ] Document public API and extension points in README.

- Input robustness & options (nice-to-have)
  - [ ] Expose keys-of-interest filtering to reduce queue noise on some devices.
  - [ ] Optional separate logger for side-channel inputs (e.g., markers), reusing the same log formatting.

- Developer ergonomics
  - [ ] Provide a minimal example study demonstrating how to override trial builder and instructions.
  - [ ] Add a `scripts/dev_smoke.m` to run a deterministic short run in debug with no outputs (mock images).

## Notes for Contributors

- Keep changes minimal with respect to output invariants.
- Prefer small, focused PRs per TODO item.
- When touching utilities, update header docs and error identifiers.
- Aim for clear, actionable error messages with remediation steps.

