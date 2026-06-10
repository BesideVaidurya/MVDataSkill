---
name: mvdataskill
description: Batch-run MATLAB multi-view clustering comparison algorithms with unified multi-view data loading/preprocessing, dataset-specific hyperparameter handling from Demo.m, built-in ACC/NMI/Purity/F-score/ARI metrics, runtime measurement, label-based mean/std statistics, and result saving under result/. Use when adapting MATLAB multi-view clustering algorithms or experiment scripts to run multiple datasets consistently.
---

# MVDataSkill

Use this project-local MATLAB skill when running multi-view clustering comparison algorithms in this workspace.

## Workflow

1. Add the skill to MATLAB path with `addpath(genpath('E:\coding\papper\sub\MVDataSkill'))`.
2. Build a config with `mvskill_default_config()`.
3. Set `cfg.algorithmName`, `cfg.algorithmRoot`, `cfg.dataPath`, `cfg.dataList`, `cfg.params`, and `cfg.runner`.
4. Keep `cfg.outputFormat = 'd_by_n'` for algorithms whose samples are columns. Raw `n x d_i` views are transposed to final `d_i x n` when `cfg.autoTranspose = true`.
5. If the original algorithm demo contains dataset-specific parameter assignments, parse them with `paramInfo = mvskill_parse_params_from_demo(demoFile)` and set `cfg.datasetParams = paramInfo.datasetParams`.
6. Run `summary = mvskill_run_batch(cfg)`.

The default metrics are built into:

`E:\coding\papper\sub\MVDataSkill\metrics`

The default metric order is:

`ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Entropy`

Timing is measured with `tic` immediately before calling the algorithm runner and `toc` immediately after the runner returns labels.

`mvskill_run_batch` calls the runner once per dataset. If standard deviation is needed, the runner should return multiple clustering label vectors produced after that algorithm run, for example an `n x r` matrix, `r x n` matrix, or a cell array. The skill computes ACC/NMI/etc. for each label vector and reports metric mean/std over those labels.
