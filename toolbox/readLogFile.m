function tableDictionary = readLogFile(logFileName,sheetName)
% Function to read the one of Asha's HTC log files and package the
% contents and header in a dictionary for key-value indexing
%
% Notes: 1. use of '/' or '\' in directory names is not advised because 
%           regexp parsing routines might match against them
%
%   v1.0    J.Gavornik    8 Jan 2011
%   v1.1    Gavornik      19 Jan 2011 - Updated for machine specific
%                                       behavior

if nargin<2
    error('readLogFile: must pass both logFileName and sheetName');
end

if ismac
    warning('off','MATLAB:xlsread:ActiveX'); % suppress ActiveX warning
end

[~,~,data] = xlsread(logFileName,sheetName);
data = data(:,1:22);
headerLabels = data(1,:);

% Find the 'Plate Time' column.  This will be used to index into the
% tableDictionary
ptc = strmatch('plate time',lower(headerLabels));

% Create the main dictionary, populate with sub-dictionaries for each row
% in the table
tableDictionary = containers.Map;
for row = 2:size(data,1) % start with row 2 to skip the header 
    newDict = containers.Map;
    if isa(data{row,ptc},'double')
        theMainKey = sprintf('%i',data{row,ptc});
    else
        theMainKey = data{row,ptc};
    end
%     Handle cases where the plate time column is empty
    if isempty(theMainKey) || strcmpi(theMainKey,'nan')
        theMainKey = sprintf('EmptyKey%03i',round(100*rand));
    end
%     fprintf('theMainKey = %s\n',theMainKey)
    for col = 1:size(data,2)
        if col ~= ptc
            theSubKey = headerLabels{col};
%              fprintf('\ttheSuSbKey = %s\n',theSubKey)
            theData = data{row,col}; 
            newDict(theSubKey) = theData;
        end
    end

    tableDictionary(theMainKey) = newDict;
    
end

if ismac
    warning('on','MATLAB:xlsread:ActiveX'); % restore ActiveX warning
end