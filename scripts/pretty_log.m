function pretty_log(logPath, varargin)
%PRETTY_LOG Render a log TSV with nicer formatting without changing outputs.
%  PRETTY_LOG(logPath)
%  PRETTY_LOG(logPath, 'Width', 120)
%
%  Reads a standard task log (tab-separated) and prints a clean, aligned
%  view to the Command Window, formatting codes as integers and aligning
%  numeric columns. The original log files are not modified.
%
%  Options:
%    'Width'  - total print width (default 120)
%    'Out'    - optional output text file path to save the pretty view
%
%  Example:
%    pretty_log('data/sub-01/2025-01-01-12-00_sub-01_run-01_task-exp_log.tsv')

  p = inputParser;
  addParameter(p, 'Width', 120, @(x) isnumeric(x) && isscalar(x));
  addParameter(p, 'Out', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
  parse(p, varargin{:});
  width = p.Results.Width;
  outFile = char(p.Results.Out);

  if nargin < 1 || isempty(logPath)
      error('Input:Missing', 'Provide a path to a log .tsv file.');
  end
  if exist(logPath,'file') ~= 2
      error('File:NotFound','Log file not found: %s', logPath);
  end

  % Read as text to preserve columns exactly
  opts = detectImportOptions(logPath, 'FileType','text', 'Delimiter','\t');
  try, opts.VariableNamingRule = 'preserve'; catch, end
  T = readtable(logPath, opts);

  % Expected headers
  headers = {'EVENT_TYPE','EVENT_NAME','DATETIME','EXP_ONSET','ACTUAL_ONSET','DELTA','EVENT_ID'};
  for i=1:numel(headers)
      if ~ismember(headers{i}, T.Properties.VariableNames)
          error('Log:InvalidFormat','Missing column %s in log.', headers{i});
      end
  end

  % Build formatted lines
  lines = strings(0,1);
  % Column widths (heuristic)
  w = struct('type', 6, 'name', 9, 'time', 16, 'exp', 10, 'act', 11, 'delta', 9, 'id', 7);
  % Header
  headerLine = sprintf('%-*s  %-*s  %-*s  %*s  %*s  %*s  %*s', ...
      w.type, 'TYPE', w.name, 'NAME', w.time, 'DATETIME', ...
      w.exp, 'EXP', w.act, 'ACT', w.delta, 'DELTA', w.id, 'ID');
  sep = repmat('-', 1, min(width, strlength(headerLine)));
  lines(end+1) = headerLine; %#ok<AGROW>
  lines(end+1) = string(sep); %#ok<AGROW>

  % Rows
  for i=1:height(T)
      et  = string(T.EVENT_TYPE{i});
      en  = string(T.EVENT_NAME{i});
      dt  = string(T.DATETIME{i});
      exp = T.EXP_ONSET(i); if ismissing(exp) || (ischar(exp) && strcmp(exp,'-')), exp = NaN; end
      act = T.ACTUAL_ONSET(i); if ismissing(act) || (ischar(act) && strcmp(act,'-')), act = NaN; end
      del = T.DELTA(i); if ismissing(del) || (ischar(del) && strcmp(del,'-')), del = NaN; end
      idv = T.EVENT_ID(i);

      % Sanitize numeric conversions
      expStr = fmtNum(exp, 6);
      actStr = fmtNum(act, 6);
      delStr = fmtNum(del, 6);

      % Event id as integer if numeric-like
      idStr = '-';
      try
          if isnumeric(idv)
              idStr = sprintf('%d', round(idv));
          elseif iscell(idv) && ~isempty(idv)
              idStr = string(idv{1});
          elseif isstring(idv) || ischar(idv)
              % if looks like a number
              n = str2double(string(idv));
              if ~isnan(n), idStr = sprintf('%d', round(n)); else, idStr = char(idv); end
          end
      catch
          idStr = '-';
      end

      line = sprintf('%-*s  %-*s  %-*s  %*s  %*s  %*s  %*s', ...
          w.type, et, w.name, en, w.time, dt, ...
          w.exp, expStr, w.act, actStr, w.delta, delStr, w.id, idStr);
      if strlength(line) > width
          line = extractBefore(line, width);
      end
      lines(end+1) = line; %#ok<AGROW>
  end

  out = strjoin(lines, newline) + newline;

  if ~isempty(outFile)
      fid = fopen(outFile, 'w');
      assert(fid>0, 'File:OpenFailed','Cannot open %s for writing', outFile);
      c = onCleanup(@() fclose(fid)); %#ok<NASGU>
      fwrite(fid, out);
      fprintf('Wrote pretty log to %s\n', outFile);
  else
      fprintf('%s', out);
  end
end

function s = fmtNum(x, nd)
  if ischar(x)
      if strcmp(x,'-'), s = '-'; return; end
      x = str2double(x);
  end
  if isempty(x) || isnan(x)
      s = '-';
  else
      s = sprintf('%.*f', nd, x);
  end
end

