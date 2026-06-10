# MVDataSkill

<p align="center">
  <b>A MATLAB toolkit for reproducible batch experiments in multi-view clustering.</b>
</p>

<p align="center">
  <a href="#english">English</a> | <a href="#chinese">中文</a>
</p>

## Table of Contents

- [English](#english)
- [Overview](#overview)
- [Key Features](#key-features)
- [Repository Structure](#repository-structure)
- [Install as a Codex Skill](#install-as-a-codex-skill)
- [Use the Skill in Codex](#use-the-skill-in-codex)
- [Quick Start](#quick-start)
- [Dataset-Specific Hyperparameters](#dataset-specific-hyperparameters)
- [Built-in Evaluation Metrics](#built-in-evaluation-metrics)
- [Runtime Measurement](#runtime-measurement)
- [Output Files](#output-files)
- [Chinese / 中文](#chinese)

---

## English

## Overview

**MVDataSkill** is a reusable MATLAB toolkit for running multi-view clustering comparison experiments in a consistent and reproducible way. It provides a unified experiment wrapper for loading datasets, preparing multi-view data, applying dataset-specific hyperparameters, running clustering algorithms repeatedly, evaluating results, recording runtime, and saving all outputs.

The toolkit is designed for research workflows where different comparison algorithms may use different `Demo.m` scripts, dataset variable names, parameter settings, and evaluation files. MVDataSkill centralizes these common steps so each algorithm only needs to provide a small runner function.

## Key Features

- Batch runs multiple `.mat` datasets with one configuration file.
- Supports multi-view data stored as `X`, `data`, `fea`, or `features`.
- Supports common label fields such as `Y`, `y`, `gt`, `gnd`, `label`, `labels`, and `truth`.
- Maps loaded ground-truth labels to compact `1..K` labels by default, so datasets whose labels start at `0` can be used by algorithms that index by class label.
- Preserves final accuracy by default: no normalization or invalid-value replacement is applied unless explicitly enabled.
- Supports both `d x n` and `n x d` view formats.
- Parses dataset-specific hyperparameters from original MATLAB demo scripts.
- Falls back to paper/default hyperparameters when a dataset has no specific setting.
- Includes built-in evaluation metrics, so algorithms do not need their own metric files.
- Records runtime with `tic` before the algorithm runner and `toc` immediately after labels are returned.
- Records optional iteration counts when the runner returns them as a second output or inside an `extra` struct field such as `iter`, `iteration`, `iterNum`, or `numIter`.
- Saves per-dataset and all-dataset summary results to `result/`.

## Repository Structure

```text
MVDataSkill/
├── README.md
└── MVDataSkill/
    ├── mvskill_default_config.m
    ├── mvskill_run_batch.m
    ├── mvskill_preprocess_views.m
    ├── mvskill_load_dataset.m
    ├── mvskill_evaluate.m
    ├── metrics/
    │   ├── Accuracy.m
    │   ├── Clustering8Measure.m
    │   ├── compute_f.m
    │   ├── compute_nmi.m
    │   ├── Contingency.m
    │   ├── purity.m
    │   └── RandIndex.m
    └── examples/
        ├── Demo_Template_for_Algorithm.m
        └── Demo_JSMC_with_MVDataSkill.m
```

## Install as a Codex Skill

Assume you are in the repository root.

### Codex

Copy the skill folder into `$CODEX_HOME/skills/mvdataskill/`.

For macOS, Linux, or Git Bash:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/mvdataskill"
cp -R MVDataSkill/. "${CODEX_HOME:-$HOME/.codex}/skills/mvdataskill/"
```

For Windows PowerShell:

```powershell
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$skillDir = Join-Path $codexHome "skills\mvdataskill"
New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
Copy-Item -Recurse -Force ".\MVDataSkill\*" $skillDir
```

Restart Codex after installation so the new skill can be discovered.

## Use the Skill in Codex

After installation, mention the skill in your Codex request:

```text
Use $mvdataskill to modify this MATLAB clustering algorithm so it can batch-run multi-view datasets and save ACC/NMI/Purity/ARI results.
```

Another example:

```text
Use $mvdataskill to wrap this algorithm's Demo.m with unified preprocessing, dataset-specific hyperparameters, runtime recording, and result saving.
```

Codex will read the skill instructions from `MVDataSkill/SKILL.md` and use the MATLAB helper functions in this repository to adapt comparison algorithms.

## Quick Start

Add the toolkit to the MATLAB path:

```matlab
addpath(genpath('path/to/MVDataSkill/MVDataSkill'));
```

Create a batch-running configuration:

```matlab
cfg = mvskill_default_config();

cfg.algorithmName = 'YourAlgorithm';
cfg.algorithmRoot = 'path/to/your/algorithm';
cfg.dataPath = fullfile(cfg.algorithmRoot, 'datasets');
cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');

cfg.dataList = {
    'ORL.mat'
    'Yale.mat'
    'BBCSport.mat'
};

cfg.repNum = 10;
cfg.outputFormat = 'd_by_n';
cfg.relabelGroundTruth = true; % Map labels such as 0..K-1 to 1..K.

% Keep these disabled unless the original algorithm demo does the same.
cfg.replaceInvalid = false;
cfg.normalize = false;

cfg.params = struct();
cfg.params.alpha = 1;
cfg.params.beta = 0.1;
cfg.params.lambda = 0.1;

cfg.runner = @(X, K, info, repIdx, cfg) runYourAlgorithm( ...
    X, K, cfg.params.alpha, cfg.params.beta, cfg.params.lambda);

summary = mvskill_run_batch(cfg);
```

## Dataset-Specific Hyperparameters

Many paper implementations define hyperparameters directly beside dataset-loading code:

```matlab
load('BBC','label','data');
alpha = 0.1; lambda = 0.01; beta = 0.1;

% load('ORL_mtv','gt','X');
% alpha = 0.001; lambda = 0.01; beta = 1;
```

MVDataSkill can parse these settings:

```matlab
paramInfo = mvskill_parse_params_from_demo(fullfile(cfg.algorithmRoot, 'Demo.m'));

cfg.params = paramInfo.activeParams;          % Default fallback parameters
cfg.datasetParams = paramInfo.datasetParams;  % Dataset-specific overrides
cfg.paramNameOrder = {'alpha', 'lambda', 'beta', 'sigma', 'gamma', 'mu1', 'mu2', 'rho'};
```

For each dataset, MVDataSkill uses:

```text
current parameters = default cfg.params + matched dataset-specific overrides
```

If no dataset-specific hyperparameters are found, the default paper/original-demo parameters are used.

## Built-in Evaluation Metrics

MVDataSkill includes the metric functions needed for common clustering evaluation:

```text
ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Entropy
```

The default metric function is:

```matlab
cfg.metricFunction = 'Clustering8Measure';
```

The built-in metric files are located in:

```text
MVDataSkill/metrics/
```

## Runtime Measurement

Runtime is measured only around the algorithm runner:

```matlab
tic;
label = runner(...);
Time = toc;
```

Metric computation happens after `toc`, so `time_mean` and `time_std` reflect algorithm runtime rather than evaluation time.
If the runner returns iteration information, `iteration_mean` and `iteration_std` are saved beside the time columns.

## Output Files

Results are saved under the algorithm's `result/` directory:

```text
result/
├── Algorithm_all_datasets_summary_result.txt
├── Algorithm_all_datasets_summary_result.xlsx
└── DatasetName/
    ├── DatasetName_Algorithm_result.txt
    ├── DatasetName_Algorithm_result.xlsx
    └── DatasetName_Algorithm_result.mat
```

---

<a id="chinese"></a>

## 中文

**MVDataSkill** 是一个用于多视图聚类对比实验的 MATLAB 工具包。它把数据批量读取、多视图数据预处理、数据集超参数匹配、重复运行、评价指标计算、运行时间统计和结果保存统一封装起来，方便在不同对比算法之间复用。

### 主要功能

- 支持批量运行多个 `.mat` 数据集。
- 自动识别常见特征变量名，例如 `X`、`data`、`fea`、`features`。
- 自动识别常见标签变量名，例如 `Y`、`y`、`gt`、`gnd`、`label`、`labels`、`truth`。
- 默认不做归一化、不替换 `NaN/Inf`，避免改变原算法最终准确率。
- 支持 `d x n` 和 `n x d` 两种数据方向。
- 支持从原始 `Demo.m` 中解析不同数据集对应的超参数。
- 若某个数据集没有专属超参数，则自动使用原文默认超参数。
- 内置 ACC、NMI、Purity、F-score、ARI 等评价指标。
- 用 `tic` 和 `toc` 统计算法运行时间，评价指标计算不计入运行时间。
- 自动保存每个数据集结果和总汇总结果到 `result/` 文件夹。

### 快速使用

### 在 Codex 中安装 Skill

假设当前路径是仓库根目录。

如果你使用 macOS、Linux 或 Git Bash：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/mvdataskill"
cp -R MVDataSkill/. "${CODEX_HOME:-$HOME/.codex}/skills/mvdataskill/"
```

如果你使用 Windows PowerShell：

```powershell
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$skillDir = Join-Path $codexHome "skills\mvdataskill"
New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
Copy-Item -Recurse -Force ".\MVDataSkill\*" $skillDir
```

安装完成后，重启 Codex，让 Codex 自动发现这个 skill。

### 在 Codex 中使用

安装后，可以在 Codex 对话中直接这样调用：

```text
Use $mvdataskill to modify this MATLAB clustering algorithm so it can batch-run multi-view datasets and save ACC/NMI/Purity/ARI results.
```

也可以这样描述具体任务：

```text
Use $mvdataskill to wrap this algorithm's Demo.m with unified preprocessing, dataset-specific hyperparameters, runtime recording, and result saving.
```

Codex 会读取 `MVDataSkill/SKILL.md` 中的说明，并调用本仓库中的 MATLAB 工具函数来改造其它多视图聚类对比算法。

```matlab
addpath(genpath('path/to/MVDataSkill/MVDataSkill'));

cfg = mvskill_default_config();
cfg.algorithmName = 'YourAlgorithm';
cfg.algorithmRoot = 'path/to/your/algorithm';
cfg.dataPath = fullfile(cfg.algorithmRoot, 'datasets');
cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');

cfg.dataList = {'ORL.mat', 'Yale.mat', 'BBCSport.mat'};
cfg.repNum = 10;
cfg.outputFormat = 'd_by_n';

cfg.replaceInvalid = false;
cfg.normalize = false;

cfg.params = struct('alpha', 1, 'beta', 0.1, 'lambda', 0.1);
cfg.runner = @(X, K, info, repIdx, cfg) runYourAlgorithm( ...
    X, K, cfg.params.alpha, cfg.params.beta, cfg.params.lambda);

summary = mvskill_run_batch(cfg);
```

### 数据集超参数

如果原始算法脚本中写有不同数据集对应的超参数，可以使用：

```matlab
paramInfo = mvskill_parse_params_from_demo(fullfile(cfg.algorithmRoot, 'Demo.m'));

cfg.params = paramInfo.activeParams;
cfg.datasetParams = paramInfo.datasetParams;
cfg.paramNameOrder = {'alpha', 'lambda', 'beta', 'sigma', 'gamma', 'mu1', 'mu2', 'rho'};
```

运行时，每个数据集会优先使用自己的专属超参数；如果没有匹配到，则使用 `cfg.params` 中的默认超参数。

### 结果保存

所有结果默认保存到算法目录下的 `result/` 文件夹，其中包括：

- 每个数据集的 `.txt`、`.xlsx`、`.mat` 结果文件。
- 所有数据集的汇总 `.txt` 和 `.xlsx` 文件。
- 实际使用的超参数、评价指标均值和标准差、运行时间均值和标准差。
