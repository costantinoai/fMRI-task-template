function yes = shouldSuppress(lastLog, code, nowt, debounceSec)
%SHOULDSUPPRESS Return true if a repeated key should be suppressed by debounce.
%   lastLog: struct with fields 'code' and 'time' or empty
%   code: current key code (decimal)
%   nowt: current GetSecs timestamp (seconds)
%   debounceSec: window in seconds; if 0, never suppress

if debounceSec <= 0 || isempty(lastLog)
    yes = false;
    return
end

if lastLog.code == code && (nowt - lastLog.time) <= debounceSec
    yes = true;
else
    yes = false;
end

end

