function cfg = config()
%CONFIG MATLAB configuration for the fMRI task template.
%  Returns a struct with all parameters consumed by TaskConfig.load.
%  Edit values below to match your study. Field names are stable and
%  mapped 1:1 into the params struct used at runtime.

% --- Timing ---
cfg.stimDur  = 1;    % s
cfg.fixDur   = 1;    % s
cfg.prePost  = 10;   % s

% --- Task info ---
cfg.taskName = 'myexp';

% --- Event names (used in logging) ---
cfg.eventNames = struct();
cfg.eventNames.instruction = 'Instr';
cfg.eventNames.triggerWait = 'TgrWait';
cfg.eventNames.preFix      = 'Pre-fix';
cfg.eventNames.stimulus    = 'Stim';
cfg.eventNames.fixation    = 'Fix';
cfg.eventNames.postFix     = 'Post-fix';

% --- Image resize ---
cfg.resize     = true;
cfg.resizeMode = 'visualUnits';   % 'visualUnits' or 'pixelSize'
cfg.outWidth   = 8;               % deg or px depending on resizeMode
% cfg.outHeight  = 8;  % Uncomment to force height

% --- Runs & stimuli ---
cfg.numRuns        = 2;
cfg.stimListFile   = './src/list_of_stimuli.tsv';
cfg.numRepetitions = 2;
cfg.stimRandomization = 'run';    % 'run', 'all', or omit

% --- Fixation & text ---
cfg.fixSize  = .6;         % deg
cfg.fixType  = 'round';    % 'round' or 'cross'
cfg.textSize = 30;
cfg.textFont = 'Helvetica';

% --- Instructions ---
% Provide exactly two '()' placeholders across these lines
cfg.instructionsText1 = 'On each trial judge whether the image is inside or outside.';
cfg.instructionsText2 = 'Press () for the inside, or press () for outside.';
cfg.instructionsText3 = '';
cfg.instructionsText4 = 'Press any button to begin!';
cfg.triggerWaitText   = 'Experiment loading ...';

% --- Screen geometry (mm) ---
cfg.scrDistMRI  = 630;
cfg.scrWidthMRI = 340;
% cfg.scrHeightMRI = 190;  % optional
cfg.scrDistPC   = 520;
cfg.scrWidthPC  = 510;
% cfg.scrHeightPC = 300;   % optional
cfg.useScreenGeometry = false;  % keep false unless measured geometry is desired

% --- Response instructions labels ---
cfg.respInst1 = 'left/green';
cfg.respInst2 = 'right/red';

% --- Key/button codes (decimals) ---
% Prefer mode-specific sets; TaskConfig will pick the right one.
% PC/dev keyboard
cfg.buttonsPC = [25, 26, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN]; % q,w (per prior config)
cfg.triggerKeyPCCode = 15;
cfg.escapeKeyPCCode  = 10;

% MRI button box (e.g., '3'=51, '4'=52, trigger '5'=53)
cfg.buttonsFMRI       = [102, 106, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN];
cfg.triggerKeyMRICode = 53;
cfg.escapeKeyMRICode  = 27;

% Optional: canonical key map (decimals) and custom codes
% cfg.keyMap = struct('one',49,'two',50,'three',51,'four',52,'five',53);
% cfg.buttonDecimalCodes = [49 50 51 52 53 54 55 56 57 48];
% cfg.colorDecimalCodes  = struct('r',114,'b',98,'g',103,'y',121);

% --- Device binding (PsychHID indices) ---
cfg.deviceIDs = struct('trigger', [], 'response', []);

% --- Trigger & debounce policies ---
cfg.triggerPolicy  = 'double';   % site-specific; default 'double'
cfg.triggerWindowMs = 100;       % ms
cfg.debounceWindowMs = 0;        % ms

% --- Debug options (optional) ---
cfg.debug = struct();
cfg.debug.writeLogs = false;
cfg.debug.saveMat   = false;
cfg.debug.windowScale = 0.5;
cfg.debug.slowMoFactor = 1.0;
cfg.debug.overlay   = false;
cfg.debug.skipSyncTests = 0;
cfg.debug.releaseSkipSyncTests = [];
cfg.debug.warnOnDrift = false;
cfg.debug.driftWarnMs = 10;
cfg.debug.rngSeed = [];

end
