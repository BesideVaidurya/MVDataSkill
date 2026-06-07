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
cfg.repNum = 10;
cfg.featureField = '';
cfg.labelField = '';

% Most subspace-clustering codes in this workspace use d x n views.
cfg.outputFormat = 'd_by_n';
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

cfg.saveTxt = true;
cfg.saveXlsx = true;
cfg.saveMat = true;
cfg.skipMissingDataset = true;
cfg.continueOnError = false;
cfg.verbose = true;
end
