function port_config_jsonc(jsoncPath, outPath)
%PORT_CONFIG_JSONC Convert a JSON/JSONC config into src/config.m
%  PORT_CONFIG_JSONC(jsoncPath, outPath)
%  - jsoncPath: path to a JSON or JSONC file with fields matching the
%    previous template configuration.
%  - outPath: destination MATLAB config file (default 'src/config.m').
%
%  The function parses the JSONC, maps fields into a MATLAB struct, and
%  writes a config.m file that returns the struct. Existing file is
%  overwritten. Comments are not preserved.

  if nargin < 1 || isempty(jsoncPath)
      error('Input:Missing', 'Provide a path to a JSON/JSONC config file.');
  end
  if nargin < 2 || isempty(outPath)
      outPath = fullfile('src','config.m');
  end
  if exist(jsoncPath,'file')~=2
      error('File:NotFound','JSON/JSONC file not found: %s', jsoncPath);
  end

  raw = fileread(jsoncPath);
  cfg = jsondecode(local_jsonc_clean(raw));

  % Build MATLAB config struct (we preserve fields as-is where possible)
  m = struct();

  % Timing
  m.stimDur = getf(cfg,'stimDur',1);
  m.fixDur  = getf(cfg,'fixDur',1);
  m.prePost = getf(cfg,'prePost',10);

  % Task
  m.taskName = getf(cfg,'taskName','myexp');

  % Resize
  m.resize     = logical(getf(cfg,'resize',true));
  m.resizeMode = getf(cfg,'resizeMode','visualUnits');
  m.outWidth   = getf(cfg,'outWidth',8);
  m.outHeight  = getf(cfg,'outHeight',8);

  % Runs & stimuli
  m.numRuns        = getf(cfg,'numRuns',2);
  m.stimListFile   = getf(cfg,'stimListFile','src/list_of_stimuli.tsv');
  m.numRepetitions = getf(cfg,'numRepetitions',2);
  if isfield(cfg,'stimRandomization'), m.stimRandomization = cfg.stimRandomization; end
  m.preloadImages  = logical(getf(cfg,'preloadImages',true));

  % Fixation & text
  m.fixSize = getf(cfg,'fixSize',.6);
  m.fixType = getf(cfg,'fixType','round');
  m.textSize = getf(cfg,'textSize',30);
  m.textFont = getf(cfg,'textFont','Helvetica');

  % Instructions
  if isfield(cfg,'instructionsText1'), m.instructionsText1 = cfg.instructionsText1; end
  if isfield(cfg,'instructionsText2'), m.instructionsText2 = cfg.instructionsText2; end
  if isfield(cfg,'instructionsText3'), m.instructionsText3 = cfg.instructionsText3; end
  m.triggerWaitText = getf(cfg,'triggerWaitText','Experiment loading... waiting for trigger');

  % Screen geometry
  m.scrDistMRI  = getf(cfg,'scrDistMRI',630);
  m.scrWidthMRI = getf(cfg,'scrWidthMRI',340);
  if isfield(cfg,'scrHeightMRI'), m.scrHeightMRI = cfg.scrHeightMRI; end
  m.scrDistPC   = getf(cfg,'scrDistPC',520);
  m.scrWidthPC  = getf(cfg,'scrWidthPC',510);
  if isfield(cfg,'scrHeightPC'), m.scrHeightPC = cfg.scrHeightPC; end
  m.useScreenGeometry = logical(getf(cfg,'useScreenGeometry',false));

  % Response labels
  m.respInst1 = getf(cfg,'respInst1','left/green');
  m.respInst2 = getf(cfg,'respInst2','right/red');

  % Keys/buttons (decimals)
  if isfield(cfg,'buttonsPC'),   m.buttonsPC = row10(cfg.buttonsPC); end
  if isfield(cfg,'buttonsFMRI'), m.buttonsFMRI = row10(cfg.buttonsFMRI); end
  if isfield(cfg,'buttons'),     m.buttons = row10(cfg.buttons); end
  if isfield(cfg,'escapeKeyPCCode'),   m.escapeKeyPCCode = cfg.escapeKeyPCCode; end
  if isfield(cfg,'escapeKeyMRICode'),  m.escapeKeyMRICode = cfg.escapeKeyMRICode; end
  if isfield(cfg,'escapeKeyCode'),     m.escapeKeyCode = cfg.escapeKeyCode; end
  if isfield(cfg,'triggerKeyPCCode'),  m.triggerKeyPCCode = cfg.triggerKeyPCCode; end
  if isfield(cfg,'triggerKeyMRICode'), m.triggerKeyMRICode = cfg.triggerKeyMRICode; end
  if isfield(cfg,'triggerKeyCode'),    m.triggerKeyCode = cfg.triggerKeyCode; end
  if isfield(cfg,'keyMap'),            m.keyMap = cfg.keyMap; end
  if isfield(cfg,'buttonDecimalCodes'), m.buttonDecimalCodes = row10(cfg.buttonDecimalCodes); end
  if isfield(cfg,'colorDecimalCodes'),  m.colorDecimalCodes = cfg.colorDecimalCodes; end

  % Devices
  if isfield(cfg,'deviceIDs'), m.deviceIDs = cfg.deviceIDs; end

  % Trigger/debounce
  m.triggerPolicy   = getf(cfg,'triggerPolicy','double');
  m.triggerWindowMs = getf(cfg,'triggerWindowMs',100);
  m.debounceWindowMs = getf(cfg,'debounceWindowMs',0);

  % Debug
  if isfield(cfg,'debug'), m.debug = cfg.debug; end

  % Write out MATLAB file
  write_config_m(m, outPath);
  fprintf('Wrote %s\n', outPath);

end

function v = getf(s, name, def)
  if isfield(s, name), v = s.(name); else, v = def; end
end

function arr = row10(v)
  v = v(:)';
  if numel(v) < 10, v = [v nan(1,10-numel(v))]; end %#ok<AGROW>
  arr = v(1:min(10,numel(v)));
end

function write_config_m(m, outPath)
  [d,~,~] = fileparts(outPath);
  if ~isempty(d) && exist(d,'dir')~=7, mkdir(d); end
  fid = fopen(outPath,'w');
  assert(fid>0, 'File:OpenFailed','Cannot open %s for writing', outPath);
  c = onCleanup(@() fclose(fid));
  fprintf(fid, 'function cfg = config()\n');
  fprintf(fid, '%% Auto-generated from JSONC by port_config_jsonc on %s\n\n', datestr(now));
  fn = fieldnames(m);
  for i=1:numel(fn)
      key = fn{i}; val = m.(key);
      fprintf(fid, 'cfg.%s = %s;\n', key, lit(val));
  end
  fprintf(fid, '\nend\n');
end

function s = lit(v)
  if ischar(v)
      s = sprintf('''%s''', escape_str(v));
  elseif isstring(v) && isscalar(v)
      s = sprintf('''%s''', escape_str(char(v)));
  elseif isnumeric(v)
      if isscalar(v)
          if isnan(v), s='NaN'; else, s=num2str(v); end
      else
          s = mat2str(v);
      end
  elseif islogical(v)
      s = mat2str(v);
  elseif isstruct(v)
      % struct to MATLAB literal via struct constructor
      f = fieldnames(v);
      parts = cell(1,numel(f)*2);
      for i=1:numel(f)
          parts{2*i-1} = sprintf('''%s''', escape_str(f{i}));
          parts{2*i}   = lit(v.(f{i}));
      end
      s = sprintf('struct(%s)', strjoin(parts, ', '));
  elseif iscell(v)
      % cells as MATLAB literal; try to render simply
      items = cellfun(@lit, v, 'UniformOutput', false);
      s = sprintf('{%s}', strjoin(items, ', '));
  else
      % fallback to mat2str if possible
      try
          s = mat2str(v);
      catch
          s = '[]';
      end
  end
end

function t = escape_str(s)
  t = strrep(s, '''', '''''');
end

function cleaned = local_jsonc_clean(rawText)
  % Minimal cleaner: strip comments and trailing commas
  rawText = char(rawText);
  if ~isempty(rawText) && rawText(1) == char(65279)
      rawText = rawText(2:end);
  end
  s = rawText; n = numel(s); out = s;
  IN_STR=1; IN_BLK=2; IN_LINE=3; IN_NONE=0; state=IN_NONE; i=1; esc=false;
  while i<=n
      ch=s(i); nxt=char(0); if i<n, nxt=s(i+1); end
      switch state
          case IN_NONE
              if ch=='"', state=IN_STR; esc=false; i=i+1; continue;
              elseif ch=='/' && nxt=='*', state=IN_BLK; out(i:i+1)='  '; i=i+2; continue;
              elseif ch=='/' && nxt=='/', state=IN_LINE; out(i:i+1)='  '; i=i+2; continue;
              else, i=i+1; continue; end
          case IN_STR
              if ~esc && ch=='\', esc=true; i=i+1; continue; end
              if esc, esc=false; i=i+1; continue; end
              if ch=='"', state=IN_NONE; i=i+1; continue; end
              i=i+1; continue;
          case IN_BLK
              if ch==newline, out(i)=newline; else, out(i)=' '; end
              if ch=='*' && nxt=='/', out(i:i+1)='  '; state=IN_NONE; i=i+2; continue; else, i=i+1; continue; end
          case IN_LINE
              if ch==newline, out(i)=newline; state=IN_NONE; i=i+1; continue; else, out(i)=' '; i=i+1; continue; end
      end
  end
  % trailing commas
  s2=out; n2=numel(s2); i=1; state=IN_NONE; esc=false;
  while i<=n2
      ch=s2(i); nxt=char(0); if i<n2, nxt=s2(i+1); end
      switch state
          case IN_NONE
              if ch=='"', state=IN_STR; esc=false; i=i+1; continue;
              elseif ch==','
                  j=i+1; while j<=n2 && isspace(s2(j)), j=j+1; end
                  if j<=n2 && (s2(j)=='}' || s2(j)==']'), s2(i)=' '; end
                  i=i+1; continue;
              else, i=i+1; continue; end
          case IN_STR
              if ~esc && ch=='\', esc=true; i=i+1; continue; end
              if esc, esc=false; i=i+1; continue; end
              if ch=='"', state=IN_NONE; i=i+1; continue; end
              i=i+1; continue;
      end
  end
  cleaned = s2;
end

