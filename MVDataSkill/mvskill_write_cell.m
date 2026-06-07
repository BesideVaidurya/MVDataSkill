function mvskill_write_cell(cellData, fileName)
%MVSKILL_WRITE_CELL Save a cell array with MATLAB-version compatibility.

if exist('writecell', 'file') == 2 || exist('writecell', 'builtin') == 5
    writecell(cellData, fileName);
elseif exist('xlswrite', 'file') == 2
    xlswrite(fileName, cellData);
else
    warning('No writecell/xlswrite support was found. Skip xlsx file: %s', fileName);
end
end
