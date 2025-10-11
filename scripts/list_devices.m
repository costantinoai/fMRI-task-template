function list_devices()
%LIST_DEVICES Script wrapper around utils/listDevices for convenience.
%   Run this from the repo root in MATLAB to list device indices used in
%   src/config.m (deviceIDs.trigger and deviceIDs.response).

addpath('./utils');
listDevices();
end
