function cleanupObj = mvskill_addpath(cfg)
%MVSKILL_ADDPATH Add skill, algorithm, data and metric folders to path.

originalPath = path;
cleanupObj = onCleanup(@() path(originalPath));

if nargin < 1 || isempty(cfg)
    cfg = mvskill_default_config();
end

if isfield(cfg, 'skillRoot') && exist(cfg.skillRoot, 'dir')
    addpath(genpath(cfg.skillRoot));
end

if isfield(cfg, 'algorithmRoot') && ~isempty(cfg.algorithmRoot) && exist(cfg.algorithmRoot, 'dir')
    addpath(cfg.algorithmRoot);
    if isfield(cfg, 'codeFolders')
        for i = 1:numel(cfg.codeFolders)
            p = fullfile(cfg.algorithmRoot, cfg.codeFolders{i});
            if exist(p, 'dir')
                addpath(genpath(p));
            end
        end
    end
end

if isfield(cfg, 'dataPath') && ~isempty(cfg.dataPath) && exist(cfg.dataPath, 'dir')
    addpath(cfg.dataPath);
end

end
