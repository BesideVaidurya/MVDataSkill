clear;
clc;
close all;

exampleRoot = fileparts(mfilename('fullpath'));
skillRoot = fileparts(exampleRoot);
subRoot = fileparts(skillRoot);

addpath(genpath(skillRoot));

cfg = mvskill_default_config();
cfg.algorithmName = 'JSMC';
cfg.algorithmRoot = fullfile(subRoot, 'JSMC-main', 'JSMC-main');
cfg.dataPath = fullfile(cfg.algorithmRoot, 'datasets');
cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');

cfg.dataList = {
    'ORL.mat'
    'Yale.mat'
    'BBCSport.mat'
    'Reuters-1200.mat'
    'WebKB.mat'
    '3sources.mat'
    'EYaleB10.mat'
    'COIL20.mat'
    'UCI.mat'
};

cfg.repNum = 10;
cfg.outputFormat = 'd_by_n';
cfg.replaceInvalid = true;
cfg.normalize = true;
cfg.normalizeFunction = 'NormalizeData';

cfg.params = struct();
cfg.params.alpha = 1;
cfg.params.beta = 0.1;
cfg.params.lambda = 0.1;

cfg.runner = @(X, K, info, repIdx, cfg) runJSMC( ...
    X, K, cfg.params.alpha, cfg.params.beta, cfg.params.lambda);

summary = mvskill_run_batch(cfg);
