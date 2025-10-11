function pretty_console(on)
%PRETTY_CONSOLE Toggle pretty console rendering of log lines.
%  PRETTY_CONSOLE(true)  - enable
%  PRETTY_CONSOLE(false) - disable
%  PRETTY_CONSOLE        - toggle current state

  if nargin < 1
      on = ~getappdata(0, 'LOG_PRETTY_CONSOLE');
  end
  setappdata(0, 'LOG_PRETTY_CONSOLE', logical(on));
  fprintf('Pretty console: %s\n', string(logical(on)));
end

