# fMRI Task Template — API Reference

This document provides a complete index of all utility functions organized by workflow stage. Use this as a reference when customizing your task.

---

## Quick Navigation

- [Setup Functions](#setup-functions) - Configuration, trial list creation, session initialization
- [Display Functions](#display-functions) - Visual presentation (instructions, stimuli, fixation)
- [Recording Functions](#recording-functions) - Input capture, logging, data saving
- [Hardware Functions](#hardware-functions) - PTB initialization, screen setup, device management
- [Helper Functions](#helper-functions) - Timing, conversions, utilities

---

## Setup Functions

Functions for configuring experiments, building trial lists, and initializing sessions.

### `TaskConfig.load(configPath, fmriMode)`
**Purpose**: Load and validate experiment configuration from MATLAB config file

**Location**: `utils/setup/TaskConfig.m`

**Inputs**:
- `configPath` (string): Path to config.m file (e.g., `'src/config.m'`)
- `fmriMode` (logical): If true, use MRI codes/geometry; if false, use PC codes

**Outputs**:
- `params` (struct): Validated parameter struct with all config fields

**Errors**:
- `Config:NotFound` - Config file doesn't exist
- `Config:InvalidType` - Not a .m file
- `Config:InvalidReturn` - Config function didn't return a struct

**Example**:
```matlab
params = TaskConfig.load('src/config.m', false);
```

---

### `validateParams(params, fmriMode)`
**Purpose**: Validate that all required fields are present with correct types and ranges

**Location**: `utils/setup/validateParams.m`

**Inputs**:
- `params` (struct): Parameter struct from config
- `fmriMode` (logical): Controls which device codes to validate

**Outputs**: None (errors if invalid)

**Errors**:
- `Params:MissingField` - Required field missing
- `Params:InvalidType` - Field has wrong type
- `Params:InvalidRange` - Numeric value out of valid range
- `File:NotFound` - Stimulus list file doesn't exist

**Example**:
```matlab
validateParams(params, true);
```

---

### `makeTrialList(params, in)`
**Purpose**: Build complete trial list from stimulus file, with repetitions and randomization

**Location**: `utils/setup/makeTrialList.m`

**Inputs**:
- `params` (struct): Experiment parameters (numRepetitions, numRuns, stimRandomization)
- `in` (struct): Session info (subNum, runNum)

**Outputs**:
- `trialList` (struct array): Complete trial list with fields:
  - `stimuli`, `run`, `trialNb`, `idealStimOnset`
  - `respKey1Code`, `respKey2Code`, `respInst1`, `respInst2`
  - Plus any custom columns from stimulus TSV

**Errors**:
- `Params:InvalidRuns` - Trial count not divisible by number of runs
- `File:NotFound` - Stimulus list file missing

**Example**:
```matlab
trialList = makeTrialList(params, in);
```

---

### `validateTrialList(trialList)`
**Purpose**: Validate trial list structure and check for absolute paths

**Location**: `utils/setup/validateTrialList.m`

**Inputs**:
- `trialList` (struct array): Trial list to validate

**Outputs**: None (errors if invalid)

**Errors**:
- `TrialList:AbsolutePath` - Stimulus contains absolute path (security risk)
- `TrialList:MissingField` - Required field missing

**Example**:
```matlab
validateTrialList(trialList);
```

---

### `loadImages(trialList, params)`
**Purpose**: Preload and resize all stimulus images

**Location**: `utils/setup/loadImages.m`

**Inputs**:
- `trialList` (struct array): Trial list with `stimuli` field
- `params` (struct): Resize parameters (resize, resizeMode, outWidth, outHeight)

**Outputs**:
- `imMat` (struct): Image matrix with field `image` (cell array of image matrices)

**Errors**:
- `LoadImages:FileNotFound` - Image file doesn't exist
- `LoadImages:InvalidFormat` - Unsupported image format

**Example**:
```matlab
imMat = loadImages(trialList, params);
```

---

### `determineButtonMapping(subNum, runNum, params)`
**Purpose**: Determine response button order for this run (alternates across runs)

**Location**: `utils/setup/determineButtonMapping.m`

**Inputs**:
- `subNum` (numeric): Subject number
- `runNum` (numeric): Run number
- `params` (struct): Contains respKey codes and instructions

**Outputs**:
- `mapping` (struct): Contains `respKey1Code`, `respKey2Code`, `respInst1`, `respInst2`

**Example**:
```matlab
mapping = determineButtonMapping(1, 2, params);
```

---

### `initializeSession(debugMode, fmriMode)`
**Purpose**: Initialize session by loading config, setting up paths, and validating params

**Location**: `utils/setup/initializeSession.m`

**Inputs**:
- `debugMode` (logical): Controls windowing and save behavior
- `fmriMode` (logical): Controls device codes and screen geometry

**Outputs**:
- `params` (struct): Validated experiment parameters
- `paths` (struct): Canonical paths (root, utils, src, data)
- `dbg` (struct): Debug options

**Example**:
```matlab
[params, paths, dbg] = initializeSession(true, false);
```

---

### `promptSubjectRun(params, debugMode)`
**Purpose**: Prompt for subject and run numbers (or use defaults in debug mode)

**Location**: `utils/setup/promptSubjectRun.m`

**Inputs**:
- `params` (struct): Contains numRuns for validation
- `debugMode` (logical): If true, use defaults (sub=99, run=99)

**Outputs**:
- `subNum` (numeric): Subject number
- `runNum` (numeric): Run number

**Example**:
```matlab
[subNum, runNum] = promptSubjectRun(params, false);
```

---

### `prepareSession(subNum, runNum, debugMode)`
**Purpose**: Create session info struct and output directory

**Location**: `utils/setup/prepareSession.m`

**Inputs**:
- `subNum` (numeric): Subject number
- `runNum` (numeric): Run number
- `debugMode` (logical): If false, creates data directory

**Outputs**:
- `in` (struct): Session metadata (subNum, runNum, resDir, timestamp, scriptStart)

**Errors**:
- `Session:InvalidSubNum` - Subject number not positive integer
- `Session:InvalidRunNum` - Run number not positive integer

**Example**:
```matlab
in = prepareSession(1, 2, false);
```

---

### `prepareEnvironment()`
**Purpose**: Verify required directories exist and add utils to MATLAB path

**Location**: `utils/setup/prepareEnvironment.m`

**Inputs**: None

**Outputs**:
- `paths` (struct): Canonical paths (root, utils, src, data, scripts)

**Errors**:
- `Environment:MissingUtils` - utils/ directory not found
- `Environment:MissingSrc` - src/ directory not found

**Warnings**:
- If scripts/ or data/ directories missing

**Example**:
```matlab
paths = prepareEnvironment();
```

---

## Display Functions

Functions for rendering visual elements on screen.

### `showTrialStimulus(win, winRect, params, in, image, trial, trialIdx, logFile, debugMode, dbg)`
**Purpose**: Display trial stimulus with timing and logging (consolidates common pattern)

**Location**: `utils/display/showTrialStimulus.m`

**Inputs**:
- `win`, `winRect` (ptr, array): PTB window and rectangle
- `params` (struct): Experiment parameters
- `in` (struct): Session info (scriptStart, gray, colors)
- `image` (matrix/struct): Preloaded image or []
- `trial` (struct): Trial info with idealStimOnset, stimuli fields
- `trialIdx` (numeric): Trial index for logging
- `logFile` (file handle): Log file
- `debugMode` (logical): Enable debug features
- `dbg` (struct): Debug options

**Outputs**:
- `VBL` (numeric): Flip timestamp
- `actualOnset` (numeric): Onset relative to script start

**Example**:
```matlab
[VBL, onset] = showTrialStimulus(win, winRect, params, in, img, trial, 5, logFile, true, dbg);
```

---

### `showFixationPeriod(win, winRect, params, in, duration, logFile, inputDevs, debugMode, dbg)`
**Purpose**: Display fixation with timing, logging, and input capture (consolidates common pattern)

**Location**: `utils/display/showFixationPeriod.m`

**Inputs**:
- `win`, `winRect` (ptr, array): PTB window and rectangle
- `params` (struct): Experiment parameters
- `in` (struct): Session info
- `duration` (numeric): Fixation duration in seconds
- `logFile` (file handle): Log file
- `inputDevs` (struct): Input queues
- `debugMode` (logical): Enable debug features
- `dbg` (struct): Debug options

**Outputs**:
- `VBL` (numeric): Flip timestamp
- `keyPressed` (numeric/empty): Key code if pressed, else []
- `in` (struct): Updated session info
- `dbg` (struct): Updated debug options

**Example**:
```matlab
[VBL, key, in, dbg] = showFixationPeriod(win, winRect, params, in, 1.5, logFile, inputDevs, false, dbg);
```

---

### `showInstructions(win, params, in, logFile, respInst1, respInst2, inputDevs, dbg)`
**Purpose**: Display instructions and wait for participant to continue

**Location**: `utils/display/showInstructions.m`

**Inputs**:
- `win` (ptr): PTB window pointer
- `params` (struct): Contains instruction text lines
- `in` (struct): Session info (colors, scriptStart)
- `logFile` (file handle): For logging FLIP event
- `respInst1`, `respInst2` (string): Response button labels to insert
- `inputDevs` (struct): Input queues
- `dbg` (struct): Debug options

**Outputs**:
- `VBL` (numeric): Timestamp of instruction flip
- `in` (struct): Updated session info

**Example**:
```matlab
[VBL, in] = showInstructions(win, params, in, logFile, 'left', 'right', inputDevs, dbg);
```

---

### `waitForTrigger(win, params, in, logFile, inputDevs, dbg)`
**Purpose**: Display trigger wait message and consume scanner triggers per policy

**Location**: `utils/display/waitForTrigger.m`

**Inputs**:
- `win` (ptr): PTB window pointer
- `params` (struct): Contains triggerWaitText and triggerPolicy
- `in` (struct): Session info
- `logFile` (file handle): For logging
- `inputDevs` (struct): Input queues
- `dbg` (struct): Debug options

**Outputs**:
- `VBL` (numeric): Timestamp when trigger received
- `in` (struct): Updated session info

**Trigger policies**:
- `'single'`: Accept first trigger
- `'double'`: Wait for two triggers (scanner artifact)
- `'window'`: Accept first trigger in time window

**Example**:
```matlab
[VBL, in] = waitForTrigger(win, params, in, logFile, inputDevs, dbg);
```

---

### `displayTrial(params, in, image, trial, ~, win, winRect)`
**Purpose**: Render a single trial's stimulus (or fixation if trial is fixation type)

**Location**: `utils/display/displayTrial.m`

**Inputs**:
- `params` (struct): Experiment parameters
- `in` (struct): Session info (gray background)
- `image` (matrix/struct): Preloaded image or empty for fixation
- `trial` (struct): Trial info (must have `stimuli` field)
- `~` (unused): Legacy parameter slot
- `win` (ptr): PTB window pointer
- `winRect` (array): Screen rectangle [x1 y1 x2 y2]

**Outputs**: None (draws to PTB buffer, doesn't flip)

**Behavior**:
- Fills background with gray
- Creates texture, draws stimulus, closes texture (memory cleanup)
- If `trial.stimuli == 'fixation'`, calls `displayFixation` instead

**Example**:
```matlab
displayTrial(params, in, runImMat(i), runTrials(i), 1, win, winRect);
```

---

### `displayFixation(win, winRect, params, in)`
**Purpose**: Draw fixation element on screen

**Location**: `utils/display/displayFixation.m`

**Inputs**:
- `win` (ptr): PTB window pointer
- `winRect` (array): Screen rectangle
- `params` (struct): Contains `fixType` ('round' or 'cross'), `fixSize` (deg)
- `in` (struct): Color values (black, white, gray), optionally PPD

**Outputs**: None (draws to PTB buffer)

**Fixation types**:
- `'round'`: Three-layer circular target (black-white-black)
- `'cross'`: Simple cross with configurable width

**Example**:
```matlab
displayFixation(win, winRect, params, in);
```

---

### `drawDebugOverlay(win, text, in)`
**Purpose**: Draw small debug text overlay on screen (for development)

**Location**: `utils/display/drawDebugOverlay.m`

**Inputs**:
- `win` (ptr): PTB window pointer
- `text` (string): Text to display
- `in` (struct): Contains white color value

**Outputs**: None (draws to PTB buffer)

**Example**:
```matlab
if debugMode && dbg.overlay
    drawDebugOverlay(win, 'Trial 5', in);
end
```

---

## Recording Functions

Functions for capturing input, logging events, and saving data.

### `createLogFile(params, in, debugMode, dbg)`
**Purpose**: Create log file and write TSV header

**Location**: `utils/recording/createLogFile.m`

**Inputs**:
- `params` (struct): Contains taskName
- `in` (struct): Session info (timestamp, subNum, runNum, resDir)
- `debugMode` (logical): If true and dbg.writeLogs=false, use console
- `dbg` (struct): Contains writeLogs flag

**Outputs**:
- `logFile` (file handle): Open file handle or stdout (1)

**File format**: TSV with header:
```
EVENT_TYPE	EVENT_NAME	EVENT_ID	TRIAL	EXP_ONSET	ACTUAL_ONSET	DELTA	MSG
```

**Example**:
```matlab
logFile = createLogFile(params, in, debugMode, dbg);
```

---

### `logEvent(logFile, eventType, eventName, eventID, trial, expOnset, actualOnset, delta, msg)`
**Purpose**: Write a single event row to log file

**Location**: `utils/recording/logEvent.m`

**Inputs**:
- `logFile` (file handle): Log file handle
- `eventType` (string): Type (FLIP, RESP, INFO, ERROR, WARN)
- `eventName` (string): Event name (Stim, Fix, Pre-fix, Post-fix, etc.)
- `eventID` (string): Event identifier
- `trial` (string/numeric): Trial number or '-'
- `expOnset` (numeric/string): Expected onset (s) or '-'
- `actualOnset` (numeric/string): Actual onset (s) or '-'
- `delta` (numeric/string): Timing deviation (ms) or '-'
- `msg` (string): Optional message

**Outputs**: None (writes to file)

**Example**:
```matlab
logEvent(logFile, 'FLIP', 'Stim', dateTimeStr, 1, 12.5, 12.501, 1.0, 'image01.png');
```

---

### `waitAndCaptureInput(params, in, logFile, durationSec, inputDevs, debugMode, dbg)`
**Purpose**: Wait for specified duration while capturing and logging all input

**Location**: `utils/recording/waitAndCaptureInput.m`

**Inputs**:
- `params` (struct): Experiment parameters (for key mapping)
- `in` (struct): Session info
- `logFile` (file handle): For logging key presses
- `durationSec` (numeric): Wait duration in seconds
- `inputDevs` (struct): Input queues (trigger, response)
- `debugMode` (logical): Enables overlay toggle
- `dbg` (struct): Contains slowMoFactor, overlay

**Outputs**:
- `keyPressed` (logical): True if any key was pressed
- `in` (struct): Updated session info
- `dbg` (struct): Updated debug options (overlay may toggle)

**Example**:
```matlab
[pressed, in, dbg] = waitAndCaptureInput(params, in, logFile, 1.5, inputDevs, debugMode, dbg);
```

---

### `logKeyPressDual(params, in, logFile, untilKeyPress, needValidResponse, conditionFunc, inputDevs)`
**Purpose**: Poll dual input queues and log all key presses with debouncing

**Location**: `utils/recording/logKeyPressDual.m`

**Inputs**:
- `params` (struct): Contains respKeysCode, triggerKeyCode, escapeKeyCode, debounceWindowMs
- `in` (struct): Session info (scriptStart), updated with lastKeyLog
- `logFile` (file handle): For logging RESP events
- `untilKeyPress` (logical): If true, return after first key
- `needValidResponse` (logical): If true, only return on valid response key
- `conditionFunc` (function handle): While this returns true, keep polling
- `inputDevs` (struct): Input queues (trigger, response)

**Outputs**:
- `pressedKey` (numeric/empty): Key code if valid response, else []
- `in` (struct): Updated with lastKeyLog for debouncing

**Behavior**:
- Polls both queues, merges events by timestamp
- Logs all presses as RESP events
- Applies debouncing via `shouldSuppress`
- ESC key (27) raises `ScriptExecution:ManuallyAborted`

**Example**:
```matlab
[key, in] = logKeyPressDual(params, in, logFile, false, false, @() true, inputDevs);
```

---

### `shouldSuppress(keyCode, timestamp, lastKeyLog, debounceWindowMs)`
**Purpose**: Determine if key press should be suppressed due to debouncing

**Location**: `utils/recording/shouldSuppress.m`

**Inputs**:
- `keyCode` (numeric): Current key code
- `timestamp` (numeric): Current timestamp (seconds)
- `lastKeyLog` (struct array): Recent key log with fields `code`, `time`
- `debounceWindowMs` (numeric): Debounce window in milliseconds

**Outputs**:
- `suppress` (logical): True if should suppress, false if should log

**Example**:
```matlab
suppress = shouldSuppress(102, GetSecs(), in.lastKeyLog, 100);
```

---

### `saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, saveMat)`
**Purpose**: Save .mat file, close log, restore input, and clean up PTB

**Location**: `utils/recording/saveAndClose.m`

**Inputs**:
- `params` (struct): Experiment parameters
- `in` (struct): Session info (resDir, timestamp, subNum, runNum)
- `debugMode` (logical): Controls whether to save
- `runTrials` (struct array): Trial data with responses
- `runImMat` (cell array): Image matrices
- `logFile` (file handle): Log file to close
- `saveMat` (logical): Override save behavior

**Outputs**: None (saves file and cleans up)

**Saves**: `YYYY-MM-DD-hh-mm_sub-XX_run-YY_task-NAME.mat`
**Variables**: `params`, `in`, `runTrials`, `runImMat`

**Example**:
```matlab
saveAndClose(params, in, debugMode, runTrials, runImMat, logFile, dbg.saveMat);
```

---

## Hardware Functions

Functions for Psychtoolbox initialization and hardware setup.

### `initPTB()`
**Purpose**: Initialize Psychtoolbox (close screens, unify key names)

**Location**: `utils/hardware/initPTB.m`

**Inputs**: None

**Outputs**: None (side effects: cleans PTB state)

**Example**:
```matlab
initPTB();
```

---

### `createInputQueues(params)`
**Purpose**: Create separate keyboard queues for trigger and response devices

**Location**: `utils/hardware/createInputQueues.m`

**Inputs**:
- `params` (struct): Contains deviceIDs.trigger and deviceIDs.response

**Outputs**:
- `inputDevs` (struct): Contains queue IDs (trigger, response)

**Behavior**:
- Creates dual queues to capture simultaneous events
- If deviceIDs empty, uses default keyboard
- Supports multiple devices per queue (cell arrays)

**Example**:
```matlab
inputDevs = createInputQueues(params);
```

---

### `openScreen(params, in, fmriMode, debugMode, dbg)`
**Purpose**: Open PTB window, configure colors, and compute pixels per degree

**Location**: `utils/hardware/openScreen.m`

**Inputs**:
- `params` (struct): Screen geometry (scrDistMRI/PC, scrWidthMRI/PC)
- `in` (struct): Session info
- `fmriMode` (logical): Controls which geometry to use
- `debugMode` (logical): Controls fullscreen vs windowed
- `dbg` (struct): Contains windowScale, skipSyncTests

**Outputs**:
- `win` (ptr): PTB window pointer
- `winRect` (array): Window rectangle [0 0 width height]
- `screen` (struct): Screen info (number, framerate)
- `in` (struct): Updated with color values (black, white, gray)
- `params` (struct): Updated with PPD if useScreenGeometry=true

**Example**:
```matlab
[win, winRect, screen, in, params] = openScreen(params, in, false, true, dbg);
```

---

### `computePPD(scrWidthPx, scrWidthMm, scrDistMm)`
**Purpose**: Compute pixels per degree of visual angle from screen geometry

**Location**: `utils/hardware/computePPD.m`

**Inputs**:
- `scrWidthPx` (numeric): Screen width in pixels
- `scrWidthMm` (numeric): Screen width in millimeters
- `scrDistMm` (numeric): Viewing distance in millimeters

**Outputs**:
- `PPD` (numeric): Pixels per degree of visual angle

**Formula**: `PPD = (scrWidthPx / scrWidthMm) * (2 * scrDistMm * tan(0.5 * pi/180))`

**Example**:
```matlab
PPD = computePPD(1920, 510, 600);
```

---

### `listDevices()`
**Purpose**: List all PsychHID devices with indices (helper for config)

**Location**: `utils/hardware/listDevices.m`

**Inputs**: None

**Outputs**: Prints device list to console

**Example**:
```matlab
listDevices();
```

---

## Helper Functions

Generic utilities for timing, conversions, and formatting.

### `getTrialImage(runImMat, trialIdx)`
**Purpose**: Safely extract trial image from preloaded matrix

**Location**: `utils/lib/getTrialImage.m`

**Inputs**:
- `runImMat` (cell array/struct array): Preloaded images
- `trialIdx` (numeric): Trial index (1-based)

**Outputs**:
- `image` (matrix/struct/[]): Image or [] if not available

**Example**:
```matlab
img = getTrialImage(runImMat, 5);
```

---

### `adjustFixationDuration(runTrials, currentTrialIdx, params)`
**Purpose**: Adjust fixation duration to compensate for timing drift

**Location**: `utils/lib/adjustFixationDuration.m`

**Inputs**:
- `runTrials` (struct array): Trial list with `idealStimOnset` and `stimOnset` fields
- `currentTrialIdx` (numeric): Index of current trial (just shown)
- `params` (struct): Contains baseline `fixDur`

**Outputs**:
- `adjustedFixDur` (numeric): Adjusted fixation duration in seconds

**Logic**:
- `delta = actualOnset - idealOnset`
- `adjustedFixDur = params.fixDur - delta`
- If delta=0 (on time), returns `params.fixDur`
- If late (delta>0), shortens fixation
- If early (delta<0), lengthens fixation

**Example**:
```matlab
fixDur = adjustFixationDuration(runTrials, 5, params);
```

---

### `convertVisualUnits(value, fromUnits, toUnits, useScreenGeometry, scrDist, scrWidth)`
**Purpose**: Convert between visual angle (deg) and pixels

**Location**: `utils/lib/convertVisualUnits.m`

**Inputs**:
- `value` (numeric): Value to convert
- `fromUnits` (string): 'deg', 'px', or 'mm'
- `toUnits` (string): 'deg', 'px', or 'mm'
- `useScreenGeometry` (logical, optional): Use provided geometry vs defaults
- `scrDist` (numeric, optional): Viewing distance in mm
- `scrWidth` (numeric, optional): Screen width in mm

**Outputs**:
- `converted` (numeric): Converted value

**Default geometry** (when useScreenGeometry=false):
- 30 pixels per cm
- 1 deg = 1 cm at typical viewing distance

**Example**:
```matlab
% Using defaults
px = convertVisualUnits(5, 'deg', 'px');

% Using measured geometry
px = convertVisualUnits(5, 'deg', 'px', true, 600, 510);
```

---

### `dateTimeStr()`
**Purpose**: Generate timestamp string for filenames

**Location**: `utils/lib/dateTimeStr.m`

**Inputs**: None

**Outputs**:
- `str` (string): Timestamp in format `YYYY-MM-DD-HH-MM`

**Example**:
```matlab
timestamp = dateTimeStr();  % '2025-10-12-14-30'
```

---

### `resizeStim(im, params, PPD)`
**Purpose**: Resize stimulus image according to params

**Location**: `utils/lib/resizeStim.m`

**Inputs**:
- `im` (matrix): Original image matrix
- `params` (struct): Contains resizeMode, outWidth, outHeight
- `PPD` (numeric, optional): Pixels per degree (required if resizeMode='visualUnits')

**Outputs**:
- `resized` (matrix): Resized image

**Resize modes**:
- `'pixelSize'`: Use outWidth/outHeight as pixel dimensions
- `'visualUnits'`: Convert outWidth/outHeight from degrees to pixels using PPD

**Example**:
```matlab
resizedIm = resizeStim(originalIm, params, in.PPD);
```

---

### `validateInstructionPlaceholders(params)`
**Purpose**: Validate that instructions contain exactly two `()` placeholders

**Location**: `utils/setup/validateInstructionPlaceholders.m`

**Inputs**:
- `params` (struct): Contains instructionsText1, instructionsText2, etc.

**Outputs**: None (errors if invalid)

**Errors**:
- `Instructions:InvalidPlaceholders` - Not exactly 2 placeholders found

**Example**:
```matlab
validateInstructionPlaceholders(params);
```

---

## Utility Scripts

Located in `scripts/` directory - not functions, but useful tools.

### `quick_check.m`
Validates configuration and trial list without opening PTB windows. Run before first experiment.

### `list_devices.m`
Lists all PsychHID devices with indices. Use to populate `deviceIDs` in config.

### `detect_button_codes.m`
Interactive script to detect decimal codes for button box responses.

### `pretty_log.m`
Pretty-prints TSV log files with aligned columns. Usage: `pretty_log('path/to/log.tsv')`

### `dev_smoke.m`
Fast 2-trial smoke test with deterministic output. Use during development for quick iteration.

### `check_consistency.m`
Validates output consistency across runs (compares log files and .mat files).

### `check_invariants.sh`
Shell script that verifies output format invariants (TSV headers, file naming).

---

## Customization Hooks

Functions you should **customize for your study**:

1. **Trial list builder**: Replace `makeTrialList` with custom builder in `src/makeTrialListCustom.m`
2. **Trial display**: Modify `displayTrial` for custom stimulus rendering
3. **Instructions**: Edit instruction text in `src/config.m` or override `showInstructions`
4. **Fixation**: Change fixation style via config or override `displayFixation`
5. **Response collection**: Modify trial loop in `fMRI_task.m` for rating scales, feedback, etc.

See `CLAUDE.md` and `README.md` for detailed customization examples.

---

## Error Identifier Reference

All errors use namespaced identifiers for easy troubleshooting:

- `Config:*` - Configuration loading errors
- `Params:*` - Parameter validation errors
- `File:*` - File I/O errors
- `Input:*` - Input device errors
- `PTB:*` - Psychtoolbox errors
- `Session:*` - Session setup errors
- `TrialList:*` - Trial list validation errors
- `ScriptExecution:*` - Runtime execution errors

---

## See Also

- **CLAUDE.md** - Development guide, architecture, workflow
- **README.md** - User guide, configuration reference
- **AGENTS.md** - Contributor guide, coding standards
- **TODO.md** - Project roadmap and milestones
