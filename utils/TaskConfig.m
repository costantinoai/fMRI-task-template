classdef TaskConfig
    %TASKCONFIG Load and validate task configuration from MATLAB config.
    %   Usage:
    %       params = TaskConfig.load('src/config.m', fmriMode)
    %   Produces a struct 'params' compatible with the existing codebase,
    %   preserving field names and derived values (e.g., trialDur).

    methods(Static)
        function params = load(configPath, fmriMode)
            % Fail early if file missing
            if exist(configPath, 'file') ~= 2
                error('Config:NotFound', 'Config not found at %s. Create src/config.m or pass a correct path.', configPath);
            end

            % Evaluate MATLAB config function (must return a struct)
            try
                [cfgDir, cfgFunc, cfgExt] = fileparts(configPath);
                if strcmpi(cfgExt, '.m') ~= 1
                    error('Config:InvalidType', 'Expected a MATLAB config file (.m) at %s.', configPath);
                end
                % Temporarily add its folder to path to call the function
                added = false;
                if ~isempty(cfgDir) && exist(cfgDir,'dir')==7 && ~contains(path, cfgDir)
                    addpath(cfgDir); added = true;
                end
                % Ensure we remove the added path on function exit without
                % using short-circuit ops in anonymous function (which
                % causes scalar logical errors). Use a small helper.
                cleaner = onCleanup(@() localRemovePath(added, cfgDir));
                cfg = feval(cfgFunc);
                if ~isstruct(cfg)
                    error('Config:InvalidReturn', 'Config function %s must return a struct.', cfgFunc);
                end
            catch ME
                error('Config:InvalidMATLAB', 'Invalid MATLAB config in %s: %s', configPath, ME.message);
            end

            % Initialize params as struct and map fields 1:1 where possible
            params = struct();

            % Timing
            params.stimDur  = cfg.stimDur;
            params.fixDur   = cfg.fixDur;
            params.prePost  = cfg.prePost;

            % Task name
            params.taskName = cfg.taskName;

            % Resize
            params.resize     = logical(cfg.resize);
            if isfield(cfg, 'resizeMode'), params.resizeMode = cfg.resizeMode; end
            if isfield(cfg, 'outWidth'),   params.outWidth   = cfg.outWidth; end
            if isfield(cfg, 'outHeight'),  params.outHeight  = cfg.outHeight; end

            % Runs & stimuli
            params.numRuns         = cfg.numRuns;
            params.stimListFile    = cfg.stimListFile;
            params.numRepetitions  = cfg.numRepetitions;
            if isfield(cfg, 'stimRandomization')
                params.stimRandomization = cfg.stimRandomization;
            end
            % Image preload control (default true)
            if isfield(cfg, 'preloadImages')
                params.preloadImages = logical(cfg.preloadImages);
            else
                params.preloadImages = true;
            end

            % Fixation & text
            params.fixSize = cfg.fixSize;
            params.fixType = cfg.fixType;
            params.textSize = cfg.textSize;
            params.textFont = cfg.textFont;

            % Instructions & trigger text (keep fields as before)
            fn = fieldnames(cfg);
            for i = 1:numel(fn)
                if startsWith(fn{i}, 'instructionsText')
                    params.(fn{i}) = cfg.(fn{i});
                end
            end
            params.triggerWaitText = cfg.triggerWaitText;

            % Screen geometry (MRI & PC)
            params.scrDistMRI  = cfg.scrDistMRI;
            params.scrWidthMRI = cfg.scrWidthMRI;
            params.scrDistPC   = cfg.scrDistPC;
            params.scrWidthPC  = cfg.scrWidthPC;
            % Optional screen height (mm)
            if isfield(cfg, 'scrHeightMRI'), params.scrHeightMRI = cfg.scrHeightMRI; end
            if isfield(cfg, 'scrHeightPC'),  params.scrHeightPC  = cfg.scrHeightPC;  end
            % Optional geometry accuracy flag
            if isfield(cfg, 'useScreenGeometry')
                params.useScreenGeometry = logical(cfg.useScreenGeometry);
            else
                params.useScreenGeometry = false;
            end

            % Response instructions text
            params.respInst1 = cfg.respInst1;
            params.respInst2 = cfg.respInst2;

            % Unified button codes (up to 10 positions), decimals only. Also
            % support mode-specific arrays: buttonsPC (debug) and buttonsFMRI.
            btn = [];
            if fmriMode && isfield(cfg,'buttonsFMRI')
                btn = cfg.buttonsFMRI(:)';
            elseif ~fmriMode && isfield(cfg,'buttonsPC')
                btn = cfg.buttonsPC(:)';
            elseif isfield(cfg, 'buttons')
                btn = cfg.buttons(:)';
            end
            % Normalize: treat empty entries as NaN
            if isempty(btn)
                btn = nan(1,10);
            else
                if numel(btn) < 10
                    btn = [btn nan(1, 10-numel(btn))]; %#ok<AGROW>
                elseif numel(btn) > 10
                    btn = btn(1:10);
                end
            end
            params.buttons = btn;
            % Escape key (decimal): prefer mode-specific, fallback to unified
            if fmriMode && isfield(cfg,'escapeKeyMRICode') && ~isempty(cfg.escapeKeyMRICode)
                params.escapeKeyCode = cfg.escapeKeyMRICode;
            elseif ~fmriMode && isfield(cfg,'escapeKeyPCCode') && ~isempty(cfg.escapeKeyPCCode)
                params.escapeKeyCode = cfg.escapeKeyPCCode;
            else
                params.escapeKeyCode = cfg.escapeKeyCode;
            end

            % Optional device IDs for dual queues
            if isfield(cfg, 'deviceIDs')
                if isfield(cfg.deviceIDs,'trigger') && ~isempty(cfg.deviceIDs.trigger)
                    params.triggerDeviceID = cfg.deviceIDs.trigger;
                else
                    params.triggerDeviceID = [];
                end
                if isfield(cfg.deviceIDs,'response') && ~isempty(cfg.deviceIDs.response)
                    params.responseDeviceID = cfg.deviceIDs.response;
                else
                    params.responseDeviceID = [];
                end
            end

            % Optional canonical key map (labels); decimal codes will be computed
            if isfield(cfg, 'keyMap')
                params.keyMap = cfg.keyMap; % now expected as decimals
            end

            % Optional support for up to 10 buttons via labels and/or decimal codes
            if isfield(cfg, 'buttons')
                % Expected up to 10 entries, labels such as '1'...'10' or device-specific strings
                params.buttons = cfg.buttons; % decimals only
            end
            if isfield(cfg, 'buttonDecimalCodes')
                % Device-provided decimal codes (e.g., 53 for '5'); use as-is
                params.buttonDecimalCodes = cfg.buttonDecimalCodes(:)';
            end
            if isfield(cfg, 'colorDecimalCodes')
                params.colorDecimalCodes = cfg.colorDecimalCodes(:)';
            end

            % Derived fields
            params.trialDur = params.stimDur + params.fixDur;

            % Mode‑specific screen & key selections
            % Screen geometry
            if fmriMode
                params.scrDist = params.scrDistMRI;
                params.scrWidth = params.scrWidthMRI;
            else
                params.scrDist = params.scrDistPC;
                params.scrWidth = params.scrWidthPC;
            end

            % Response keys 1 and 2 from unified buttons list
            params.respKey1Code = params.buttons(1);
            params.respKey2Code = params.buttons(2);

            % Trigger code: prefer mode-specific, then unified, default 53
            if fmriMode && isfield(cfg,'triggerKeyMRICode') && ~isempty(cfg.triggerKeyMRICode)
                params.triggerKeyCode = cfg.triggerKeyMRICode;
            elseif ~fmriMode && isfield(cfg,'triggerKeyPCCode') && ~isempty(cfg.triggerKeyPCCode)
                params.triggerKeyCode = cfg.triggerKeyPCCode;
            elseif isfield(cfg, 'triggerKeyCode') && ~isempty(cfg.triggerKeyCode)
                params.triggerKeyCode = cfg.triggerKeyCode;
            else
                params.triggerKeyCode = 53;
            end

            % Pack response key codes for convenience
            params.respKeysCode = [params.respKey1Code, params.respKey2Code];

            % Compute canonical key map decimal codes if labels provided
            if isfield(params, 'keyMap')
                params.keyCodes = params.keyMap; % already decimals
            end

            % Optional debug block (pass-through; defaults handled in main)
            if isfield(cfg, 'debug') && isstruct(cfg.debug)
                params.debug = cfg.debug;
            end

            % Trigger policy (site-specific); default 'double'
            if isfield(cfg, 'triggerPolicy')
                params.triggerPolicy = cfg.triggerPolicy;
            else
                params.triggerPolicy = 'double';
            end
            if isfield(cfg, 'triggerWindowMs')
                params.triggerWindowMs = cfg.triggerWindowMs;
            else
                params.triggerWindowMs = 100; % ms
            end

            % Optional debounce window for duplicate keys (ms)
            if isfield(cfg, 'debounceWindowMs')
                params.debounceWindowMs = cfg.debounceWindowMs;
            else
                params.debounceWindowMs = 0;
            end
        end
    end
end

function localRemovePath(added, cfgDir)
%LOCALREMOVEPATH Remove cfgDir from path if it was added.
    try
        if added && ~isempty(cfgDir) && exist(cfgDir,'dir')==7
            rmpath(cfgDir);
        end
    catch
        % ignore
    end
end
