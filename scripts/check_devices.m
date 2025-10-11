function check_devices()
%CHECK_DEVICES Sanity test trigger/response device IDs from src/config.m.
%   Prints whether configured device indices are present according to
%   PsychHID. Run from repo root in MATLAB.

addpath('./utils');
cfgPath = fullfile('src','config.m');
if exist(cfgPath,'file')~=2, error('File:NotFound','Missing %s', cfgPath); end
params = TaskConfig.load(cfgPath, false);

try
    devs = PsychHID('Devices');
catch ME
    error('PTB:DevicesFailed', 'PsychHID failed: %s', ME.message);
end
idx = [devs.index];

function printStatus(name, id)
    if isempty(id)
        fprintf('%s: (unset)\n', name);
    elseif any(idx == id)
        fprintf('%s: %d OK\n', name, id);
    else
        fprintf('%s: %d NOT FOUND (run scripts/list_devices)\n', name, id);
    end
end

trigID = [];
if isfield(params,'triggerDeviceID'), trigID = params.triggerDeviceID; end
respID = [];
if isfield(params,'responseDeviceID'), respID = params.responseDeviceID; end
printStatus('trigger', trigID);
printStatus('response', respID);

end
