function initializePTB()
% INITIALIZEPTB Initializes the experiment environment (platform-agnostic).
% - Closes open PTB screens
% - Unifies key names
% - RNG seeding is handled in the main script (debug/seeded mode)
% Note: Keyboard queues are created via createInputQueues instead.

try
    Screen('CloseAll');
    KbName('UnifyKeyNames');
    disp('Experiment environment initialized.');
catch ME
    disp('An error occurred while initializing PTB:');
    disp(ME.message);
end

end
