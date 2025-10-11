function [firstPressedKey, in] = logKeyPressDual(params, in, logFile, triggerKeyBreaks, otherKeysBreak, conditionFunc, inputDevs)
% LOGKEYPRESSDUAL Log key presses from separate trigger and response queues.
%   Polls two queues (trigger and response) to avoid missing simultaneous
%   events. Preserves existing log event types/names and returns the first
%   response key if it matches the expected response keys.

firstPressedKey = [];

% Debounce window
debounceSec = 0;
if isfield(params,'debounceWindowMs') && params.debounceWindowMs > 0
    debounceSec = params.debounceWindowMs / 1000;
end

% Helper to select device or default
trigID = [];
respID = [];
if isstruct(inputDevs)
    if isfield(inputDevs,'trigger'),  trigID = inputDevs.trigger;  end
    if isfield(inputDevs,'response'), respID = inputDevs.response; end
end

% Flush both queues
try
    if isempty(trigID), KbQueueFlush(); else, KbQueueFlush(trigID); end
catch, end
try
    if isempty(respID), KbQueueFlush(); else, KbQueueFlush(respID); end
catch, end

% Normalize key names if needed
try, KbName('UnifyKeyNames'); catch, end

% Codes for comparisons (decimal)
if isfield(params, 'respKeysCode') && ~isempty(params.respKeysCode)
    respCodes = params.respKeysCode;
elseif isfield(params, 'buttonDecimalCodes') && ~isempty(params.buttonDecimalCodes)
    respCodes = params.buttonDecimalCodes;
else
    respCodes = [];
end
trgCode = params.triggerKeyCode; if isempty(trgCode) || isnan(trgCode), trgCode = 0; end
escCode = params.escapeKeyCode;  if isempty(escCode) || isnan(escCode), escCode = 27; end

% Attempt to use event buffer API if available for robust capture
useEvtBuf = (exist('KbQueueGetEvent','file') == 3) || (exist('KbQueueGetEvent','file') == 2);

sameDevice = (isempty(trigID) && isempty(respID)) || (~isempty(trigID) && ~isempty(respID) && trigID == respID);

while conditionFunc(true)
    % Read events either via event buffer (preferred) or KbQueueCheck fallback
    trPressed = false; rsPressed = false; trFirstPress = zeros(1,256); rsFirstPress = zeros(1,256);
    if useEvtBuf
        if sameDevice
            % Drain once and mirror to both masks
            dev = respID; if isempty(dev), dev = trigID; end
            evts = localDrainEvents(dev);
            if ~isempty(evts)
                trPressed = true; rsPressed = true;
                for ii=1:numel(evts)
                    kc = evts(ii).Keycode;
                    if evts(ii).Pressed && kc >= 1 && kc <= numel(trFirstPress)
                        t = evts(ii).Time;
                        trFirstPress(kc) = t;
                        rsFirstPress(kc) = t;
                    end
                end
            end
        else
            % Drain both devices independently
            trEvts = localDrainEvents(trigID);
            rsEvts = localDrainEvents(respID);
            if ~isempty(trEvts)
                trPressed = true;
                for ii=1:numel(trEvts)
                    kc = trEvts(ii).Keycode;
                    if trEvts(ii).Pressed && kc >= 1 && kc <= numel(trFirstPress)
                        trFirstPress(kc) = trEvts(ii).Time;
                    end
                end
            end
            if ~isempty(rsEvts)
                rsPressed = true;
                for ii=1:numel(rsEvts)
                    kc = rsEvts(ii).Keycode;
                    if rsEvts(ii).Pressed && kc >= 1 && kc <= numel(rsFirstPress)
                        rsFirstPress(kc) = rsEvts(ii).Time;
                    end
                end
            end
        end
    else
        if sameDevice
            % Poll once
            try
                if isempty(respID)
                    [pressed, firstPress] = KbQueueCheck();
                else
                    [pressed, firstPress] = KbQueueCheck(respID);
                end
            catch
                pressed = false; firstPress = zeros(1,256);
            end
            trPressed = pressed; rsPressed = pressed;
            trFirstPress = firstPress; rsFirstPress = firstPress;
        else
            try
                if isempty(trigID)
                    [trPressed, trFirstPress] = KbQueueCheck();
                else
                    [trPressed, trFirstPress] = KbQueueCheck(trigID);
                end
            catch
                trPressed = false; trFirstPress = zeros(1,256);
            end
            try
                if isempty(respID)
                    [rsPressed, rsFirstPress] = KbQueueCheck();
                else
                    [rsPressed, rsFirstPress] = KbQueueCheck(respID);
                end
            catch
                rsPressed = false; rsFirstPress = zeros(1,256);
            end
        end
    end

    % Collect events and log both if simultaneous
    breakRequested = false;

    % Trigger
    if trgCode >= 1 && trPressed && numel(trFirstPress) >= trgCode && trFirstPress(trgCode)
        nowt = GetSecs;
        suppress = false;
        if debounceSec > 0 && isfield(in,'lastTrigLog')
            suppress = shouldSuppress(in.lastTrigLog, trgCode, nowt, debounceSec);
        end
        if ~suppress
            logEvent(logFile, 'PULSE', 'Trigger', dateTimeStr, '-', nowt-in.scriptStart, '-', trgCode);
            in.lastTrigLog = struct('code', trgCode, 'time', nowt);
        end
        if triggerKeyBreaks
            breakRequested = true; % record, but keep logging other events from this iteration
        end
    end

    % Escape (check both devices)
    if escCode >= 1 && ((trPressed && numel(trFirstPress) >= escCode && trFirstPress(escCode)) || ...
                        (rsPressed && numel(rsFirstPress) >= escCode && rsFirstPress(escCode)))
        logEvent(logFile, 'RESP', 'Escape', dateTimeStr, '-', GetSecs-in.scriptStart, '-', escCode);
        in.pressedAbortKey = true;
        error('ScriptExecution:ManuallyAborted', 'Script execution manually aborted.');
    end

    % Response keys (from response device preferred): log all newly pressed
    if rsPressed
        rsCodes = find(rsFirstPress);
        hit = intersect(rsCodes, respCodes);
        for k = 1:numel(hit)
            hitCode = hit(k);
            nowt = GetSecs;
            suppress = false;
            if debounceSec > 0 && isfield(in,'lastRespLog')
                suppress = shouldSuppress(in.lastRespLog, hitCode, nowt, debounceSec);
            end
            if ~suppress
                logEvent(logFile, 'RESP', 'KeyPress', dateTimeStr, '-', nowt-in.scriptStart, '-', hitCode);
                in.lastRespLog = struct('code', hitCode, 'time', nowt);
            end
            if isempty(firstPressedKey)
                firstPressedKey = hitCode;
            end
        end
        if ~isempty(hit) && otherKeysBreak
            breakRequested = true;
        end
    end

    % Also log any other key presses (not necessarily response keys) on response device
    if rsPressed
        other = setdiff(find(rsFirstPress), unique([respCodes, trgCode, escCode]));
        for k = 1:numel(other)
            anyCode = other(k);
            nowt = GetSecs;
            suppress = false;
            if debounceSec > 0 && isfield(in,'lastRespLog')
                suppress = shouldSuppress(in.lastRespLog, anyCode, nowt, debounceSec);
            end
            if ~suppress
                logEvent(logFile, 'RESP', 'KeyPress', dateTimeStr, '-', nowt-in.scriptStart, '-', anyCode);
                in.lastRespLog = struct('code', anyCode, 'time', nowt);
            end
            if anyCode == 111
                in.toggleOverlay = true;
            end
        end
        if ~isempty(other) && otherKeysBreak
            breakRequested = true;
        end
    end

    % Log any non-trigger, non-escape keys on trigger device as RESP KeyPress
    if trPressed && ~sameDevice
        trAll = find(trFirstPress);
        trOther = setdiff(trAll, unique([trgCode, escCode]));
        for k = 1:numel(trOther)
            code = trOther(k);
            nowt = GetSecs;
            suppress = false;
            if debounceSec > 0 && isfield(in,'lastTrigLog')
                suppress = shouldSuppress(in.lastTrigLog, code, nowt, debounceSec);
            end
            if ~suppress
                logEvent(logFile, 'RESP', 'KeyPress', dateTimeStr, '-', nowt-in.scriptStart, '-', code);
                in.lastTrigLog = struct('code', code, 'time', nowt);
            end
        end
    end

    % Flush queues after logging to avoid re-logging the same firstPress
    if ~useEvtBuf
        % Only flush if using KbQueueCheck fallback
        try, if isempty(trigID), KbQueueFlush(); else, KbQueueFlush(trigID); end; catch, end
        try, if isempty(respID), KbQueueFlush(); else, KbQueueFlush(respID); end; catch, end
    end

    if breakRequested
        break
    end

    % Yield briefly to reduce potential UI stalls
    WaitSecs(0.0005);
end

% Local function: Drain all pending events from the KbQueue event buffer.
function evts = localDrainEvents(dev)
    evts = struct('Keycode', {}, 'Pressed', {}, 'Time', {});
    try
        if isempty(dev)
            while true
                [evt, n] = KbQueueGetEvent(); %#ok<NASGU>
                if isempty(evt); break; end
                if isfield(evt,'Pressed') && evt.Pressed
                    evts(end+1) = struct('Keycode', evt.Keycode, 'Pressed', evt.Pressed, 'Time', evt.Time); %#ok<AGROW>
                end
            end
        else
            while true
                [evt, n] = KbQueueGetEvent(dev); %#ok<NASGU>
                if isempty(evt); break; end
                if isfield(evt,'Pressed') && evt.Pressed
                    evts(end+1) = struct('Keycode', evt.Keycode, 'Pressed', evt.Pressed, 'Time', evt.Time); %#ok<AGROW>
                end
            end
        end
    catch
        evts = [];
    end
end

end
