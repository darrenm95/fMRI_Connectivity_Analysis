% create object to control data import process to extract number of
% participants that fall into each category : yes have tinnitus, no do not
% have tinnitus, excluded from the analysis
function [count_yes, count_no, count_excluded] = importCount(path)

opts = delimitedTextImportOptions("NumVariables", 2);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = ":";

% Specify column names and types
opts.VariableNames = ["Var1", "VarName2"];
opts.SelectedVariableNames = "VarName2";
opts.VariableTypes = ["string", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Var1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Var1", "EmptyFieldRule", "auto");

% Import the data
count = readtable(path, opts);

% Convert to output type
count = table2array(count);

% Clear temporary variables
clear opts

% Split counts
count_yes = count(1);
count_no = count(2);
count_excluded = count(3);