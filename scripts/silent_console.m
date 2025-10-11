function silent_console(on)
%SILENT_CONSOLE Toggle silencing of TSV console logging.
%  SILENT_CONSOLE(true)  - suppress TSV lines in console (file unaffected)
%  SILENT_CONSOLE(false) - restore default console logging
%  SILENT_CONSOLE        - toggle current state

  if nargin < 1
      on = ~getappdata(0, 'LOG_SILENT_CONSOLE');
  end
  setappdata(0, 'LOG_SILENT_CONSOLE', logical(on));
  fprintf('Silent console: %s\n', string(logical(on)));
end

