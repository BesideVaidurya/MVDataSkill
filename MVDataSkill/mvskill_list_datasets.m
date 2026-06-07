function dataList = mvskill_list_datasets(dataPath)
%MVSKILL_LIST_DATASETS Return all .mat dataset file names in a folder.

if nargin < 1 || isempty(dataPath) || ~exist(dataPath, 'dir')
    error('A valid dataPath is required.');
end

files = dir(fullfile(dataPath, '*.mat'));
dataList = cell(numel(files), 1);
for i = 1:numel(files)
    dataList{i} = files(i).name;
end
dataList = sort(dataList);
end
