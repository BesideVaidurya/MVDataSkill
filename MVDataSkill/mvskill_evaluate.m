function metric = mvskill_evaluate(gt, label, cfg)
%MVSKILL_EVALUATE Compute clustering metrics by cfg.metricFunction.

if nargin < 3 || isempty(cfg)
    cfg = mvskill_default_config();
end

metricFunction = 'Clustering8Measure';
if isfield(cfg, 'metricFunction') && ~isempty(cfg.metricFunction)
    metricFunction = cfg.metricFunction;
end

originalPath = path;
cleanupObj = onCleanup(@() path(originalPath)); %#ok<NASGU>

if isfield(cfg, 'metricPath') && ~isempty(cfg.metricPath) && exist(cfg.metricPath, 'dir')
    addpath(genpath(cfg.metricPath));
end

fh = str2func(metricFunction);
gt = double(gt(:));
label = double(label(:));
if numel(gt) ~= numel(label)
    error('Label length mismatch. gt = %d, label = %d.', numel(gt), numel(label));
end

if exist(metricFunction, 'file') ~= 2
    error('Metric function was not found: %s. Check cfg.metricPath.', metricFunction);
end

metric = fh(gt, label);
metric = metric(:)';
end
