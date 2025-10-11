function validateInstructionPlaceholders(params)
%VALIDATEINSTRUCTIONPLACEHOLDERS Ensure exactly two '()' placeholders exist.

% Collect instruction text fields
paramFieldnames = fieldnames(params);
texts = {};
for i = 1:numel(paramFieldnames)
    fn = paramFieldnames{i};
    if contains(fn, 'instructionsText')
        texts{end+1} = params.(fn); %#ok<AGROW>
    end
end
paragraph = '';
for i = 1:numel(texts)
    paragraph = [paragraph texts{i} '\n\n']; %#ok<AGROW>
end

idx = strfind(paragraph, '()');
if numel(idx) ~= 2
    error('Instructions:PlaceholderCount', ['Instructions must contain exactly two placeholders ''()'' ', ...
        'to label the left/right responses. Edit your instructionsText* fields in src/config.m.']);
end

end
