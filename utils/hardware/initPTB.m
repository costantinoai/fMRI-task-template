function initPTB()
% INITPTB Initialize Psychtoolbox environment.
%
%   Closes any open PTB screens and unifies key names across platforms.
%   Must be called before any other PTB operations.
%
% Errors:
%   Hardware:PTBFailed - PTB initialization failed
%
% Example:
%   initPTB();
%
% Author: fMRI Task Template Team
% Last updated: 2025

try
    Screen('CloseAll');
    KbName('UnifyKeyNames');
catch ME
    error('Hardware:PTBFailed', ['PTB initialization failed: %s. ', ...
        'Make sure Psychtoolbox is installed and on the MATLAB path.'], ME.message);
end

end
