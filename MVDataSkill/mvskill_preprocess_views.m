function [X, info] = mvskill_preprocess_views(rawX, gt, cfg)
%MVSKILL_PREPROCESS_VIEWS Validate and optionally normalize multi-view data.
%
% Default convention:
%   output X{v}: d_i x n
%   output gt:   n x 1
% Raw n x d_i views are transposed to d_i x n when cfg.autoTranspose is true.

defaultCfg = mvskill_default_config();
if nargin < 3 || isempty(cfg)
    cfg = defaultCfg;
else
    cfg = merge_config(defaultCfg, cfg);
end
if ~iscell(rawX)
    rawX = {rawX};
end

gt = double(gt(:));
sampleNum = length(gt);
viewNum = numel(rawX);
X = cell(1, viewNum);
viewSizeBefore = cell(1, viewNum);
viewSizeAfter = cell(1, viewNum);
viewTransposed = false(1, viewNum);

outputFormat = 'd_by_n';
if isfield(cfg, 'outputFormat') && ~isempty(cfg.outputFormat)
    outputFormat = cfg.outputFormat;
end

for iv = 1:viewNum
    Xi = rawX{iv};
    if isempty(Xi)
        error('View %d is empty.', iv);
    end
    if issparse(Xi)
        Xi = full(Xi);
    end
    if ~(isnumeric(Xi) || islogical(Xi))
        error('View %d should be numeric or logical, but it is %s.', iv, class(Xi));
    end

    viewSizeBefore{iv} = size(Xi);
    Xi = double(Xi);

    badIdx = isnan(Xi) | isinf(Xi);
    if any(badIdx(:))
        if isfield(cfg, 'replaceInvalid') && cfg.replaceInvalid
            Xi(badIdx) = cfg.nanInfValue;
        else
            error(['View %d contains NaN/Inf values. To match an original demo that ', ...
                'replaces invalid values, set cfg.replaceInvalid = true.'], iv);
        end
    end

    if is_d_by_n(outputFormat)
        if size(Xi, 2) == sampleNum
            % already d x n
        elseif isfield(cfg, 'autoTranspose') && cfg.autoTranspose && size(Xi, 1) == sampleNum
            Xi = Xi';
            viewTransposed(iv) = true;
        else
            error(['View %d must be d_i x n, with n equal to length(gt). ', ...
                'size(X{%d}) = [%d, %d], length(gt) = %d. ', ...
                'If this dataset is n x d_i, keep cfg.autoTranspose = true.'], ...
                iv, iv, size(Xi, 1), size(Xi, 2), sampleNum);
        end
    elseif is_n_by_d(outputFormat)
        if size(Xi, 1) == sampleNum
            % already n x d
        elseif isfield(cfg, 'autoTranspose') && cfg.autoTranspose && size(Xi, 2) == sampleNum
            Xi = Xi';
            viewTransposed(iv) = true;
        else
            error(['View %d must be n x d_i when cfg.outputFormat is n_by_d. ', ...
                'size(X{%d}) = [%d, %d], length(gt) = %d. ', ...
                'If this dataset is d_i x n, keep cfg.autoTranspose = true.'], ...
                iv, iv, size(Xi, 1), size(Xi, 2), sampleNum);
        end
    else
        error('Unknown cfg.outputFormat: %s. Use d_by_n or n_by_d.', outputFormat);
    end

    if isfield(cfg, 'normalize') && cfg.normalize
        Xi = normalize_view(Xi, outputFormat, cfg);
    end

    X{iv} = double(Xi);
    viewSizeAfter{iv} = size(Xi);
end

info = struct();
info.viewNum = viewNum;
info.sampleNum = sampleNum;
info.classNum = length(unique(gt));
info.outputFormat = outputFormat;
info.viewSizeBefore = viewSizeBefore;
info.viewSizeAfter = viewSizeAfter;
info.viewTransposed = viewTransposed;
end

function tf = is_d_by_n(fmt)
tf = strcmpi(fmt, 'd_by_n') || strcmpi(fmt, 'dxn') || ...
    strcmpi(fmt, 'column') || strcmpi(fmt, 'columns') || strcmpi(fmt, 'feature_by_sample');
end

function tf = is_n_by_d(fmt)
tf = strcmpi(fmt, 'n_by_d') || strcmpi(fmt, 'nxd') || ...
    strcmpi(fmt, 'row') || strcmpi(fmt, 'rows') || strcmpi(fmt, 'sample_by_feature');
end

function Xi = normalize_view(Xi, outputFormat, cfg)
if isfield(cfg, 'normalizeFunction') && ~isempty(cfg.normalizeFunction) && ...
        exist(cfg.normalizeFunction, 'file') == 2
    fh = str2func(cfg.normalizeFunction);
    Xi = fh(Xi);
    return;
end

mode = 'auto_l2';
if isfield(cfg, 'normalizeMode') && ~isempty(cfg.normalizeMode)
    mode = cfg.normalizeMode;
end

if strcmpi(mode, 'none')
    return;
elseif strcmpi(mode, 'column_l2') || (strcmpi(mode, 'auto_l2') && is_d_by_n(outputFormat))
    normValue = sqrt(sum(Xi .^ 2, 1));
    normValue(normValue < 1e-12) = 1;
    Xi = bsxfun(@rdivide, Xi, normValue);
elseif strcmpi(mode, 'row_l2') || (strcmpi(mode, 'auto_l2') && is_n_by_d(outputFormat))
    normValue = sqrt(sum(Xi .^ 2, 2));
    normValue(normValue < 1e-12) = 1;
    Xi = bsxfun(@rdivide, Xi, normValue);
else
    error('Unknown cfg.normalizeMode: %s.', mode);
end
end

function cfg = merge_config(defaultCfg, cfg)
names = fieldnames(defaultCfg);
for i = 1:numel(names)
    if ~isfield(cfg, names{i})
        cfg.(names{i}) = defaultCfg.(names{i});
    end
end
end
