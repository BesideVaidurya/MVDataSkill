function datasetParams = mvskill_set_dataset_params(datasetParams, datasetName, params)
%MVSKILL_SET_DATASET_PARAMS Set params for one dataset using a safe key.

if nargin < 1 || isempty(datasetParams)
    datasetParams = struct();
end
if nargin < 3 || isempty(params)
    params = struct();
end

key = mvskill_dataset_key(datasetName);
datasetParams.(key) = params;
end
