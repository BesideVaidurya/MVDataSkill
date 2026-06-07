clear;
clc;
close all;

addpath(genpath('E:\coding\papper\sub\MVDataSkill'));

cfg = mvskill_default_config();

% 1) Change these paths for a new comparison algorithm.
cfg.algorithmName = 'YourAlgorithm';
cfg.algorithmRoot = 'E:\coding\papper\sub\YourAlgorithm-main\YourAlgorithm-main';
cfg.dataPath = fullfile(cfg.algorithmRoot, 'datasets');
cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');

% 2) Leave empty to run all .mat files in cfg.dataPath.
cfg.dataList = {
    'ORL.mat'
    'Yale.mat'
};

% 3) Use d_by_n when columns are samples; use n_by_d when rows are samples.
cfg.outputFormat = 'd_by_n';
% Keep false unless the original Demo.m replaces NaN/Inf values.
cfg.replaceInvalid = false;
% Keep false unless the original Demo.m explicitly normalizes data before running.
cfg.normalize = false;
cfg.repNum = 10;

% Optional: set these only when the original Demo.m uses specific variable names.
% cfg.featureField = 'X';
% cfg.labelField = 'gt';

% 4) Put all algorithm parameters here. They will be saved in result tables.
cfg.params = struct();
cfg.params.alpha = 1;
cfg.params.beta = 0.1;

% Optional: parse dataset-specific params from an original Demo.m.
% paramInfo = mvskill_parse_params_from_demo(fullfile(cfg.algorithmRoot, 'Demo.m'));
% cfg.params = paramInfo.activeParams; % Use this only if the active line is the default setting.
% cfg.datasetParams = paramInfo.datasetParams;
% cfg.paramNameOrder = {'alpha', 'lambda', 'beta', 'sigma', 'gamma', 'mu1', 'mu2', 'rho'};

% 5) Replace runYourAlgorithm with your algorithm entry function.
% cfg.params is automatically changed to the current dataset's merged params.
cfg.runner = @(X, K, info, repIdx, cfg) runYourAlgorithm( ...
    X, K, cfg.params.alpha, cfg.params.beta);

summary = mvskill_run_batch(cfg);
