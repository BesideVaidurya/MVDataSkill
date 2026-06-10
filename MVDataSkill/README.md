# MVDataSkill

`MVDataSkill` is a reusable MATLAB toolkit for multi-view clustering comparison experiments.
It centralizes dataset loading, multi-view preprocessing, metric evaluation, label-based mean/std statistics, and result saving.

## What It Does

- Loads `.mat` datasets and automatically finds feature variables: `X`, `data`, `fea`, or `features`.
- Loads labels from common fields: `Y`, `y`, `gt`, `gnd`, `truelabel`, `label`, `labels`, or `truth`.
- Maps loaded ground-truth labels to compact `1..K` labels by default, so datasets whose labels start at `0` can still be used by MATLAB code that indexes by class label. The original labels and mapping are saved in result `.mat` files.
- Converts every view to a fixed final orientation, default `d x n` where columns are samples. Raw `n x d` views are transposed automatically when `cfg.autoTranspose = true`.
- Converts sparse/logical data to `double`; `NaN/Inf` replacement and normalization are only done when explicitly enabled.
- Calls the built-in metric files in `E:\coding\papper\sub\MVDataSkill\metrics`, so algorithms do not need to carry their own ACC/NMI/F-score files.
- Saves per-dataset `.txt`, `.xlsx`, `.mat` files and an all-dataset summary, including runtime and optional iteration count columns.

## Quick Use

```matlab
addpath(genpath('E:\coding\papper\sub\MVDataSkill'));

cfg = mvskill_default_config();
cfg.algorithmName = 'JSMC';
cfg.algorithmRoot = 'E:\coding\papper\sub\JSMC-main\JSMC-main';
cfg.dataPath = fullfile(cfg.algorithmRoot, 'datasets');
cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');

cfg.dataList = {'ORL.mat', 'Yale.mat', 'BBCSport.mat'};
cfg.repNum = 10;          % Number of returned label vectors expected for mean/std.
cfg.outputFormat = 'd_by_n';
cfg.autoTranspose = true; % Raw n x d_i views are converted to final d_i x n.
cfg.relabelGroundTruth = true; % Map labels such as 0..K-1 to 1..K.
cfg.replaceInvalid = false;
cfg.normalize = false;
% Optional: set these only when you want to match the original Demo.m exactly.
% cfg.featureField = 'X';
% cfg.labelField = 'gt';

cfg.params = struct('alpha', 1, 'beta', 0.1, 'lambda', 0.1);
cfg.runner = @(X, K, info, repIdx, cfg) runJSMC( ...
    X, K, cfg.params.alpha, cfg.params.beta, cfg.params.lambda);

summary = mvskill_run_batch(cfg);
```

To avoid changing final ACC/NMI/Purity, normalization is off by default. Turn it on only if the original demo does the same preprocessing:

```matlab
cfg.replaceInvalid = true;       % Only if the original demo replaces NaN/Inf.
cfg.normalize = true;
cfg.normalizeFunction = 'NormalizeData';  % Example for JSMC.
```

## Dataset-Specific Hyperparameters

Many paper demos keep dataset-specific hyperparameters on the same line as `load(...)`, for example:

```matlab
load('BBC','label','data'); alpha=0.1; lambda=0.01; beta=0.1; sigma=0.1;
%load('ORL_mtv','gt','X'); alpha=0.001; lambda=0.01; beta=1; sigma=0.01;
```

Use `mvskill_parse_params_from_demo` to extract these values:

```matlab
paramInfo = mvskill_parse_params_from_demo( ...
    'E:\coding\papper\sub\YourAlgorithm-main\YourAlgorithm-main\Demo.m');

% Default fallback from the original paper/demo. Used when no dataset-specific
% params are found for the current dataset.
cfg.params = struct('alpha', 0.1, 'lambda', 0.01, 'beta', 0.1, ...
    'sigma', 0.1, 'gamma', 0.01, 'mu1', 10e-3, 'mu2', 10e-2, 'rho', 10e-1);

% Dataset-specific overrides parsed from active and commented load(...) lines.
cfg.datasetParams = paramInfo.datasetParams;
cfg.paramNameOrder = {'alpha', 'lambda', 'beta', 'sigma', 'gamma', 'mu1', 'mu2', 'rho'};
```

If the uncommented `load(...)` line in the original demo is the paper's default setting, you can use it directly:

```matlab
cfg.params = paramInfo.activeParams;
```

During `mvskill_run_batch`, the actual params for one dataset are:

```matlab
currentParams = default cfg.params + matching cfg.datasetParams override
```

Dataset matching is case-insensitive and ignores `.mat`, spaces, hyphens, and underscores where possible through a safe internal key. For example, `BBC.mat` matches `load('BBC', ...)`.

## Runner Interface

The runner is the only algorithm-specific part. These forms are supported:

```matlab
cfg.runner = @(X, K) myAlgorithm(X, K);
cfg.runner = @(X, K, info) myAlgorithm(X, K, info.sampleNum);
cfg.runner = @(X, K, info, repIdx, cfg) myAlgorithm(X, K, cfg.params.alpha);
```

The runner is called once per dataset. It can return one label vector or multiple label vectors produced after that algorithm run. Supported label output formats are:

```matlab
label          % n x 1 or 1 x n
labelMatrix    % n x r or r x n, where r is the number of label outputs
labelCell      % 1 x r or r x 1 cell array, each cell is one n-sample label vector
```

`mvskill_run_batch` computes metrics for each returned label vector, then reports metric `mean/std` over those label vectors. It does not repeatedly run the complete algorithm just to compute standard deviation.

If the algorithm exposes its iteration count, return it as the runner's second output:

```matlab
cfg.runner = @runnerWithIter;

function [label, iterNum] = runnerWithIter(X, K, info, repIdx, cfg)
    [label, iterNum] = runYourAlgorithm(...);
end
```

or return a struct whose field is one of `iter`, `iteration`, `iterNum`, `numIter`, etc. `mvskill_run_batch` records this in `iteration_mean` and `iteration_std`.

## Output Orientation

Use this for algorithms like JSMC/CMSR that compute `size(X{1}, 2)` as sample number:

```matlab
cfg.outputFormat = 'd_by_n';
cfg.autoTranspose = true;
```

Use this for algorithms that expect rows as samples:

```matlab
cfg.outputFormat = 'n_by_d';
```

## Metric Order

The default metric function is `Clustering8Measure`, and the result order is:

```matlab
ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Entropy
```

You can change the metric path or function:

```matlab
cfg.metricPath = 'E:\coding\papper\sub\MVDataSkill\metrics';
cfg.metricFunction = 'Clustering8Measure';
```

Timing is measured around the algorithm runner only:

```matlab
tic;
label = runner(...);
Time = toc;
```

Metric computation happens after `toc`, so `time_mean` and `time_std` record algorithm runtime, not evaluation time.
If the runner returns iteration information, `iteration_mean` and `iteration_std` are saved beside the time columns.

## Example

See:

```matlab
E:\coding\papper\sub\MVDataSkill\examples\Demo_JSMC_with_MVDataSkill.m
E:\coding\papper\sub\MVDataSkill\examples\Demo_Template_for_Algorithm.m
```
