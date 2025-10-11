function detect_button_codes()
%DETECT_BUTTON_CODES Interactive utility to discover device indices and key codes.
% - Prints device index, device name, and decimal code for each key press.
% - Works across all keyboard candidate indices reported by GetKeyboardIndices.
% - Press ESC (27) to exit.
%
% Usage: Run from repo root in MATLAB:  scripts/detect_button_codes

addpath('./utils');

fprintf('Detecting keyboard candidate devices ...\n');
try
    kbdIdx = GetKeyboardIndices();
catch ME
    error('PTB:GetKeyboardIndicesFailed', 'GetKeyboardIndices failed: %s', ME.message);
end
if isempty(kbdIdx)
    error('PTB:NoKeyboards', 'No keyboard candidate devices found.');
end

% Map indices to device names
devs = PsychHID('Devices');
devNames = containers.Map('KeyType','double','ValueType','char');
for i = 1:numel(devs)
    devNames(devs(i).index) = devs(i).product;
end

ListenChar(2);
cleanup = onCleanup(@() ListenChar(0));

% Create queues for all keyboard indices
for id = kbdIdx
    KbQueueCreate(id);
    KbQueueStart(id);
end
fprintf('Press keys on your device(s). Press ESC (10) to quit.\n');

esc = 10; % decimal code
running = true;
while running
    for id = kbdIdx
        [pressed, firstPress] = KbQueueCheck(id);
        if pressed
            % Get first key code
            code = find(firstPress, 1);
            if ~isempty(code)
                name = '(unknown)';
                if isKey(devNames, id), name = devNames(id); end
                fprintf('Device %d [%s] -> Code %d\n', id, name, code);
                if code == esc
                    running = false; break;
                end
            end
            KbQueueFlush(id);
        end
    end
    WaitSecs(0.01);
end

% Stop and release queues
for id = kbdIdx
    try, KbQueueStop(id); KbQueueRelease(id); catch, end
end

end

