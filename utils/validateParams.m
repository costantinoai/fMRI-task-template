function validateParams(params, fmriMode)
%VALIDATEPARAMS Validate required fields and basic ranges; fail early.

% Required basics
req = {'stimDur','fixDur','prePost','taskName','resize','numRuns', ...
       'stimListFile','numRepetitions','fixSize','fixType', ...
       'textSize','textFont','triggerWaitText', ...
       'scrDistMRI','scrWidthMRI','scrDistPC','scrWidthPC', ...
       'respInst1','respInst2'};
missing = setdiff(req, fieldnames(params));
if ~isempty(missing)
    error('Params:MissingField', ['Missing required params: %s. Edit src/config.m to add these fields. ', ...
        'See README for configuration details.'], strjoin(missing, ', '));
end

% File presence
if exist(params.stimListFile, 'file') ~= 2
    error('File:NotFound', ['Stimulus list file not found: %s. Ensure src/list_of_stimuli.tsv exists ', ...
        'or update stimListFile in src/config.m.'], params.stimListFile);
end

% Allowed values / ranges
ensure(params.stimDur > 0, 'Params:InvalidValue', 'stimDur must be > 0 seconds.');
ensure(params.fixDur >= 0, 'Params:InvalidValue', 'fixDur must be >= 0 seconds.');
ensure(params.prePost >= 0, 'Params:InvalidValue', 'prePost must be >= 0 seconds.');
ensure(params.numRuns >= 1, 'Params:InvalidValue', 'numRuns must be >= 1.');
ensure(params.numRepetitions >= 1, 'Params:InvalidValue', 'numRepetitions must be >= 1.');
ensure(params.fixSize > 0, 'Params:InvalidValue', 'fixSize must be > 0 (degrees).');
ensure(ischar(params.fixType) || isstring(params.fixType), 'Params:InvalidValue', 'fixType must be a string (e.g., "round" or "cross").');
if isfield(params, 'stimRandomization')
    ok = any(strcmp(params.stimRandomization, {'run','all'}));
    ensure(ok, 'Params:InvalidValue', 'stimRandomization must be "run" or "all".');
end

% Keys
% Unified keys requirement: buttons[] and escape key
reqk = {'buttons','escapeKeyCode'};
missing = setdiff(reqk, fieldnames(params));
if ~isempty(missing)
    error('Params:MissingKeys', ['Missing key params: %s. Add them in src/config.m. ', ...
        'Define a ''buttons'' array (at least 2 entries) and an ''escapeKeyCode''.'], strjoin(missing, ', '));
end

% Buttons (optional): max 10
ensure(isfield(params,'buttons') && numel(params.buttons) >= 2, 'Params:InvalidButtons', 'Buttons array must define at least positions 1 and 2.');
ensure(numel(params.buttons) <= 10, 'Params:TooManyButtons', 'Too many buttons (max 10).');

% Numeric-only policy for key codes
codes = [params.escapeKeyCode, params.respKey1Code, params.respKey2Code, params.triggerKeyCode];
ensure(all(arrayfun(@(x) isnumeric(x) && isfinite(x), codes)), 'Params:InvalidValue', 'All key codes must be numeric decimals.');

% Device ID sanity checks (if provided)
if isfield(params, 'triggerDeviceID') && ~isempty(params.triggerDeviceID)
    ensureDeviceExists(params.triggerDeviceID, 'deviceIDs.trigger');
end
if isfield(params, 'responseDeviceID') && ~isempty(params.responseDeviceID)
    ensureDeviceExists(params.responseDeviceID, 'deviceIDs.response');
end

end

function ensure(cond, id, msg)
if ~cond
    error(id, msg);
end
end

function ensureDeviceExists(devIndex, fieldName)
try
    devs = PsychHID('Devices');
catch ME
    error('PTB:DevicesFailed', 'Failed to query devices via PsychHID: %s', ME.message);
end
idx = [devs.index];
if ~any(idx == devIndex)
    error('Device:NotFound', 'Device index %d not found (configure %s). Run scripts/list_devices to inspect indices.', devIndex, fieldName);
end
end
