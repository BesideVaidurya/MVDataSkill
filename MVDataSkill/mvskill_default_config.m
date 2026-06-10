function cfg = mvskill_default_config()
%MVSKILL_DEFAULT_CONFIG Build default config for multi-view batch runs.

skillRoot = fileparts(mfilename('fullpath'));
subRoot = fileparts(skillRoot);
workspaceRoot = fileparts(subRoot);

cfg = struct();
cfg.skillRoot = skillRoot;
cfg.algorithmName = 'Algorithm';
cfg.algorithmRoot = '';
cfg.codeFolders = {'tools', 'cal_funcs', 'funcs', 'functions', 'utils', 'ClusteringMeasure'};

cfg.dataPath = '';
cfg.dataList = {};
cfg.resultRoot = '';
% Number of clustering label outputs used for metric mean/std.
% mvskill_run_batch calls the algorithm runner once; the runner should
% return one label vector or multiple label vectors generated after that run.
cfg.repNum = 10;
cfg.repeatMode = 'label';
cfg.featureField = '';
cfg.labelField = '';
% Map ground-truth labels to compact 1..K labels after loading. This keeps
% datasets such as Returns, whose labels start at 0, compatible with MATLAB
% algorithms that index by class label.
cfg.relabelGroundTruth = true;

% Final data passed to algorithms uses d_i x n views and n x 1 labels.
% If a raw view is stored as n x d_i, it will be transposed to d_i x n.
cfg.outputFormat = 'd_by_n';
cfg.autoTranspose = true;
% Keep this false by default so the skill does not change reported accuracy.
% Enable it only when the original algorithm demo performs the same normalization.
cfg.normalize = false;
cfg.normalizeMode = 'auto_l2';
cfg.normalizeFunction = '';
cfg.replaceInvalid = false;
cfg.nanInfValue = 0;

cfg.metricPath = fullfile(skillRoot, 'metrics');
cfg.metricFunction = 'Clustering8Measure';
cfg.metricNames = {'ACC', 'NMI', 'Purity', 'Fscore', 'Precision', 'Recall', 'ARI', 'Entropy'};

cfg.params = struct();
cfg.datasetParams = struct();
cfg.paramNameOrder = {};
cfg.runner = [];
% Iteration logging is optional. If the runner returns a second output,
% mvskill_run_batch tries to read a numeric scalar directly or from these
% common fields when the second output is a struct.
cfg.iterationField = '';
cfg.iterationFields = {'iter', 'iters', 'iteration', 'iterations', ...
    'iterNum', 'iterationNum', 'numIter', 'nIter', 'convergedIter'};

cfg.saveTxt = true;
cfg.saveXlsx = true;
cfg.saveMat = true;
cfg.skipMissingDataset = true;
cfg.continueOnError = false;
cfg.verbose = true;
end
