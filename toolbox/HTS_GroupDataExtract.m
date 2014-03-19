function returnDict = HTS_GroupDataExtract(dataSelector,dataFiles)
% returnDict = HTS_GroupDataExtract(dataSelector,dataFiles)
%
% Function to pull data specified by params out of the xls files specified
% in dataFiles cell array using the dataSelector which is an instance of a
% dataSelectionObject.  See analysisDemo.m for an example of how to use
% define groupings, extract data from selected files and pass that data to
% analysis routines.
%
% Note: this function will look for a sheet called 'Corrected' if it
% exists, otherwise it will use 'AutoCreate'.  It will throw warnings of
% either the dependent or independent variable is not found in any xls
% file.
%
% v1.0    J.Gavornik    28 Feb 2011
% v1.1    Williams      11 Jan 2012  Now checks if excel file contains 
%                                    'Math' sheet to use for data
%                                    processing
%#ok<*AGROW>

headerRows = 2;

if ~iscell(dataFiles)
    dataFiles = {dataFiles};
end

% Create a dictionary that will be used to hold and return the extracted
% data
returnDict = HTS_dataDict(dataSelector);

% Loop over files
nFiles = numel(dataFiles);
for iFile = 1:nFiles
    try
        % Start with fresh selction indici for all groups
        dataSelector.clearAllIndici;
        
        % Get the names of the sheets in the file
        dataFile = dataFiles{iFile};
        [a,sheetNames] = xlsfinfo(dataFile);
        if ~strcmp(a,'Microsoft Excel Spreadsheet')
            error('HTS_GroupDataExtract: %s is not an excel spreadsheet',dataFile);
        end
        if sum(strcmp(sheetNames,'Math'))
            sheetName = 'Math';
        elseif sum(strcmp(sheetNames,'Corrected'))
            sheetName = 'Corrected';
        elseif sum(strcmp(sheetNames,'AutoCreate'))
            sheetName = 'AutoCreate';
        else
            error('HTS_GroupDataExtract: %s does not have a recognized sheet name',dataFile);
        end
   
        fprintf('HTS_GroupDataExtract: using sheet %s for %s\n',sheetName,dataFile)
        
        % Read the data from the file
        warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
        [~,~,data] = xlsread(dataFile,sheetName);
        warning('on','MATLAB:xlsread:ActiveX'); % restore ActiveX warning
        header = data(1:headerRows,:);
        data = data(headerRows+1:end,:);
        
        % Look at the header to figure out which columns hold the relevant
        % data and to find the indici into the data for each group
        for col = 1:size(header,2)
            % Get and collapse the header column ignoring NaN values
            headerCol = header(:,col);
            headerStr = '';
            for row = 1:headerRows
                if ~isnan(headerCol{row})
                    headerStr = sprintf('%s %s',headerStr,headerCol{row});
                end
            end
            headerStr_ = strrep(headerStr,' ','');
            if strcmp(headerStr_,...
                    strrep(dataSelector.dependentVariable,' ',''))
                dependentDataValues = data(:,col);
            elseif strcmp(headerStr_,...
                    strrep(dataSelector.independentVariable,' ',''))
                independentDataValues = data(:,col);
            end
            % Pass each column to the dataSelector which will update
            % selection indici based on the data contents and groupDefs
            dataSelector.findValidIndiciFromDataColumn(headerStr,data(:,col));
        end
        
        % Check to make sure that all of the header values were found in
        % the file
        if ~exist('dependentDataValues','var')
            warning('HTS_GroupDataExtract: dependent variable not found in %s',dataFile);
        end
        if ~exist('independentDataValues','var')
            warning('HTS_GroupDataExtract: independent variable not found in %s',dataFile);
        end
        
        % Extract the data for each group and put into the dictionary
        returnDict(dataFile) = dataSelector.extractDataFromGroups(...
            dependentDataValues,independentDataValues);
        
        
    catch ME
        warning('HTS_GroupDataExtract: failed for file %i (%s)',iFile,dataFiles{iFile}); %#ok<WNTAG>
        fprintf('Error report:\n%s\n',getReport(ME));
    end
    
end

% If there are multiple files, make a combined data set and add it to the
% dictionary as well
if nFiles > 1
    % Get data from the selector
    nGroups = dataSelector.nGroups;
    groupKeys = dataSelector.getGroupDescriptions;
    % Create the combined group
    combinedData = containers.Map;
    tmpStruct.dependentData = [];
    tmpStruct.independentData = [];
    for iGrp = 1:nGroups
        combinedData(groupKeys{iGrp}) = tmpStruct;
    end
    for iFile = 1:nFiles
        fprintf('the key = %s\n',dataFiles{iFile});
        try
            fileData = returnDict(dataFiles{iFile});
            for iGrp = 1:nGroups
                grpKey = groupKeys{iGrp};
                combDepData = combinedData(grpKey).dependentData;
                fileDepData = fileData(grpKey).dependentData;
                tmpStruct.dependentData = [combDepData(:)' fileDepData(:)'];
                combIndData = combinedData(grpKey).independentData;
                fileIndData = fileData(grpKey).independentData;
                tmpStruct.independentData = [combIndData(:)' fileIndData(:)'];
                combinedData(grpKey) = tmpStruct;
            end
        catch ME
            warning('HTS_GroupDataExtract: data combination failed for file %i (%s)',...
                iFile,dataFiles{iFile}); %#ok<WNTAG>
            fprintf('Error report:\n%s\n',getReport(ME));
        end
    end
    returnDict('combinedData') = combinedData;
end
