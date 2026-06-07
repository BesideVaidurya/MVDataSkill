# MVDataSkill

Use this project-local MATLAB skill when running multi-view clustering comparison algorithms in this workspace.

## Workflow

1. Add the skill to MATLAB path with `addpath(genpath('E:\coding\papper\sub\MVDataSkill'))`.
2. Build a config with `mvskill_default_config()`.
3. Set `cfg.algorithmName`, `cfg.algorithmRoot`, `cfg.dataPath`, `cfg.dataList`, `cfg.params`, and `cfg.runner`.
4. Keep `cfg.outputFormat = 'd_by_n'` for algorithms whose samples are columns, or use `n_by_d` when samples are rows.
5. If the original algorithm demo contains dataset-specific parameter assignments, parse them with `paramInfo = mvskill_parse_params_from_demo(demoFile)` and set `cfg.datasetParams = paramInfo.datasetParams`.
6. Run `summary = mvskill_run_batch(cfg)`.

The default metrics are built into:

`E:\coding\papper\sub\MVDataSkill\metrics`

The default metric order is:

`ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Entropy`

Timing is measured with `tic` immediately before calling the algorithm runner and `toc` immediately after the runner returns labels.
