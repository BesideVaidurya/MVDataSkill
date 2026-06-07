function info = mvskill_parse_params_from_demo(demoFile)
%MVSKILL_PARSE_PARAMS_FROM_DEMO Extract dataset hyperparameters from Demo.m.
%
% It parses lines such as:
%   load('BBC','label','data'); alpha=0.1; lambda=0.01; beta=0.1;
% and also commented alternatives such as:
%   %load('ORL_mtv','gt','X'); alpha=0.001; lambda=0.01;

if nargin < 1 || isempty(demoFile) || ~exist(demoFile, 'file')
    error('A valid MATLAB demo file is required.');
end

text = fileread(demoFile);
lines = regexp(text, '\r\n|\n|\r', 'split');

info = struct();
info.demoFile = demoFile;
info.datasetParams = struct();
info.activeParams = struct();
info.records = struct('dataset', {}, 'key', {}, 'params', {}, ...
    'lineNumber', {}, 'isCommented', {}, 'line', {});
info.paramNames = {};

for i = 1:numel(lines)
    rawLine = lines{i};
    [line, isCommented] = strip_comment_prefix(rawLine);

    if isempty(regexp(line, 'load\s*\(', 'once'))
        continue;
    end

    datasetName = parse_load_dataset(line);
    if isempty(datasetName)
        continue;
    end

    params = parse_numeric_assignments(line);
    if isempty(fieldnames(params))
        continue;
    end

    key = mvskill_dataset_key(datasetName);
    info.datasetParams.(key) = params;
    info.paramNames = union_stable(info.paramNames, fieldnames(params)');

    rec = struct();
    rec.dataset = datasetName;
    rec.key = key;
    rec.params = params;
    rec.lineNumber = i;
    rec.isCommented = isCommented;
    rec.line = rawLine;
    info.records(end + 1) = rec; %#ok<AGROW>

    if ~isCommented && isempty(fieldnames(info.activeParams))
        info.activeParams = params;
    end
end
end

function [line, isCommented] = strip_comment_prefix(rawLine)
line = strtrim(rawLine);
isCommented = false;

while ~isempty(line) && line(1) == '%'
    isCommented = true;
    line = strtrim(line(2:end));
end
end

function datasetName = parse_load_dataset(line)
datasetName = '';
token = regexp(line, 'load\s*\(\s*[''"]([^''"]+)[''"]', 'tokens', 'once');
if ~isempty(token)
    [~, datasetName, ~] = fileparts(token{1});
end
end

function params = parse_numeric_assignments(line)
params = struct();
tokens = regexp(line, '(^|;)\s*([A-Za-z]\w*)\s*=\s*([^;]+)', 'tokens');

for i = 1:numel(tokens)
    name = tokens{i}{2};
    valueText = strtrim(tokens{i}{3});
    percentPos = strfind(valueText, '%');
    if ~isempty(percentPos)
        valueText = strtrim(valueText(1:percentPos(1) - 1));
    end

    [ok, value] = parse_numeric_value(valueText);
    if ok
        params.(name) = value;
    end
end
end

function [ok, value] = parse_numeric_value(valueText)
ok = false;
value = [];

if isempty(valueText)
    return;
end

% Keep eval constrained to scalar numeric expressions such as 0.01, 1e-3, or 10^-2.
if isempty(regexp(valueText, '^[0-9eE\+\-\*\/\.\(\)\^\s]+$', 'once'))
    return;
end

try
    value = eval(valueText); %#ok<EVLDIR>
    ok = isnumeric(value) && isscalar(value) && isfinite(value);
catch
    ok = false;
    value = [];
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
