function summary = mvskill_run_batch(cfg)
%MVSKILL_RUN_BATCH Batch run one multi-view clustering algorithm.
%
% Required:
%   cfg.runner = @(X, K, info, repIdx, cfg) yourAlgorithm(...)
%
% Repetition convention:
%   The runner is called once for each dataset. If mean/std is needed, the
%   runner should return multiple clustering label vectors generated after
%   that algorithm run, e.g. an n x r matrix, r x n matrix, or a cell array.
%   Metrics are averaged over those returned labels, not over repeated
%   complete algorithm runs.

if nargin < 1
    cfg = [];
end
defaultCfg = mvskill_default_config();
cfg = merge_config(defaultCfg, cfg);

if isempty(cfg.runner)
    error('cfg.runner is required. Example: cfg.runner = @(X,K,info,rep,cfg) runJSMC(X,K,1,0.1,0.1);');
end

cleanupObj = mvskill_addpath(cfg); %#ok<NASGU>

dataPath = mvskill_find_data_path(cfg);
if isempty(cfg.dataList)
    cfg.dataList = mvskill_list_datasets(dataPath);
end

if isempty(cfg.resultRoot)
    if ~isempty(cfg.algorithmRoot)
        cfg.resultRoot = fullfile(cfg.algorithmRoot, 'result');
    else
        cfg.resultRoot = fullfile(pwd, 'result');
    end
end
if ~exist(cfg.resultRoot, 'dir')
    mkdir(cfg.resultRoot);
end

metricNames = cfg.metricNames(:)';
metricNum = numel(metricNames);
paramNames = collect_param_names(cfg);

baseHeader = [{'dataset', 'view_num', 'sample_num', 'class_num'}, ...
    paramNames, {'time_mean', 'time_std', 'iteration_mean', 'iteration_std'}];
metricMeanHeader = cellfun(@(s) [s, '_mean'], metricNames, 'UniformOutput', false);
metricStdHeader = cellfun(@(s) [s, '_std'], metricNames, 'UniformOutput', false);
summaryHeader = [baseHeader, metricMeanHeader, metricStdHeader];

summaryCell = cell(numel(cfg.dataList) + 1, numel(summaryHeader));
summaryCell(1, :) = summaryHeader;
summaryRow = 2;

summaryTxt = fullfile(cfg.resultRoot, [cfg.algorithmName, '_all_datasets_summary_result.txt']);
summaryXlsx = fullfile(cfg.resultRoot, [cfg.algorithmName, '_all_datasets_summary_result.xlsx']);

fidSummary = fopen(summaryTxt, 'w');
if fidSummary < 0
    error('Cannot open summary txt file: %s', summaryTxt);
end
cleanupSummary = onCleanup(@() fclose(fidSummary)); %#ok<NASGU>
write_txt_row(fidSummary, summaryHeader);

datasetResults = cell(numel(cfg.dataList), 1);

for dataIndex = 1:numel(cfg.dataList)
    dataName = cfg.dataList{dataIndex};
    dataFile = fullfile(dataPath, dataName);

    try
        if cfg.verbose
            fprintf('\n=============================================\n');
            fprintf('Current dataset: %s\n', dataName);
            fprintf('=============================================\n');
        end

        if ~exist(dataFile, 'file')
            msg = sprintf('Dataset file does not exist, skip it: %s', dataFile);
            if cfg.skipMissingDataset
                warning('%s', msg);
                continue;
            else
                error('%s', msg);
            end
        end

        rawData = mvskill_load_dataset(dataFile, cfg);
        [X, info] = mvskill_preprocess_views(rawData.rawX, rawData.gt, cfg);
        info.dataset = rawData.name;
        info.file = rawData.file;
        info.gt = rawData.gt;
        info.originalGt = rawData.originalGt;
        info.labelMap = rawData.labelMap;

        currentParams = mvskill_get_dataset_params(cfg.params, cfg.datasetParams, rawData.name);
        runCfg = cfg;
        runCfg.params = currentParams;
        runCfg.currentDataset = rawData.name;

        if cfg.verbose
            fprintf('Views: %d, samples: %d, classes: %d\n', ...
                info.viewNum, info.sampleNum, info.classNum);
        end

        resultDir = fullfile(cfg.resultRoot, rawData.name);
        if ~exist(resultDir, 'dir')
            mkdir(resultDir);
        end

        txtFile = fullfile(resultDir, [rawData.name, '_', cfg.algorithmName, '_result.txt']);
        xlsxFile = fullfile(resultDir, [rawData.name, '_', cfg.algorithmName, '_result.xlsx']);
        matFile = fullfile(resultDir, [rawData.name, '_', cfg.algorithmName, '_result.mat']);

        if cfg.verbose
            fprintf('Running %s once. Metrics mean/std will be computed from returned labels.\n', rawData.name);
        end

        tic;
        [labelOutput, extra] = call_runner(runCfg.runner, X, rawData.classNum, info, 1, runCfg);
        runTime = toc;

        labelRecord = collect_label_record(labelOutput, numel(rawData.gt), cfg.algorithmName, dataName);
        labelNum = numel(labelRecord);
        iterationRecord = collect_iteration_record(extra, labelNum, cfg);
        if cfg.verbose && cfg.repNum > 1 && labelNum == 1
            warning(['%s returned only one label vector for %s. ', ...
                'Metric std will be zero unless the runner returns multiple labels.'], ...
                cfg.algorithmName, dataName);
        end

        perf = zeros(labelNum, metricNum);
        extraRecord = cell(labelNum, 1);
        for labelIdx = 1:labelNum
            label = labelRecord{labelIdx};

            metric = mvskill_evaluate(rawData.gt, label, cfg);
            if numel(metric) ~= metricNum
                error('%s should return %d metrics, but it returned %d.', ...
                    cfg.metricFunction, metricNum, numel(metric));
            end

            extraRecord{labelIdx} = extra;
            perf(labelIdx, :) = metric;
        end

        meanPerf = mean(perf, 1);
        stdPerf = std(perf, 0, 1);
        timeRecord = runTime;
        timeMean = runTime;
        timeStd = 0;
        [iterationMean, iterationStd] = summarize_iteration_record(iterationRecord);

        paramValues = params_to_cells(currentParams, paramNames);
        currentRow = [{rawData.name, info.viewNum, info.sampleNum, info.classNum}, ...
            paramValues, {timeMean, timeStd, iterationMean, iterationStd}, ...
            num2cell(meanPerf), num2cell(stdPerf)];

        resultCell = cell(2, numel(summaryHeader));
        resultCell(1, :) = summaryHeader;
        resultCell(2, :) = currentRow;

        if cfg.saveTxt
            fid = fopen(txtFile, 'w');
            if fid < 0
                error('Cannot open txt file: %s', txtFile);
            end
            write_txt_row(fid, summaryHeader);
            write_txt_row(fid, currentRow);
            fclose(fid);
        end

        if cfg.saveXlsx
            mvskill_write_cell(resultCell, xlsxFile);
        end

        result = struct();
        result.dataset = rawData.name;
        result.algorithmName = cfg.algorithmName;
        result.params = currentParams;
        result.defaultParams = cfg.params;
        result.info = info;
        result.repNum = cfg.repNum;
        result.labelNum = labelNum;
        result.timeRecord = timeRecord;
        result.timeMean = timeMean;
        result.timeStd = timeStd;
        result.iterationRecord = iterationRecord;
        result.iterationMean = iterationMean;
        result.iterationStd = iterationStd;
        result.perf = perf;
        result.meanPerf = meanPerf;
        result.stdPerf = stdPerf;
        result.metricNames = metricNames;
        result.labelRecord = labelRecord;
        result.extraRecord = extraRecord;
        result.gt = rawData.gt;
        result.originalGt = rawData.originalGt;
        result.labelMap = rawData.labelMap;
        result.header = summaryHeader;

        if cfg.saveMat
            save(matFile, 'result');
        end

        summaryCell(summaryRow, :) = currentRow;
        summaryRow = summaryRow + 1;
        write_txt_row(fidSummary, currentRow);
        datasetResults{dataIndex} = result;

        if cfg.verbose
            fprintf('\n%s has completed.\n', rawData.name);
            fprintf('txt  saved to: %s\n', txtFile);
            fprintf('xlsx saved to: %s\n', xlsxFile);
            fprintf('mat  saved to: %s\n', matFile);
        end
    catch ME
        if cfg.continueOnError
            warning('Dataset failed and was skipped: %s\n%s', dataName, ME.message);
            errorDir = fullfile(cfg.resultRoot, 'errors');
            if ~exist(errorDir, 'dir')
                mkdir(errorDir);
            end
            errorFile = fullfile(errorDir, [safe_name(dataName), '_error.txt']);
            fidError = fopen(errorFile, 'w');
            if fidError >= 0
                fprintf(fidError, '%s\n', getReport(ME));
                fclose(fidError);
            end
        else
            rethrow(ME);
        end
    end
end

summaryCell = summaryCell(1:summaryRow - 1, :);
if cfg.saveXlsx
    mvskill_write_cell(summaryCell, summaryXlsx);
end

summary = struct();
summary.header = summaryHeader;
summary.cell = summaryCell;
summary.results = datasetResults;
summary.summaryTxt = summaryTxt;
summary.summaryXlsx = summaryXlsx;
summary.cfg = cfg;

if cfg.verbose
    fprintf('\nAll datasets have completed.\n');
    fprintf('Summary txt  saved to: %s\n', summaryTxt);
    fprintf('Summary xlsx saved to: %s\n', summaryXlsx);
end
end

function cfg = merge_config(defaultCfg, cfg)
if nargin < 2 || isempty(cfg)
    cfg = defaultCfg;
    return;
end
names = fieldnames(defaultCfg);
for i = 1:numel(names)
    if ~isfield(cfg, names{i})
        cfg.(names{i}) = defaultCfg.(names{i});
    end
end
end

function values = params_to_cells(params, paramNames)
values = cell(1, numel(paramNames));
for i = 1:numel(paramNames)
    if isfield(params, paramNames{i})
        values{i} = params.(paramNames{i});
    else
        values{i} = '';
    end
end
end

function names = collect_param_names(cfg)
names = {};
if isfield(cfg, 'paramNameOrder') && ~isempty(cfg.paramNameOrder)
    names = cfg.paramNameOrder(:)';
end

if isfield(cfg, 'params') && isstruct(cfg.params)
    names = union_stable(names, fieldnames(cfg.params)');
end

if isfield(cfg, 'datasetParams') && isstruct(cfg.datasetParams)
    keys = fieldnames(cfg.datasetParams);
    for i = 1:numel(keys)
        dsParams = cfg.datasetParams.(keys{i});
        if isstruct(dsParams)
            names = union_stable(names, fieldnames(dsParams)');
        end
    end
end
end

function out = union_stable(a, b)
out = a;
for i = 1:numel(b)
    if ~any(strcmp(out, b{i}))
        out{end + 1} = b{i}; %#ok<AGROW>
    end
end
end

function [label, extra] = call_runner(runner, X, K, info, repIdx, cfg)
extra = [];
nIn = nargin(runner);
nOut = nargout(runner);

if nIn < 0 || nIn >= 5
    if nOut < 0 || nOut >= 2
        [label, extra] = runner(X, K, info, repIdx, cfg);
    else
        label = runner(X, K, info, repIdx, cfg);
    end
elseif nIn == 4
    if nOut < 0 || nOut >= 2
        [label, extra] = runner(X, K, info, repIdx);
    else
        label = runner(X, K, info, repIdx);
    end
elseif nIn == 3
    if nOut < 0 || nOut >= 2
        [label, extra] = runner(X, K, info);
    else
        label = runner(X, K, info);
    end
else
    if nOut < 0 || nOut >= 2
        [label, extra] = runner(X, K);
    else
        label = runner(X, K);
    end
end
end

function labelRecord = collect_label_record(labelOutput, sampleNum, algorithmName, dataName)
if iscell(labelOutput)
    if isempty(labelOutput)
        error('%s returned an empty label cell array in %s.', algorithmName, dataName);
    end
    labelRecord = cell(numel(labelOutput), 1);
    for i = 1:numel(labelOutput)
        labelRecord{i} = validate_label_vector(labelOutput{i}, sampleNum, algorithmName, dataName);
    end
    return;
end

if ~(isnumeric(labelOutput) || islogical(labelOutput))
    error('%s returned labels with unsupported type %s in %s.', ...
        algorithmName, class(labelOutput), dataName);
end

labelOutput = double(labelOutput);
if isempty(labelOutput)
    error('%s returned empty labels in %s.', algorithmName, dataName);
end

if isvector(labelOutput)
    labelRecord = {validate_label_vector(labelOutput, sampleNum, algorithmName, dataName)};
elseif size(labelOutput, 1) == sampleNum
    labelRecord = cell(size(labelOutput, 2), 1);
    for i = 1:size(labelOutput, 2)
        labelRecord{i} = validate_label_vector(labelOutput(:, i), sampleNum, algorithmName, dataName);
    end
elseif size(labelOutput, 2) == sampleNum
    labelRecord = cell(size(labelOutput, 1), 1);
    for i = 1:size(labelOutput, 1)
        labelRecord{i} = validate_label_vector(labelOutput(i, :), sampleNum, algorithmName, dataName);
    end
else
    error(['%s returned label matrix with incompatible size in %s. ', ...
        'Expected n x r or r x n labels, where n = %d, but got [%d, %d].'], ...
        algorithmName, dataName, sampleNum, size(labelOutput, 1), size(labelOutput, 2));
end
end

function label = validate_label_vector(label, sampleNum, algorithmName, dataName)
label = double(label(:));
if numel(label) ~= sampleNum
    error('%s returned %d labels for %d samples in %s.', ...
        algorithmName, numel(label), sampleNum, dataName);
end
end

function iterationRecord = collect_iteration_record(extra, labelNum, cfg)
iterationRecord = [];
if nargin < 2 || isempty(labelNum)
    labelNum = 1;
end

if isempty(extra)
    return;
end

if isnumeric(extra) || islogical(extra)
    if isscalar(extra) || (isvector(extra) && numel(extra) == labelNum)
        candidate = double(extra(:));
    else
        return;
    end
else
    candidate = extract_iteration_value(extra, cfg);
end
if isempty(candidate)
    return;
end

candidate = double(candidate(:));
candidate = candidate(isfinite(candidate));
if isempty(candidate)
    return;
end

iterationRecord = candidate;
end

function [iterationMean, iterationStd] = summarize_iteration_record(iterationRecord)
if isempty(iterationRecord)
    iterationMean = '';
    iterationStd = '';
    return;
end

iterationMean = mean(iterationRecord(:));
if numel(iterationRecord) == 1
    iterationStd = 0;
else
    iterationStd = std(iterationRecord(:), 0);
end
end

function value = extract_iteration_value(extra, cfg)
value = [];

if isnumeric(extra) || islogical(extra)
    if isscalar(extra) || isvector(extra)
        value = double(extra(:));
    end
    return;
end

if iscell(extra)
    values = [];
    for i = 1:numel(extra)
        oneValue = extract_iteration_value(extra{i}, cfg);
        if ~isempty(oneValue)
            values = [values; oneValue(:)]; %#ok<AGROW>
        end
    end
    value = values;
    return;
end

if ~isstruct(extra)
    return;
end

if numel(extra) > 1
    values = [];
    for i = 1:numel(extra)
        oneValue = extract_iteration_value(extra(i), cfg);
        if ~isempty(oneValue)
            values = [values; oneValue(:)]; %#ok<AGROW>
        end
    end
    value = values;
    return;
end

fieldCandidates = {};
if isfield(cfg, 'iterationField') && ~isempty(cfg.iterationField)
    fieldCandidates{end + 1} = cfg.iterationField; %#ok<AGROW>
end
if isfield(cfg, 'iterationFields') && ~isempty(cfg.iterationFields)
    fieldCandidates = [fieldCandidates, cfg.iterationFields(:)']; %#ok<AGROW>
end

for i = 1:numel(fieldCandidates)
    fieldName = find_field_name(extra, fieldCandidates{i});
    if isempty(fieldName)
        continue;
    end

    value = extract_iteration_value(extra.(fieldName), cfg);
    if ~isempty(value)
        return;
    end
end
end

function fieldName = find_field_name(S, targetName)
fieldName = '';
names = fieldnames(S);
matchIdx = find(strcmpi(names, targetName), 1);
if ~isempty(matchIdx)
    fieldName = names{matchIdx};
end
end

function write_txt_row(fid, row)
for i = 1:numel(row)
    if i > 1
        fprintf(fid, '\t');
    end
    fprintf(fid, '%s', cell_to_text(row{i}));
end
fprintf(fid, '\n');
end

function txt = cell_to_text(value)
if isnumeric(value) || islogical(value)
    if isscalar(value)
        txt = sprintf('%.10g', value);
    else
        txt = mat2str(value);
    end
elseif ischar(value)
    txt = value;
else
    try
        txt = char(value);
    catch
        txt = '<unsupported>';
    end
end
end

function name = safe_name(name)
badChars = {'\', '/', ':', '*', '?', '"', '<', '>', '|', '.'};
for i = 1:numel(badChars)
    name = strrep(name, badChars{i}, '_');
end
end
