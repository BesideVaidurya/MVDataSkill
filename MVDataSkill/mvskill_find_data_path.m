function dataPath = mvskill_find_data_path(cfg)
%MVSKILL_FIND_DATA_PATH Resolve a dataset folder from config.

if isfield(cfg, 'dataPath') && ~isempty(cfg.dataPath)
    if exist(cfg.dataPath, 'dir')
        dataPath = cfg.dataPath;
        return;
    end
    error('Configured dataPath does not exist: %s', cfg.dataPath);
end

roots = {};
if isfield(cfg, 'algorithmRoot') && ~isempty(cfg.algorithmRoot)
    roots{end + 1} = cfg.algorithmRoot;
end
roots{end + 1} = pwd;

folderNames = {'datasets', 'dataset', 'data'};
for r = 1:numel(roots)
    for f = 1:numel(folderNames)
        p = fullfile(roots{r}, folderNames{f});
        if exist(p, 'dir')
            dataPath = p;
            return;
        end
    end
end

error('Dataset folder was not found. Set cfg.dataPath or create datasets/dataset/data.');
end
