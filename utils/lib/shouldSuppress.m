function yes = shouldSuppress(lastLog, code, nowt, debounceSec)
%SHOULDSUPPRESS Return true if a repeated key should be suppressed by debounce.
%   lastLog: struct with fields 'code' and 'time' or empty
%   code: current key code (decimal)
%   nowt: current GetSecs timestamp (seconds)
%   debounceSec: window in seconds; if 0, never suppress
%
%   Uses small epsilon (1e-9s ~= 1ns) to handle floating point precision
%   at boundary conditions.

if debounceSec <= 0 || isempty(lastLog)
    yes = false;
    return
end

% Add small epsilon to handle floating point precision at boundaries
epsilon = 1e-9;  % ~1 nanosecond tolerance
delta = nowt - lastLog.time;

if lastLog.code == code && delta <= (debounceSec + epsilon)
    yes = true;
else
    yes = false;
end

end

