function [outputFile] = processDataFileNeuNFos(logFileDict,theXLFile,sheetName)
% Function create a csv file with new columns populated based on the
% contents of a log file
%
% Notes: 1. this is correct assuming NeuNFos experiment only
%        
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
% v1.4.2  Williams    30 Nov 2011   Added function NeuNFos which adds math
%                                   sheet to processed excel file
% v1.4.3  Williams    26 Dec 2011 - Updated sheet to process only NeuNFos
%                                   data and removed function for math
%
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
    error('processDataFileNeuNFos: neither well nor field found in sheet name');
end
plate = logFileDict('Plate No.');
marker = logFileDict('Markers');
div = logFileDict('DIV');
cellType = logFileDict('Cell type');
outputFile = sprintf('%s%s%s%s%i%s',theXLFile(1:iDirMrk(end)),plate,marker,cellType,div,newFileName);
%outputFile = sprintf('%s%s%s%i%s',plate,marker,cellType,div,newFileName);

if ismac
    warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
end
[~,~,data] = xlsread(theXLFile,sheetName);

if ismac
    warning('on','MATLAB:xlsread:ActiveX'); % restore ActiveX warning
end


% First two rows are headers, combine together to make single header
header1 = data(1,:);
header2 = data(2,:);
cHeader = cell(1,numel(header1));
% 
for ii = 1:numel(header1)
     %first row contains empty elements which are returned as NaN
    cHeader{ii} = sprintf('%s %s',header1{ii},header2{ii});
    %ADD CODE TO DIFFERENTIATE BETWEEN TWO ORGANELLE INTENSITIES 
end

% Resize and create new column header labels
[rows,cols] = size(data);


if wellType % remove blank column and row
    newdata =cell(rows-1,cols);
    %create new headers with names on a single row
    newdata(2,1:cols-1) = cHeader(1,[1,3:end]); 
    newdata(3:end,1:cols-1)=data(4:end,[1,3:end]);
else
    newdata=cell(rows,cols);
    %create new headers with names on a single row
    newdata(2,1:cols)=cHeader;
    newdata(3:rows,1:cols)=data(3:end,1:cols);
end

% Need something in row 1 so that Jeffs code can call processed data sheet
newdata{1,1}='%'; 
newHeaders = {'Mouse' 'Plate' 'Marker' 'Genotype' 'DIV' 'Cell Type'...
    'Trt'};

if wellType
    newdata(2,cols:cols+numel(newHeaders)-1)=newHeaders;
else
    newdata(2,cols+1:cols+numel(newHeaders))=newHeaders;
end



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
    % for GluR1Synap4, assume all are 'NeuNFos marker'
    switch colNumber
        case {2 3 4 5 6 7 8 9 10 11}
            marker = 'NeuNFos';
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
    newdata{row+ offset,cols + offset+1} = mouseNumber;
    newdata{row+ offset,cols +offset + 2} = plate;
    newdata{row+ offset,cols +offset + 3} = marker;
    newdata{row+ offset,cols +offset + 4} = genoType;
    newdata{row+ offset,cols +offset + 5} = DIV;
    newdata{row+ offset,cols +offset + 6} = CellType;
    newdata{row+ offset,cols +offset  +7} = treatment;
  
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

end

