function logEvent(logFile, eventType, eventName, dateTime, expOnset, actualOnset, delta, eventID)
% LOGEVENT Logs an event to the command window and/or to a file.
%
%   This function logs an event to a specified log file and/or the command window.
%   The event is represented by various parameters such as event type, name,
%   date/time (as produced by dateTimeStr), expected and actual onsets and an
%   arbitrary event id.
%
%   Input arguments:
%       - logFile: The file identifier of the log file. Specify 1 to log to the command window only.
%       - eventType: The type of the event (e.g., 'Error', 'Warning', 'Info').
%       - eventName: The name or description of the event.
%       - dateTime: The date/time tag. Use dateTimeStr() output (e.g., 'yyyy-MM-dd-HH-mm').
%       - expOnset: The expected onset time of the event.
%       - actualOnset: The actual onset time of the event.
%       - delta: The difference between the expected and actual onset times.
%       - eventID: An identifier or code for the event.
%
%   Output:
%       None. The function logs the event message to the specified file and/or the command window.
%
%   Example:
%       logEvent(fid, 'FLIP', 'Stim', dateTimeStr, 12.5, 12.54, 0.04, 'myStim');
%
%   Note:
%       - If logFile is 1, the event is logged only to the command window.
%       - The date/time string can be any string; for consistency use dateTimeStr().
%       - The utility function formatVariable ensures the input fields can
%           be given in any format and still get logged properly.
% 
%   Author
%   Tim Maniquet [27/3/24]

% Helper function to determine the correct format for each input
function format = formatVariable(var)
    if ischar(var) || isstring(var)
        format = '%s';
    elseif isnumeric(var)
        format = '%f';
    else
        error('Unsupported variable type: %s', class(var));
    end
end

% Dynamically generate the format specifier (invariant TSV formatting)
formatSpec = sprintf('%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
                     formatVariable(eventType), ...
                     formatVariable(eventName), ...
                     formatVariable(dateTime), ...
                     formatVariable(expOnset), ...
                     formatVariable(actualOnset), ...
                     formatVariable(delta), ...
                     formatVariable(eventID));

% Create the log message line from the input using the specified format
logMessage = sprintf(formatSpec, ...
                    string(eventType), string(eventName), string(dateTime), ...
                    expOnset, actualOnset, delta, ...
                    string(eventID));

% If the log file is not the command window
if ~(logFile == 1)
    % Log in the external log file
    fprintf(logFile, logMessage);
end

% In both cases, log in the command window (invariant TSV) unless silenced
try
    silent = getappdata(0, 'LOG_SILENT_CONSOLE');
catch
    silent = false;
end
if ~silent
    fprintf(1, logMessage);
end

% Optional: Pretty console line for readability without changing files
try
    if getappdata(0, 'LOG_PRETTY_CONSOLE')
        % Skip pretty output for the TSV header row; print header on first real row
        isHdr = false;
        try
            isHdr = strcmp(char(string(eventType)), 'EVENT_TYPE');
        catch
        end
        if ~isHdr
            if isempty(getappdata(0,'LOG_PRETTY_HEADER_PRINTED')) || ~getappdata(0,'LOG_PRETTY_HEADER_PRINTED')
                [header, sep] = local_pretty_header();
                fprintf(1, '%s\n%s\n', header, sep);
                setappdata(0,'LOG_PRETTY_HEADER_PRINTED', true);
            end
            prettyLine = local_pretty_line(eventType, eventName, dateTime, expOnset, actualOnset, delta, eventID);
            fprintf(1, '%s\n', prettyLine);
        end
    end
catch
    % ignore if appdata missing
end

end

function [header, sep] = local_pretty_header()
%LOCAL_PRETTY_HEADER Build header line and separator with aligned columns.
    w = local_widths();
    header = sprintf('%-*s | %-*s | %-*s | %*s | %*s | %*s | %*s', ...
        w.type, 'TYPE', w.name, 'NAME', w.time, 'DATETIME', w.exp, 'EXP', w.act, 'ACT', w.delta, 'DELTA', w.id, 'ID');
    sep = repmat('-', 1, strlength(header));
end

function line = local_pretty_line(eventType, eventName, dateTime, expOnset, actualOnset, delta, eventID)
%LOCAL_PRETTY_LINE Build a simple aligned line; codes as integers; separators between columns.
    w = local_widths();
    et = string(eventType); en = string(eventName); dt = string(dateTime);
    expStr = local_fmt(expOnset, 6);
    actStr = local_fmt(actualOnset, 6);

    % Format delta as milliseconds for readability
    delStr = local_fmt_delta_ms(delta);

    idStr = '-';
    if isnumeric(eventID)
        idStr = sprintf('%d', round(eventID));
    elseif isstring(eventID) || ischar(eventID)
        x = str2double(string(eventID));
        if ~isnan(x)
            idStr = sprintf('%d', round(x));
        else
            idStr = char(eventID);
        end
    end
    line = sprintf('%-*s | %-*s | %-*s | %*s | %*s | %*s | %*s', ...
        w.type, et, w.name, en, w.time, dt, w.exp, expStr, w.act, actStr, w.delta, delStr, w.id, idStr);
end

function s = local_fmt(x, nd)
    if ischar(x)
        if strcmp(x,'-'), s = '-'; return; end
        x = str2double(x);
    end
    if isempty(x) || (isnumeric(x) && isnan(x))
        s = '-';
    else
        s = sprintf('%.*f', nd, x);
    end
end

function s = local_fmt_delta_ms(x)
%LOCAL_FMT_DELTA_MS Format delta as milliseconds (convert from seconds).
    if ischar(x)
        if strcmp(x,'-'), s = '-'; return; end
        x = str2double(x);
    end
    if isempty(x) || (isnumeric(x) && isnan(x))
        s = '-';
    else
        % Convert seconds to milliseconds and format with 2 decimal places
        s = sprintf('%.2f ms', x * 1000);
    end
end

function w = local_widths()
%LOCAL_WIDTHS Centralize widths to keep header/rows aligned.
    w = struct('type', 6, 'name', 9, 'time', 16, 'exp', 10, 'act', 11, 'delta', 9, 'id', 7);
end
