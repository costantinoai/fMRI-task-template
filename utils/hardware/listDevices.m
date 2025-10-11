function listDevices()
%LISTDEVICES Print PsychHID devices and indices to help configure deviceIDs.
%   Lists available devices and marks keyboard candidates per PTB's
%   GetKeyboardIndices. If 'master' field is available, prints that too.

try
    devs = PsychHID('Devices');
catch ME
    error('PTB:DevicesFailed', 'Failed to query devices via PsychHID: %s', ME.message);
end

% Get candidate keyboard indices
kbdIdx = [];
try, kbdIdx = GetKeyboardIndices(); catch, end

fprintf('Index\tKbd?\tMaster?\tUsageName\t\tProduct\t\tVendorID\tProductID\n');
for i = 1:numel(devs)
    d = devs(i);
    usage = '';
    if isfield(d,'usageName') && ~isempty(d.usageName), usage = d.usageName; end
    isKbd = ismember(d.index, kbdIdx);
    if isfield(d,'master')
        isMaster = d.master;
    else
        isMaster = NaN; % unknown
    end
    fprintf('%d\t%s\t%s\t%s\t\t%s\t\t%d\t%d\n', d.index, tf(isKbd), tf(isMaster), usage, d.product, d.vendorID, d.productID);
end

fprintf(['\nUse device indices returned by GetKeyboardIndices() for KbQueue. ', ...
         'Configure these in src/config.m (deviceIDs.trigger/response).\n']);

end

function s = tf(x)
if isnan(x), s = 'n/a'; elseif x, s = 'yes'; else, s = 'no'; end
end
