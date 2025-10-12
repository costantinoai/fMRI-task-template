function inputDevs = createInputQueues(params)
%CREATEINPUTQUEUES Create and start input queues for trigger and responses.
%   inputDevs = createInputQueues(params)
%   Extracts device IDs from params.deviceIDs (if present), otherwise uses defaults.
%
%   This function centralizes queue setup logic. It supports a single
%   device used for both trigger and responses (created once), or two
%   separate devices (created separately).
%
% Inputs:
%   params - Must include params.deviceIDs.trigger and params.deviceIDs.response
%            (or pass [] to use defaults)
%
% Outputs:
%   inputDevs - Struct with trigger and response device arrays
%
% Example:
%   inputDevs = createInputQueues(params);

% Extract device IDs from params (if provided)
if nargin < 1 || ~isstruct(params) || ~isfield(params, 'deviceIDs') || ~isstruct(params.deviceIDs)
    triggerDeviceID = [];
    responseDeviceID = [];
else
    triggerDeviceID = params.deviceIDs.trigger;
    responseDeviceID = params.deviceIDs.response;
end

% Default to empty -> default device
if isempty(triggerDeviceID)
    triggerDeviceID = [];
end
if isempty(responseDeviceID)
    responseDeviceID = [];
end

% Capture original inputs to decide if a fallback is acceptable
origTrig = triggerDeviceID;
origResp = responseDeviceID;

% Create queues (catch if already exist)

% Helper to validate device indices: ensure it's a keyboard and not master
function okId = queueable(id)
    okId = []; % default -> use default device
    if isempty(id), return; end
    try
        % Prefer PTB helper: GetKeyboardIndices provides valid indices
        kbdIdx = GetKeyboardIndices();
        if ~isempty(kbdIdx) && any(kbdIdx == id)
            % Probe for master flag if present
            try
                devs = PsychHID('Devices');
                idx = find([devs.index] == id, 1);
                if ~isempty(idx) && isfield(devs(idx),'master') && devs(idx).master
                    okId = [];
                else
                    okId = id;
                end
            catch
                okId = id; % accept if kbdIdx contains it
            end
        else
            okId = []; % Not a keyboard index
        end
    catch
        % Fallback: Try PsychHID-based heuristic
        try
            devs = PsychHID('Devices');
            idx = find([devs.index] == id, 1);
            if ~isempty(idx)
                d = devs(idx);
                if isfield(d,'master') && d.master
                    okId = [];
                else
                    okId = id;
                end
            end
        catch
            okId = [];
        end
    end
end

% Sanitize provided ids
triggerDeviceID = queueable(triggerDeviceID);
responseDeviceID = queueable(responseDeviceID);

% If user provided an id that resolves to master (disallowed), fail early
if ~isempty(origTrig) && isempty(triggerDeviceID)
    error('Device:NotKeyboardOrMaster', ['Trigger device index %d is not a valid keyboard for KbQueue (master or non-keyboard). ', ...
        'Run scripts/list_devices and scripts/list_keyboards to choose a valid keyboard device, or leave deviceIDs empty.'], origTrig);
end
if ~isempty(origResp) && isempty(responseDeviceID)
    error('Device:NotKeyboardOrMaster', ['Response device index %d is not a valid keyboard for KbQueue (master or non-keyboard). ', ...
        'Run scripts/list_devices and scripts/list_keyboards to choose a valid keyboard device, or leave deviceIDs empty.'], origResp);
end

% If both empty or equal after sanitization, create/start a single default/device queue once
sameDevice = (isempty(triggerDeviceID) && isempty(responseDeviceID)) || ...
             (~isempty(triggerDeviceID) && ~isempty(responseDeviceID) && triggerDeviceID == responseDeviceID);

if sameDevice
    try
        if isempty(triggerDeviceID)
            KbQueueCreate(); KbQueueStart();
        else
            KbQueueCreate(triggerDeviceID); KbQueueStart(triggerDeviceID);
        end
    catch ME
        if ~isempty(triggerDeviceID)
            error('Device:QueueCreateFailed', 'Failed to create queue for device %d: %s', triggerDeviceID, ME.message);
        else
            error('Device:DefaultQueueFailed', 'Failed to create default queue: %s', ME.message);
        end
    end
else
    % Create/start trigger queue
    try
        if isempty(triggerDeviceID)
            KbQueueCreate(); KbQueueStart();
        else
            KbQueueCreate(triggerDeviceID); KbQueueStart(triggerDeviceID);
        end
    catch ME
        if ~isempty(triggerDeviceID)
            error('Device:QueueCreateFailed', 'Failed to create trigger queue for device %d: %s', triggerDeviceID, ME.message);
        else
            error('Device:DefaultQueueFailed', 'Failed to create default trigger queue: %s', ME.message);
        end
    end
    % Create/start response queue
    try
        if isempty(responseDeviceID)
            KbQueueCreate(); KbQueueStart();
        else
            KbQueueCreate(responseDeviceID); KbQueueStart(responseDeviceID);
        end
    catch ME
        if ~isempty(responseDeviceID)
            error('Device:QueueCreateFailed', 'Failed to create response queue for device %d: %s', responseDeviceID, ME.message);
        else
            error('Device:DefaultQueueFailed', 'Failed to create default response queue: %s', ME.message);
        end
    end
end

% Return IDs for downstream calls; [] denotes default device
inputDevs = struct('trigger', triggerDeviceID, 'response', responseDeviceID);

end
