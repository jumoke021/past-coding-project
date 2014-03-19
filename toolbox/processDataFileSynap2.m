function [outputFile] = processDataFileSynap2(logFileDict,theXLFile,sheetName)
% Function create a csv file with new columns populated based on the
% contents of a log file
%
% Notes: 1. this is correct assuming SYNAP2 experiment only
%        2. field and well summary sheets are handles slightly differently
%        because the well column labeling is different and there is a blank
%        row in the well sheets that is not present in the field sheets
%
% v1.0    Gavornik    11 Jan 2011
% v1.1    Gavornik    19 Jan 2011 - Update to use xlswrite on PCs
% v1.2    Gavornik    3 Feb 2011  - Fix inf write error, change outfile
%                                   name to include plate etc. info

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
    error('processDataFileSynap2: neither well nor field found in sheet name');
end
plate = logFileDict('Plate No.');
marker = logFileDict('Markers');
div = logFileDict('DIV');
cellType = logFileDict('Cell type');
outputFile = sprintf('%sP%i%s%s%i%s',theXLFile(1:iDirMrk(end)),plate,marker,cellType,div,newFileName);

% Open the xls file and add new colums with header labels
if ispc
    [~,~,data] = xlsread(theXLFile,sheetName);
elseif ismac
    warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
    [~,~,data] = xlsread(theXLFile,sheetName);
    warning('on','MATLAB:xlsread:ActiveX'); % restore ActiveX warning
end

% First two rows are headers, combine together to make single header
header1 = data(1,:);
header2 = data(2,:);
cHeader = cell(1,numel(header1));
for ii = 1:numel(header1)
    cHeader{ii} = sprintf('%s %s',header1{ii},header2{ii});
end

% Find the column number for data of interest
for col = 1:numel(cHeader)
    hv = cHeader{col}; % header value
    % fprintf('%i %s\n',col,hv);
    if strcmp(hv,'Neuronal Phenotype Neuronal (n)')
        cNeuronNumber = col; % column with dependent data
    end
    if strcmp(hv,'Organelles Count')
        cOrgCount = col; % column with dependent data
    end
    if strcmp(hv,'NaN Cell Count')
        cCellCount = col; % column with dependent data
    end
    if strcmp(hv,'Organelles Intensity')
        cOrgInt = col; % column with dependent data
    end
    if strcmp(hv,'Organelles Total Area')
        cOrgArea = col; % column with dependent data
    end
end

% Resize and create new column labels
[rows,cols] = size(data);
if wellType % remove blank row
    newdata = cell(rows-1,cols+6);
    newdata(1:2,1:cols) = data(1:2,1:cols);
    newdata(3:end,1:cols) = data(4:end,1:cols);
else
    newdata = cell(rows,cols+6);
    newdata(1:rows,1:cols) = data;
end
newHeaders = {'Mouse' 'Plate' 'Marker' 'Genotype' 'DIV' 'Cell Type' 'Trt'...
    'Total Puncta'  'Puncta per Neuron' 'Total Puncta Intensity' ...
    'Total Puncta Area' 'Puncta Intensity Per Neuron'...
    'Puncta Area Per Neuron'};
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
    % for synap2
    switch colNumber
        case {2 11}
            marker = 'Spino';
        case{3 10}
            marker = 'Syn';
        case{4 9}
            marker = 'PSD';
        case{5 8}
            marker = 'GluR1';
        case {6 7}
            marker = 'GluR2';
    end

    % Process the treatments
    treatments = logFileDict('Treatments');
    switch rowLetter
        case {'B' 'D' 'F'}
            switch treatments
                case 'M135'
                    treatment = 'MP';
                case 'M246'
                    treatment = 'CTL';
                otherwise
                    treatment = [];
            end
        case {'C' 'E' 'G'}
            switch treatments
                case 'M135'
                    treatment = 'CTL';
                case 'M246'
                    treatment = 'MP';
                otherwise
                    treatment = [];
            end
        otherwise
            warning('processdataFile: something weird with treatment');
            treatment = [];
    end
    
    % Process puncta counts
    cellCount = theRow{cCellCount};
    punct = theRow{cOrgCount} * cellCount;
    neuronN = theRow{cNeuronNumber};
    punctPerNeuron = punct/neuronN;
    totalPunctInt = cellCount * theRow{cOrgInt};
    totalPuntArea = cellCount * theRow{cOrgArea};
    
    
    
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
    newdata{row+offset,cols + 8} = punct;
    newdata{row+offset,cols + 9} = punctPerNeuron;
    newdata{row+offset,cols + 10} = totalPunctInt;
    newdata{row+offset,cols + 11} = totalPuntArea;
    newdata{row+offset,cols + 12} = totalPunctInt / neuronN;
    newdata{row+offset,cols + 13} = totalPuntArea / neuronN;
    
    % xlswrite saves inf as 65535, correct this by leaving the cell empty
    if neuronN == 0
        newdata{row+offset,cols + 9} = [];
        newdata{row+offset,cols + 12} = [];
        newdata{row+offset,cols + 13} = [];
    end
        
end

if ispc
    % Write file results to a xls file
    warning('off','MATLAB:xlswrite:AddSheet'); % supress sheet warning
    [success,message]=xlswrite(outputFile,newdata,'AutoCreate');
    warning('on','MATLAB:xlswrite:AddSheet');
    if ~success
        fprintf('%s\n',message.message);
        warning('processDataFileSynap2: xlswrite failed for %s',theXLFile); %#ok<WNTAG>
    end
elseif ismac
    % Write out results to a csv file
    csvCellWriter(outputFile,newdata);
end
