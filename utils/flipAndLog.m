function [VBLTimestamp] = flipAndLog(win, logFile, in, eventName, expectedOnset, eventID)
%FLIPANDLOG Flip the screen and log a standard event row.
%   [VBL] = flipAndLog(win, logFile, in, eventName, expectedOnset, eventID)
%   expectedOnset can be numeric or '-' for none; eventID may be '-' or a value.

% Perform the buffer swap and get the VBL timestamp for this flip. We keep
% timing measured relative to the script start (in.scriptStart) for logging.
[VBLTimestamp, ~, ~, ~] = Screen('Flip', win);

% Compute actual relative to script start
actual = VBLTimestamp - in.scriptStart;

% Prepare fields. When expectedOnset is numeric, we also compute and log the
% delta; otherwise write '-' for optional fields to preserve the TSV shape.
if ischar(expectedOnset) || isstring(expectedOnset)
    expField = expectedOnset;
    deltField = '-';
else
    expField = expectedOnset;
    deltField = actual - expectedOnset;
end

% Log the event (preserve header and names). This function never changes
% the logging header order, keeping compatibility with downstream tools.
logEvent(logFile, 'FLIP', eventName, dateTimeStr, expField, actual, deltField, eventID);

end
