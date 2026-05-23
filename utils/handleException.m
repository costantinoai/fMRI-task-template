function handleException(logFile, exception)
% HANDLEEXCEPTION Log a caught exception, distinguishing a clean manual abort
% from a genuine error.
%
%   The experimenter pressing the escape key makes logKeyPress raise an
%   exception with identifier 'ScriptExecution:ManuallyAborted'. That is an
%   expected, clean termination, so it is logged as a single 'ABORT' event with
%   no stack trace. Any other exception keeps the original behaviour: an 'ERROR'
%   event plus the full stack trace written to the log and the command window.
%
%   Input arguments:
%   - logFile:   file identifier of the log file (1 = command window only).
%   - exception: the MException caught by the main try/catch.
%
%   Author
%   Andrea Costantino

if strcmp(exception.identifier, 'ScriptExecution:ManuallyAborted')
    % Clean, expected termination - do not treat it as an error
    logEvent(logFile, 'ABORT', 'Escape', dateTimeStr, '-', '-', '-', '-');
    fprintf(1, 'Run manually aborted by the experimenter (escape key).\n');
else
    % Genuine error - log it together with the full stack trace
    stackTrace = getReport(exception, 'extended', 'hyperlinks', 'off');
    logEvent(logFile, 'ERROR', 'Err', dateTimeStr, '-', '-', '-', '-');
    fprintf(logFile, 'Detailed error message:\n%s\n', stackTrace);
    disp(['Error: ' stackTrace]);
end

end
