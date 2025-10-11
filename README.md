# fMRI task template

This is a template script for running a task in the fMRI scanner. It is designed to be modular, lightweight and easy to adapt to your needs. Your main tool is `fMRI_task.m`, which is designed to play one run of experimental task at a time.

The structure & most of the ideas for this repo come from work by [@costantinoai](https://github.com/costantinoai) and [@laura](https://www.hoplab.be/people/#LauraVH). It was adapted by [@TimManiquet](https://github.com/TimManiquet).


**Repository structure**
```
.
├── data
│   └── sub-01
│       └── ...
├── fMRI_task.m
├── README.md
├── scripts
│   └── quick_check.m
├── src
│   ├── list_of_stimuli.tsv
│   ├── config.m
│   ├── readme_files
│   └── stimuli
│       └── your images here ...
└── utils
    ├── setup/          # Experiment configuration & trial design
    │   ├── TaskConfig.m
    │   ├── validateParams.m
    │   ├── validateInstructionPlaceholders.m
    │   ├── makeTrialList.m
    │   ├── validateTrialList.m
    │   ├── determineButtonMapping.m
    │   └── loadImages.m
    ├── display/        # Screen rendering & visual presentation
    │   ├── displayInstructions.m
    │   ├── displayTrial.m
    │   ├── displayFixation.m
    │   ├── flipAndLog.m
    │   └── resizeStim.m
    ├── recording/      # Data logging & response tracking
    │   ├── createLogFile.m
    │   ├── logEvent.m
    │   ├── logKeyPressDual.m
    │   ├── shouldSuppress.m
    │   └── saveAndClose.m
    ├── hardware/       # PTB initialization & device management
    │   ├── initializePTB.m
    │   ├── setupScreen.m
    │   ├── configScreenCol.m
    │   ├── createInputQueues.m
    │   └── listDevices.m
    └── lib/            # Generic helper utilities
        ├── dateTimeStr.m
        ├── zeroFill.m
        ├── convertVisualUnits.m
        └── adjustFixationDuration.m
```


### Requirements

Make sure the following exist in your root directory:

 - A `utils` folder containing utility functions.
 - A `src` folder containing all your stimuli in `src/stimuli`.
- A `config.m` file in the `src` directory, returning a struct of experimental parameters.
  - A `list_of_stimuli.tsv` file in the `src` directory, containing a list of your trial stimuli & other relevant variables.

Before starting your experiment, make sure you set the flags `debugMode` and `fmriMode`. These will determine a number of things:

- `debugMode` should be turned on if you are still developing. It will make your experiment run in a window instead of full screen, and will prevent data from being saved. Switching it off will make the cursor disappear for the time of the experiment, have it run in full screen, and save all result and log all the data.
- `fmriMode` will have the fMRI screen properties, response & trigger buttons, and response instruction values used. Switching it off will turn these parameters to their PC values.

Input devices and simultaneous events: configure `deviceIDs.trigger` and `deviceIDs.response` in `src/config.m` to bind queues to specific devices. The template uses dual queues and logs both trigger and response events even when they occur at the same time.


### Configuration (MATLAB)

Most of your experiment parameters are read from `src/config.m` via `TaskConfig.load`. Only decimal key codes are allowed (no key names like "q"). Use this section as a checklist for the elements you need to set. The field names match the previous template parameters where possible.

Key code policy
- Always use decimal key codes for keys and buttons. Do not use key name strings.
- Examples (ASCII decimal):
  - Digits 1..9: 49..57; 10th button typically uses 0: 48 (if your box labels 10 as 0)
  - Letters r,b,g,y: 114, 98, 103, 121
  - ESC: 27
- Note: Many button boxes send numeric ASCII codes; verify with `scripts/list_devices` and your hardware docs.


| Parameter name | Default value | Description |
| :-------------- | :-----------: | :---------- |
| `stimDur`  | `1` | Stimulus presentation time (in seconds). |
| `fixDur`  | `1` | Duration of each post-stimulus fixation (in seconds). |
| `prePost` | `10` | Duration of the pre- and post-run fixation periods (in seconds).|
| `taskName` | *'myexp'* | Name of your experiment, useful to identify it in output files. Try to use a single, meaningful word (*expertisetask*, *localiser*, *maintask*, ...). |
| `resize` | `true` | Resize flag, determines whether your stimuli get resized or not. |
| `resizeMode` | _'visualUnits'_ | If the resize flag is `true`, determines how to resize the images. Two possible values: _visualUnits_ and _pixelSize_ (see [Trial list](#trial-list)). |
| `outWidth` | `8` | If the resize flag is `true`, the width of your resized stimuli (in pixels or degrees of visual angle, depending on your `resizeMode`. Either one of `outWidth` or `outHeight` has to exist if the `resize` flag is `true`.|
| `outHeight` | `8` | If the resize flag is `true`, the height of your resized stimuli. |
| `preloadImages` | `true` | When false, loads each image on demand instead of preloading all at start (saves memory). |
| `numRuns` | `2` | Total number of runs in the experiment. |
| `stimListFile` | *'list_of_stimuli.tsv'* | Name of the file that contains a _partial_ or _full_ list of the experiment trials (see [Trial list](#trial-list)).|
| `numRepetitions` | `2` | How many times to repeat the trials listed in the `stimListFile`. Set to 1 if it contains a full trial list (see [How to write your list of stimuli](#how-to-write-your-list-of-stimuli)). |
| `stimRandomization` | _'run'_ | How to randomize the stimuli in your trial list. Comment out if you don't need any randomisation. Other possible values are 'run' and 'all' (see [Trial randomization](#trial-randomization)). |
| `fixSize` | `.6` | Size of your fixation element (in degrees of visual angle).|
| `fixType` | _'round'_ | Type of fixation element you wish to use (see `displayFixation.m`). Possible values include 'round' and 'cross'.|
| `textSize` | `30` | Size of your text on screen. |
| `textFont` | _'Helvetica'_ | Font of your text on screen. |
| `instructionsText1`, `instructionsText2`, ... | *'On each trial..'* | Line-by-line elements of instruction to give at the beginning of each run. |
| `triggerWaitText` | *'Experiment loading ...'* | Message to display while the script waits for a trigger to begin the task. |
| `scrDistMRI` | `630` | Distance to the screen in the MRI scanner (in mm). |
| `scrWidthMRI` | `340` | Width of the screen in the MRI scanner (in mm). |
| `scrHeightMRI` | optional | Height of the screen in the MRI scanner (in mm). If omitted, it is estimated from aspect ratio. |
| `scrDistPC` | `520` | Estimated distance to the PC screen in debug mode (in mm).  |
| `scrWidthPC` | `510` | Estimated width of the PC screen in debug mode (in mm).|
| `scrHeightPC` | optional | Estimated height of the PC screen (in mm). If omitted, it is estimated from aspect ratio. |
| `useScreenGeometry` | `false` | When true, uses actual screen geometry (px, mm, distance) to compute deg↔px conversions (off by default). |
| `respKeyMRI1Code`, `respKeyMRI2Code` | `51`, `52` | Decimal codes of the response buttons at the scanner (e.g., '3' and '4').|
| `triggerKeyMRICode` | `53` | Decimal code of the MRI trigger (e.g., '5').|
| `respInst1`, `respInst2` | _'left/green'_, _'right/red'_ | Names to display for each key in the instructions at the scanner/PC.|
| `respKeyPC1Code`, `respKeyPC2Code` | `102`, `106` | Decimal keyboard response codes in debug mode (e.g., 'f' and 'j'). |
| `triggerKeyPCCode` | `116` | Decimal code of the mock trigger key in debug mode (e.g., 't').|
| `escapeKeyCode` | `27` | Decimal code of the abort key (ESC).|



### Trial list

The trials of your task will be executed based on the **parameters** and **list of stimuli** file that you input. Upon execution, a list of trials is created that contains all the information about the trials to be played in the experiment.


#### How to write your list of stimuli

Write your list of stimuli in a file called `list_of_stimuli.tsv`, to be placed in the `src` folder. This file should contain _at least_ one column with header name `stimuli`. All other columns are optional, and will be read as extra information and stored in the list of trials output file (see below for an example, with two extra variables `animacy` and `setting`).

```
stimuli     animacy     setting
image1.png  animate     outside
image2.png  inanimate   inside
image3.png  inanimate   outside
image4.png  animate     outside
image5.png  animate     inside
```

Note that the `list_of_stimuli.tsv` is taken as a base to create the output `data/sub-xx/sub-xx_trial-list.tsv`, which merges the input list of stimuli with the output participant responses and any other variables created during the task. As such, make sure you don't enter column names in the `list_of_stimuli.tsv` that will interfere with the writing of these new variables (see below for a breakdown of the columns that will be created).

A special case is that of **`run`**: in the absence of it, a `run` column will be created based on the input parameters. However, if you do include a `run` column in your `list_of_stimuli.tsv` file, it will be considered correct and used as it is in the `trial_list`.


Your list of trials will be built from the list of stimuli provided in the `stimuli` column of your `list_of_stimuli.tsv` file. Here is how the script will proceed:

1. Based on the length of your stimuli column and the number of repetitions (`numRepetitions`), a total number of trials is calculated (stimuli list length * number of repetitions). The list of stimuli is duplicated to match this length.
2. Based on the number of runs, each entry in the list of stimuli gets assigned a run number, considering evenly long runs and starting from 1.

There are two possible ways of writing this list:

- Provide a **full stimuli list**, with one line for each trial of *the whole* experiment, and set the number of repetitions to 1. This is the way to go if you want to control exactly the whole sequence of action.
- Provide a **partial stimuli list**, with one line for each trial of *one/several run(s)* of the experiment, but not for the whole experiment. In this case, set the number of repetitions to >1. This is the way to go if you are repeating the same set of stimuli several times across the experiment.

![trial_list](./src/readme_files/trial_list.png)

The resulting trial list gets enhanced of several extra variables (trial number, etc.). Each time the script is executed, the trials corresponding to the run are extracted into the `runTrials` structure, which is then saved as `yyyy-mm-dd-hh-mm_sub-xx_run-xx_task-taskname.mat` in the results directory (`in.resDir`).

Here are the variables that will be created in the `trialList` structure, on top of `stimuli` and any extra variable you have entered in your `list_of_stimuli.tsv`:

- `run`
- `trialNb`
- `butMap`
- `respKey..`
- `respInst..`
- `subNum..`
- `idealStimOnset`
- `response`

These variables will also end up in the `runTrials` structure, which constitutes the behavioural output that is saved eventually as a `.mat` file.

#### Monitoring accuracy

You might wish to monitor the accuracy of your participants online, to have an idea of how the task is going or to give feedback. This can be achieved by playing with extra variables in your `list_of_stimuli.tsv` file. These variables will automatically be indexed in your trial list and can hence be accessed during/right after trial presentation. The script contains a section showing how to use such variables for accuracy monitoring (see the `%% monitoring accuracy` section, l.290).

#### Trial randomization

You can ask the script to randomize your trials by playing with the `stimRandomization` parameter.

- Comment out the `stimRandomization` parameter in your parameters file if you don't need any randomization from your list of stimuli.
- Set the `stimRandomization` parameter to _'run'_ to randomize your trials within each run.
- Set the `stimRandomization` parameter to _'all'_ to randomize your trials across all runs.

![trial_randomization](./src/readme_files/trial_randomization.png)

#### Fixation trials

You can introduce fixation events in your task by replacing image file names in your list of stimuli by the word _fixation_. The script will read those differently and show a fixation instead of showing a stimulus for these trials.

![fixation_trials](./src/readme_files/fixation_trials.png)

#### Button randomisation & instructions

This task template takes two response buttons, which can be determined using the `respKey` parameters. A random assignment is made for the first run. The order of buttons is then switched across runs. Make sure the repsonse instructions you write in the `respInst` parameters match the order of the response button parameters. These will be used to render correct instructions at the beginning of each run.

![button_mapping](./src/readme_files/button_mapping.png)

The instructions you write line by line in the parameters will be pasted together in a single paragraph. Add as many instruction lines as you need (`instructionsText4`, `instructionsText5`, ...). Make sure to have two **place holders** in your instructions, denoted with parentheses `()`. These will be replaced by the response instructions you gave, and alternated in between runs.

![instructions](./src/readme_files/instructions.png)

### Output

Upon completion and given the `debugMode` flag is off, your `data` folder should look like this:

````
.
├── sub-01
│   ├── YYYY-MM-DD-hh-mm_sub-01_run-01_task-myexp_log.tsv
│   ├── YYYY-MM-DD-hh-mm_sub-01_run-01_task-myexp.mat
│   ├── YYYY-MM-DD-hh-mm_sub-01_run-02_task-myexp_log.tsv
│   ├── YYYY-MM-DD-hh-mm_sub-01_run-02_task-myexp.mat
│   └── ... other runs here
└── sub-02
    └── ...
````

In this output are the following files:

- **log files** are created for each run (i.e. each time you run the script). They contain information about every event in the script, including screen flips, key presses, errors, etc. They are meant to keep track of everything, and to be easily turned into event files later on. By default, they are named *time tag*-*subject number*-*run number*-*experiment name*-*log***.tsv**.
- **`.mat` files** are created for each run and contain every variable created by MatLab during the run, including the `params` and `in` structures, the `runImMat` structure which contains the images themselves, and the `runTrials` structure which contains all the trial-by-trial behavioural output of the task. By default, they are named *time tag*-*subject number*-*run number*-*experiment name***.mat**.

### Timing

An important aspect of this template is that it pays attention to the **timing of events**. Firstly, through a comprehensive **logging**, the script aims at keeping close track of the timing of things. Secondly, during the task itself, event durations are **adapted** so that the run follows the ideal onset of events as closely as possible (see figure below). Here is how things unfold:

1. When started, the script will create a list of **ideal onsets** for all the trials to happen. These ideal onsets are zero-aligned, i.e. the ideal onset of the pre-fixation is `0.0`s, the ideal onset of the first image presentation is `0.0` + `params.prePost` (i.e. `10.0` with default values), the idea onset of the first fixation cross is `0.0 + params.prePost + params.fixDur`, etc.
2. As soon as logging begins, a time stamp is created to record the *script start* (stored in `in.scriptStart`).
3. Once the starting trigger is received from the scanner, the pre-run fixation begins, and the `runStart` time stamp is taken to mark the beginning of the actual task.
4. From the `runStart` time stamp, a `preRunTime` is calculated that reflects how much time has passed since logging started. The `idealStimOnset` is re-calculated based on this value for each successive event. For instance, if an event had an `idealStimOnset` of `45.0` but `13.2` seconds have already passed since the start of logging, then its `idealStimOnset` will be re-calculated and `58.2` will be written instead. This overwriting is done on line 290:
`runTrials(i).idealStimOnset = idealStimOnset;`
5. For each trial, a time stamp if taken when the stimulus is _actually_ shown on the screen, which it records as its `actualOnset`. The script will then calculate a delta between the re-calculated *ideal* and the *actual* onset of the stimulus presentation, and adjust the duration of the subsequent fixation cross duration to compensate. For instance, if a stimulus has an `actualOnset` of `25.56` but an `idealStimOnset` of `25.55`, the subsequent fixation cross will stay on screen for `params.fixDur - 0.01`. This adjustment is done by the `adjustFixationDuration` function.

This procedure is reflected in the log files, which contain a `EXP_ONSET` and a `ACTUAL_ONSET` column for all `Stim` and `Fix` events, containing the `idealStimOnset` and the `actualOnset` values, respectively. The `DELTA` column shows the difference between the two. It's worth noting that the onsets logged in these columns are *aligned to the start of the script* (`in.scriptStart`). This is useful from a logging perspective, as it allows to keep track of _all events_, including instruction display, pre-fixation, etc. However, this is not the format expected by BIDS. According to BIDS convention, onset values must be aligned to the start of the run (`runStart`), i.e. when the recording starts. To be able to use log files as event files, it is essential then to re-align the `ACTUAL_ONSET` column to create the final `onset` column.

![timing_adjustment_logic](./src/readme_files/timing_adjustment_logic.png)

### Response keys

Registering responses correctly is key. Here is how the script handles this aspect of the task:
- In `src/config.m`, declare your response keys explicitly as decimal codes (not strings). For instance: `respKeyPC1Code = 102` for the `f` key.
  Example (PC/dev):
  ```
  config.m                  params
  respKeyPC1Code = 102      params.respKey1Code = 102
  respKeyPC2Code = 106      params.respKey2Code = 106
  triggerKeyPCCode = 116    params.triggerKeyCode = 116
  ```
- When an input is detected, `logKeyPressDual` polls trigger and response queues, compares decimal key codes against the configured response and trigger keys, and logs the events. It returns the first response key for behavioral data while logging all key presses.

A few more remarks:
- Response keys are represented as decimal codes for matching (see `params.respKeysCode`).
  Response keys are determined per run and stored as a list of decimal codes:
  ```
  % Response codes for the current run
  respKey1Code = runTrials(1).respKey1Code;
  respKey2Code = runTrials(1).respKey2Code;
  params.respKeysCode = [respKey1Code, respKey2Code];
  ```
  This list is used by `logKeyPress` to compare the received input, and return it only if it is part of the expected response keys. This has the advantage of only returning _one_ behavioural response to the `runTrials` structure that is part of the instructed response buttons (all responses are logged regardless). The list format allows for more response keys to easily be fitted into this logic, which we repeat for every run as the arrangement of keys might change (e.g. left and right button switching across runs).

### Trouble shooting notes

This section lists the most often encountered bugs and their solution.

| Problem | Resolution |
| :------ | :--------- |
| **Screen Setup** | If you get an error from the `screen setup` section, it might be a problem with the system frame rate and the frame rate detected by PTB. Perhaps you are using an external monitor? If so, try disconnecting the external monitor, or set `SkipSyncTests` to 1 (ATTENTION: DON`T DO THIS IF YOU ARE RUNNING THE REAL EXPERIMENT! ONLY FOR DEBUG PURPOSES). |
| **Trigger Wait** | There is a known bug currently (as of the 21st of March 2024) where the MRI scanner sends two triggers before beginning. As a result, two keys presses are logged in the trigger wait section, with the start of each run actually taking place after the **second** trigger.|
| **Keyboard silent** | Did your script crash, and now you cannot write anything in Matlab anymore? Maybe your keyboard is still silent. You need to enable input listening again by running `ListenChar(0)`. Find a way to run that segment, for instance by finding it in `saveAndClose`, highlighting and evaluating it.|
### Quick check

Run `scripts/quick_check.m` to verify configuration, trial list, and a small image preload without opening a PTB window.

### Debug options (optional)

- `debug.writeLogs`: when true, writes log files in debug mode (default false).
- `debug.saveMat`: when true, saves `.mat` outputs in debug mode (default false).
- `debug.windowScale`: scale for the debug window size (default 0.9).
- `debug.slowMoFactor`: scales `stimDur` and `fixDur` only in debug (default 1.0).
- `debug.overlay`: draws a small debug overlay text on the screen (default false).
- `debug.skipSyncTests`: override sync tests in debug (0 or 1). In release, you can set `debug.releaseSkipSyncTests`.
- `debug.rngSeed`: integer; if set, debug runs are deterministic.
- `debug.warnOnDrift`: when true, logs a `WARN` line when stimulus onset drift exceeds `debug.driftWarnMs` (default 10 ms). Default false.

Simulating triggers and button presses
- To simulate scanner triggers and button box responses in debug mode, configure the PC codes in `src/config.m` to the keys you want to press (e.g., `triggerKeyPCCode = 116` for `t`, `respKeyPC1Code = 102` for `f`, `respKeyPC2Code = 106` for `j`). This gives you complete control over what signal you send while using your keyboard.

### Key code reference

Below are common decimal codes you can copy into your `src/config.m` (provided for convenience; verify with your hardware):

- Digits: 1=49, 2=50, 3=51, 4=52, 5=53, 6=54, 7=55, 8=56, 9=57, 0=48 (use as 10 if your box labels 10 as 0)
- Letters/colors: r=114, b=98, g=103, y=121
- Escape: 27
### Customizing Your Task

The template is designed for easy customization without modifying core utilities. Most studies customize 1-3 of these common aspects:

#### Level 1: Configuration Only (90% of studies)

**What**: Change timing, response keys, trial structure via `src/config.m` and `src/list_of_stimuli.tsv`.

**When to use**: Standard designs (blocked, event-related, mixed) with image stimuli and binary responses.

**Example**: 2AFC categorization task with 3 runs, 10s fixation blocks
```matlab
% In src/config.m:
params.taskName = 'category';
params.numRuns = 3;
params.stimDur = 1.5;  % 1.5s stimulus
params.fixDur = 2.5;   % 2.5s fixation (4s total per trial)
params.prePost = 10;   % 10s pre/post fixation blocks
```

#### Level 2: Custom Trial Logic (Most common)

**What**: Modify trial loop in `fMRI_task.m` to add feedback, rating scales, or conditional displays.

**When to use**: Need visual feedback, multi-button responses, or response-contingent displays.

**Where to edit**: Trial loop section in `fMRI_task.m` (lines ~227-324). Key customization points:
- **Line ~235**: Stimulus display (`displayTrial` call) - change what's shown
- **Line ~261-279**: Response collection - change input method (rating scale, multi-button)
- **After line ~311**: Add feedback display based on response

**Example**: Add visual feedback
```matlab
% After line ~311 in fMRI_task.m (after response is stored):
if isfield(runTrials(i), 'correctAnswer')
    isCorrect = (runTrials(i).response == runTrials(i).correctAnswer);
    Screen('FillRect', win, in.gray);
    if isCorrect
        DrawFormattedText(win, 'Correct!', 'center', 'center', [0 255 0]);
    else
        DrawFormattedText(win, 'Wrong', 'center', 'center', [255 0 0]);
    end
    VBL = Screen('Flip', win);
    logEvent(logFile, 'FLIP', 'Feedback', dateTimeStr, '-', VBL - in.scriptStart, '-', '-');
    WaitSecs(0.5);
end
```

#### Level 3: Custom Trial List Generation

**What**: Create custom trial list builder for complex designs (blocking, counterbalancing, adaptive).

**When to use**: Need blocked designs, custom randomization, or trial-by-trial parameter control.

**How**: Create `src/makeTrialListCustom.m` and call it instead of `makeTrialList` in `fMRI_task.m` line ~131.

**Example**: Blocked design with 3 conditions
```matlab
function trialList = makeTrialListCustom(params, in)
    % Create 3 conditions (A, B, C) in 4 blocks per run
    trialsPerBlock = 8;
    conditions = {'condA', 'condB', 'condC', 'condA'};
    % ... build trial list with block structure
    % See examples/CUSTOMIZATION_EXAMPLES.md for full code
end
```

#### Level 4: Advanced Customization

**What**: Custom instructions, stimulus rendering, or input handling.

**When to use**: Need non-standard displays (movies, real-time rendering) or specialized input devices.

**How**: Create custom display functions in `src/` and call from orchestrator functions.

**Resources**:
- **Full examples**: See `examples/CUSTOMIZATION_EXAMPLES.md` for 6 complete examples
- **Quick iteration**: Use `scripts/dev_smoke` for fast 2-trial testing
- **Architecture**: See `CLAUDE.md` for utilities organization and data flow

#### Customization Tips

1. **Keep study logic in `src/` or main script** - Don't modify `utils/` functions
2. **Use config for parameters** - Add fields to `src/config.m` instead of hardcoding
3. **Log custom events** - Use `logEvent(logFile, 'INFO', 'YourEvent', ...)` for analysis
4. **Test incrementally** - Run `debugMode=true` after each change
5. **Preserve timing** - Don't alter `idealStimOnset` calculations (needed for drift compensation)

### First run checklist

- From MATLAB, set your current folder to the repository root.
- Open `src/config.m` and set:
  - `taskName`, `numRuns`, `numRepetitions` and timing fields (`stimDur`, `fixDur`, `prePost`).
  - response keys (`respKeyPC1`, `respKeyPC2`, `triggerKeyPC`) for PC/dev mode; MRI keys for scanner.
  - Optional: `deviceIDs.trigger` and `deviceIDs.response` to bind trigger and response queues (see Device IDs below).
  - Optional: up to 10 `buttons` and/or `buttonDecimalCodes` for supported button boxes.
- Run a smoke test without opening PTB windows: `scripts/quick_check`.
- Start a debug run: set `debugMode = true` in `fMRI_task.m` and run the script.
- For quick iteration during development: use `scripts/dev_smoke` (2 trials only, deterministic).

### Device IDs

Use `scripts/list_devices` to print PsychHID devices and indices. Populate `deviceIDs.trigger` and `deviceIDs.response` in `src/config.m` with these indices to ensure the trigger and response queues listen to the correct devices. The template uses dual queues so simultaneous trigger + button presses are both logged.
