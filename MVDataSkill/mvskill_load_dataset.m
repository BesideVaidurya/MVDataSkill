function data = mvskill_load_dataset(dataFile, cfg)
%MVSKILL_LOAD_DATASET Load X/data and labels from a multi-view .mat file.

if nargin < 2
    cfg = mvskill_default_config();
end

if ~exist(dataFile, 'file')
    error('Dataset file does not exist: %s', dataFile);
end

S = load(dataFile);
[~, datasetName, ~] = fileparts(dataFile);

featureFields = {'X', 'data', 'fea', 'features'};
tempX = [];
foundFeature = false;
if isfield(cfg, 'featureField') && ~isempty(cfg.featureField)
    if isfield(S, cfg.featureField)
        tempX = S.(cfg.featureField);
        foundFeature = true;
    else
        error('Configured featureField "%s" was not found in %s.', cfg.featureField, dataFile);
    end
else
    for i = 1:numel(featureFields)
        if isfield(S, featureFields{i})
            tempX = S.(featureFields{i});
            foundFeature = true;
            break;
        end
    end
end
if ~foundFeature
    error('The X/data/fea/features variable was not found in %s.', dataFile);
end

if ~iscell(tempX)
    if isnumeric(tempX) || islogical(tempX)
        tempX = {tempX};
    else
        error('X/data in %s should be a cell array or numeric matrix, but it is %s.', ...
            dataFile, class(tempX));
    end
end

labelFields = {'Y', 'y', 'gt', 'gnd', 'truelabel', 'label', 'labels', 'truth'};
gt = [];
foundLabel = false;
if isfield(cfg, 'labelField') && ~isempty(cfg.labelField)
    if isfield(S, cfg.labelField)
        gt = S.(cfg.labelField);
        foundLabel = true;
    else
        error('Configured labelField "%s" was not found in %s.', cfg.labelField, dataFile);
    end
else
    for i = 1:numel(labelFields)
        if isfield(S, labelFields{i})
            gt = S.(labelFields{i});
            foundLabel = true;
            break;
        end
    end
end
if ~foundLabel
    error('The label variable was not found in %s.', dataFile);
end

if iscell(gt)
    gt = gt{1};
end
gt = double(gt(:));

data = struct();
data.name = datasetName;
data.file = dataFile;
data.raw = S;
data.rawX = tempX;
data.gt = gt;
data.classNum = length(unique(gt));
end
