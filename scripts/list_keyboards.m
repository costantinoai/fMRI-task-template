function list_keyboards()
%LIST_KEYBOARDS Print candidate keyboard device indices for KbQueue.
%   Uses PTB's GetKeyboardIndices helper to list allowed device indices.

try
    idx = GetKeyboardIndices();
catch ME
    error('PTB:GetKeyboardIndicesFailed', 'GetKeyboardIndices failed: %s', ME.message);
end

if isempty(idx)
    fprintf('No keyboard candidate devices found by GetKeyboardIndices().\n');
else
    fprintf('Keyboard candidate indices: [%s]\n', num2str(idx));
end

fprintf('Use these indices in src/config.m under deviceIDs.trigger/response.\n');

end
