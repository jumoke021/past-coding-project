function [outputFile] = processDataFileGluR1(logFileDict,theXLFile,sheetName)
% Function create a csv file with new columns populated based on the
% contents of a log file
%
% Notes: 1. this is correct assuming GLUR1 experiment only
%        2. field and well summary sheets are handles slightly differently
%        because the well column labeling is different and there is a blank
%        row in the well sheets that is not present in the field sheets
%
% v1.0    Gavornik    11 Jan 2011
% v1.1    Gavornik    19 Jan 2011 - Update to use xlswrite on PCs
% v1.2    Gavornik    21 Jan 2011 - Look for and include data from co-
%                                   localization files
% v1.3    Gavornik    3 Feb 2011  - Fix inf write error, change outfile
%                                   name to include plate etc. info
% v1.4    Gavornik    17 Feb 2011 - Look for and include data from NeuN
%                                   cFos files
% v1.4.1  Gavornik    22 Feb 2011 - Update well cFos to account for blank
%                                   row

% Parse the file path and create the name of a new output file
[pathParts,iDirMrk] = regexp(theXLFile,'/','split','start');
oldFileName = pathParts{end};
if ispc
    extension = 'xls';
elseif ismac
    extension = 'csv';
end
if strfind(lower(sheetName),'field')
    newFileName = sprintf('%s_field.%s',oldFileName(1:end-4),extension);
    wellType = false;
elseif strfind(lower(sheetName),'well')
    newFileName = sprintf('%s_well.%s',oldFileName(1:end-4),extension);
    wellType = true;
else
    error('processDataFileGLUR1: neither well nor field found in sheet name');
end
plate = logFileDict('Plate No.');
marker = logFileDict('Markers');
div = logFileDict('DIV');
cellType = logFileDict('Cell type');
outputFile = sprintf('%s%s%s%s%i%s',theXLFile(1:iDirMrk(end)),plate,marker,cellType,div,newFileName);

% Determine if there is a colocalization file and, if so, use it
dirPath = theXLFile(1:iDirMrk(end));
files = dir(dirPath);
coLocfileFound = false;
neuNfileFound = false;
for ii = 1:numel(files)
    aFile = files(ii).name;
    if ~isempty(regexp(aFile,'Co-localization.*xls','once','ignorecase'))
        if coLocfileFound
            warning('processDataFileGluR1: multiple coLocalization files found in %s',dirPath); %#ok<WNTAG>
        end
        coLocfileFound = true;
        coLocFile = [dirPath aFile];
    end
    if ~isempty(regexp(aFile,'NeuN cFos.*xls','once','ignorecase'))
        if neuNfileFound
            warning('processDataFileGluR1: multiple NeuN files found in %s',dirPath); %#ok<WNTAG>
        end
        neuNfileFound = true;
        neuNFile = [dirPath aFile];
    end
    
end
colocalize = coLocfileFound;
neuN = neuNfileFound;

% Open the xls files and add new colums with header labels - note:
% colocalize files have different sheet names than Synap4 and NeuN cFos
% files so handle differently
if ismac
    warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
end
[~,~,data] = xlsread(theXLFile,sheetName);
if colocalize
    if wellType
        coLocSheetName = 'Well summary';
    else
        coLocSheetName = 'Block summary';
    end
    [~,~,coLocData] = xlsread(coLocFile,coLocSheetName);
end
if neuN
    [~,~,neuNData] = xlsread(neuNFile,sheetName);
    nNeuNCols = 16;
end

if ismac
    warning('on','MATLAB:xlsread:ActiveX'); % restore ActiveX warning
end

% First two rows are headers, combine together to make single header
header1 = data(1,:);
header2 = data(2,:);
cHeader = cell(1,numel(header1));
for ii = 1:numel(header1)
    cHeader{ii} = sprintf('%s %s',header1{ii},header2{ii});
end

% First four rows are header in a colocalization file - this assumes coloc
% files are always the same and always like the example given to me.  If
% these assumptions are not correct, this logic may need to change
if colocalize
   coLocCol1 = 3;
   coLocCol2 = 4;
   coLocCol3 = 5;
   coLocHeader = cell(1,3);
   coLocHeader{1} = ...
       cell2mat([coLocData(1,coLocCol1) ' ' coLocData(3,coLocCol1)]);
   coLocHeader{2} = ...
       cell2mat([coLocData(1,coLocCol2) ' ' coLocData(3,coLocCol2)]);
   coLocHeader{3} = ...
       cell2mat([coLocData(1,coLocCol3) ' ' coLocData(3,coLocCol3)]);
end

% Read neuN headers using the same technique as Synap4 file but with
% different starting local
if neuN
    if wellType
        neuNStartCol = 3;
    else
        neuNStartCol = 2;
    end
    header1 = neuNData(1,neuNStartCol:end);
    header2 = neuNData(2,neuNStartCol:end);
    neuNHeader = cell(1,numel(header1));
    for ii = 1:numel(header1)
        neuNHeader{ii} = sprintf('%s %s',header1{ii},header2{ii});
    end
end


% Find the column number for data of interest
for col = 1:numel(cHeader)
    hv = cHeader{col}; % header value
    % fprintf('%i %s\n',col,hv);
    if strcmp(hv,'Neuronal Phenotype Neuron (n)')
        cNeuronNumber = col; % column with dependent data
    end
    if strcmp(hv,'Organelles 1 Count')
        cOrg1Count = col; % column with dependent data
    end
    if strcmp(hv,'Organelles 2 Count')
        cOrg2Count = col; % column with dependent data
    end
    if strcmp(hv,'NaN Cell Count')
        cCellCount = col; % column with dependent data
    end
    if strcmp(hv,'Organelles 1 Intensity')
        cOrgInt1 = col;
    end
    if strcmp(hv,'Organelles 2 Intensity')
        cOrgInt2 = col;
    end
end

% Resize and create new column header labels
[rows,cols] = size(data);
if wellType % remove blank row
    newdata = cell(rows-1,cols+6);
    newdata(1:2,1:cols) = data(1:2,1:cols);
    newdata(3:end,1:cols) = data(4:end,1:cols);
else
    newdata = cell(rows,cols+6);
    newdata(1:rows,1:cols) = data;
end
newHeaders = {'Mouse' 'Plate' 'Marker' 'Genotype' 'DIV' 'Cell Type'...
    'Trt' 'Total Puncta 1' 'Total Puncta 2' 'Puncta 1 per Neuron'...
    'Puncta 2 per Neuron' 'Total Puncta Intensity 1' 'Total Puncta Intensity 2'...
    'Puncta Intensity Per Neuron 1' 'Puncta Intensity Per Neuron 2'};
if colocalize
    newHeaders = [newHeaders coLocHeader];
end
if neuN
    newHeaders = [newHeaders neuNHeader];
end

newdata(2,cols+1:cols+numel(newHeaders)) = newHeaders;

% Define ranges for the left or right plate designations
left_cols = 1:6;
right_cols = 7:12;

% Fill in new headers for each row based on the contents of the logFileDict
% headers = newdata(2,:);
if wellType
    startRow = 4;
else
    startRow = 3;
end
for row = startRow:rows
    theRow = data(row,:);
    
    % Process the row information to determine plate column and row
    % number information
    theField = theRow{1}; % assume this is always the first row
    iDash = strfind(theField,'- ');
    iParen = strfind(theField,'(');
    if isempty(iParen)
        colNumber = ...
            str2double(theField(iDash+1:end));
    else
        colNumber = ...
            str2double(theField(iDash+1:iParen-1));
    end
    rowLetter = theField(1:iDash-2); % Assume there is always a single letter
    
    % Figure out whether we are on the right or left of the plate based on
    % colNumber
    if sum(left_cols == colNumber)
        plateSide = 'left';
    elseif sum(right_cols == colNumber)
        plateSide = 'right';
    else
        error('processdataFile: unknown plateSide for colNumber %i',colNumber);
    end
    
    % Process gene type
    genoTypeStr = logFileDict('gtype');
    genoTypes = regexp(genoTypeStr,'/','split');
    if strcmp(plateSide,'left')
        genoType = genoTypes{1};
    elseif strcmp(plateSide,'right')
        genoType = genoTypes{2};
    else
        error('processdataFile: genoType problem');
    end
    
    % Process plate, DIV, Cell Type each of which is simply copied from the
    % log file value
    plate = logFileDict('Plate No.');
    DIV = logFileDict('DIV');
    CellType = logFileDict('Cell type');
    
    % Process the marker - this is experiment specific code
    % for GluR1Synap4, assume all are 'GluR1'
    switch colNumber
        case {2 3 4 5 6 7 8 9 10 11}
            marker = 'SV2GluR1';
    end
    
    % Process the treatments
    treatments = logFileDict('Treatments');
    switch treatments
        case 'activity'
            switch colNumber
                case {4 9}
                    treatment = 'Veh';
                case{3 10}
                    treatment = 'Bic';
                case{5 8}
                    treatment = 'TTX+APV';
                case {6 7}
                    treatment = '-';
                case{2 11}
                    switch rowLetter
                        case {'B' 'C' 'D'}
                            treatment = 'CTL';
                        case {'E' 'F' 'G'}
                            treatment = 'NMDA';
                    end
            end
        otherwise
            treatment = [];
    end
    
    % Process puncta counts
    cellCount = theRow{cCellCount};
    punct1 = theRow{cOrg1Count} * cellCount;
    punct2 = theRow{cOrg2Count} * cellCount;
    neuronN = theRow{cNeuronNumber};
    punct1PerNeuron = punct1/neuronN;
    punct2PerNeuron = punct2/neuronN;
    totalInt1 = theRow{cOrgInt1} * cellCount;
    totalInt2 = theRow{cOrgInt2} * cellCount;
    
    % Get the mouse identifier from the log file
    mouseNumberStr = logFileDict('Mouse Numbers');
    mouseIDs = regexp(mouseNumberStr,'/','split');
    if strcmp(plateSide,'left')
        mouseNumber = mouseIDs{1};
    elseif strcmp(plateSide,'right')
        mouseNumber = mouseIDs{2};
    else
        error('processdataFile: mouseNumber problem');
    end
    
    if wellType
        offset = -1;
    else
        offset = 0;
    end
    
    % save processed data into the new columns
    newdata{row+offset,cols + 1} = mouseNumber;
    newdata{row+offset,cols + 2} = plate;
    newdata{row+offset,cols + 3} = marker;
    newdata{row+offset,cols + 4} = genoType;
    newdata{row+offset,cols + 5} = DIV;
    newdata{row+offset,cols + 6} = CellType;
    newdata{row+offset,cols + 7} = treatment;
    newdata{row+offset,cols + 8} = punct1;
    newdata{row+offset,cols + 9} = punct2;
    newdata{row+offset,cols + 10} = punct1PerNeuron;
    newdata{row+offset,cols + 11} = punct2PerNeuron;
    newdata{row+offset,cols + 12} = totalInt1;
    newdata{row+offset,cols + 13} = totalInt2;
    newdata{row+offset,cols + 14} = totalInt1/neuronN;
    newdata{row+offset,cols + 15} = totalInt2/neuronN;
    
    if colocalize
        coLocRow = row+offset + 2; % plus 2 to account for extra headers in coloc file
        newdata{row+offset,cols + 16} = coLocData{coLocRow,coLocCol1};
        newdata{row+offset,cols + 17} = coLocData{coLocRow,coLocCol2};
        newdata{row+offset,cols + 18} = coLocData{coLocRow,coLocCol3};
    end
    
    if neuN
        startCol = 19;
        for colN = 0:nNeuNCols-1
            % Note: +wellType to account for extra blank row in well
            % sheet
            newdata{row+offset,cols + startCol + colN} = ...
                neuNData{row+offset+wellType,neuNStartCol+colN};
        end
    end
    
    % xlswrite saves inf as 65535, correct this by leaving the cell empty
    if neuronN == 0
        newdata{row+offset,cols + 10} = [];
        newdata{row+offset,cols + 11} = [];
        newdata{row+offset,cols + 14} = [];
        newdata{row+offset,cols + 15} = [];
    end
        
end

if ispc
    % Write file results to a xls file
    warning('off','MATLAB:xlswrite:AddSheet'); % supress sheet warning
    [success,message]=xlswrite(outputFile,newdata,'AutoCreate');
    warning('on','MATLAB:xlswrite:AddSheet');
    if ~success
        fprintf('%s\n',message.message);
        warning('processDataFileSynap4: xlswrite failed for %s',theXLFile); %#ok<WNTAG>
    end
elseif ismac
    % Write out results to a csv file
    csvCellWriter(outputFile,newdata);
end
