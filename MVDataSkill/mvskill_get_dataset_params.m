function params = mvskill_get_dataset_params(defaultParams, datasetParams, datasetName)
%MVSKILL_GET_DATASET_PARAMS Merge default params with dataset-specific params.

if nargin < 1 || isempty(defaultParams)
    defaultParams = struct();
end
if nargin < 2 || isempty(datasetParams)
    datasetParams = struct();
end

params = defaultParams;
key = mvskill_dataset_key(datasetName);

if isfield(datasetParams, key)
    params = merge_params(params, datasetParams.(key));
    return;
end

compactKey = compact_dataset_key(key);
keys = fieldnames(datasetParams);
for i = 1:numel(keys)
    if strcmp(compact_dataset_key(keys{i}), compactKey)
        params = merge_params(params, datasetParams.(keys{i}));
        return;
    end
end
end

function params = merge_params(params, overrides)
names = fieldnames(overrides);
for i = 1:numel(names)
    params.(names{i}) = overrides.(names{i});
end
end

function key = compact_dataset_key(key)
key = lower(key);
if length(key) > 2 && strcmp(key(1:2), 'd_')
    key = key(3:end);
end
key = regexprep(key, '[^a-z0-9]', '');
end
