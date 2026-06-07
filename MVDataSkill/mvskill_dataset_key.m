function key = mvskill_dataset_key(datasetName)
%MVSKILL_DATASET_KEY Convert a dataset name to a valid struct field key.

if isempty(datasetName)
    key = 'dataset';
    return;
end

if iscell(datasetName)
    datasetName = datasetName{1};
end

[~, nameOnly, ~] = fileparts(char(datasetName));
key = lower(strtrim(nameOnly));
key = regexprep(key, '[^a-zA-Z0-9_]', '_');
key = regexprep(key, '_+', '_');
key = regexprep(key, '^_+|_+$', '');

if isempty(key)
    key = 'dataset';
end

if isempty(regexp(key(1), '[a-zA-Z]', 'once'))
    key = ['d_', key];
end
end
