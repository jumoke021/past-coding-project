% Script to read XLS file, parse the contents, recombine, run stats
% and export the data to csv files for Asha's High Throughput Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Changed Feb 5 2012 so that Asha can see how the processDataFileNeuNFos
% function works 
% Changed    2012 to include createPlateMap function that creates platemap
% to be read by Broad Institute Cell Profiler Data

%%
% This cell assumes that the current directory contains the log file
% specified below.  It will read the specified sheet from the logfile
% spreadsheet and package it in a data dictionary that is key-value 
% indexed using the Plate Time value from the log file
% logFile = 'LDDN6log3.xls'; % Change as needed
% sheet = 'log6'; % specify which sheets to use

logFile = 'LDDN7.xls'; % Change as needed
sheet = 'LDDN7'; % specify which sheets to use
logFileDict = readLogFile(logFile,sheet);


%%
% This cell assume that the current directory contains a folder called
% 'Raw Images'. It will find all of the xls files that are contained in 
% sub directories below 'Raw Images' and allow the user to verify which to
% include in the subsequent processing
allFiles = find_xls_files('.');
% allFiles = find_xls_files('Raw Images');
%   allFiles = find_xls_files('Repeat');
% allFiles = find_xls_files('/Volumes/My Passport/Asha/HTS/LDDN/Raw Images/121810');

% Note: code execution will pause upon evokation of the FileSelector
% function until the makes a selection from the gui.  After selection is
% complete, there will be a variable in the base workspace called
% 'selected_files'
FileSelector(allFiles)

%%
% This cell will iterate over all selected files writing them out to a csv
% file with data added from the log file

for iFile = 1:numel(selected_files)
    theFile = selected_files{iFile};
    
    iDirMrk = strfind(theFile,'/'); % location of / within the file string
    keyValue = theFile(iDirMrk(end-1)+1:iDirMrk(end)-1);
    fieldOutputFiles = {};
    wellOutputFiles = {};
   
    if logFileDict.isKey(keyValue)
        try
            ind = strfind(theFile,'/');
       fprintf('Processing %s\n',theFile(iDirMrk(end-1)+1:end));
            wellOutputFiles{end+1} = processDataFileGluR2Internalization(logFileDict(keyValue),theFile,'Summary by wells');
            fieldOutputFiles{end+1} = processDataFileGluR2Internalization(logFileDict(keyValue),theFile,'Summary by fields');
             
        % fieldOutputFiles{end+1} = processDataFileRepeatSwitch(logFileDict(keyValue),theFile,'Summary by fields');
        % wellOutputFiles{end+1} = processDataFileRepeatSwitch(logFileDict(keyValue),theFile,'Summary by wells');
        % fieldOutputFiles{end+1} = processDataFileSynap2(logFileDict(keyValue),theFile,'Summary by fields');
        % wellOutputFiles{end+1} = processDataFileSynap2(logFileDict(keyValue),theFile,'Summary by wells');
%                 
%         % if using unprocessed files 
%         [platemap] = createPlateMap(wellOutputFiles{end},logFileDict,keyValue); 

        catch ME1
            fprintf('Error report:\n%s\n',getReport(ME1));
            warning('Failed to process file: ''%s''\n',...
                theFile(iDirMrk(end-1)+1:end)); %#ok<WNTAG>
        end
    else
        warning('%s is not a key in the logFileDict',keyValue); %#ok<WNTAG>
    end
    
% [platemap] = createPlateMapFile(theFile,logFileDict);%if using processed file

end
%%
% This cell calls the general math function and currently calculates
% NeuN Pos(n) and NeuN Pos(%) and Real NeuN Pos(%)
% Please type " clear selected files " ( without the quotation marks
% before you run this code. NOTE: To run only this section the code press
% CTL+Enter. 

% Define functionhandles
addition= @(x,y) x+y; % mathematical operation you want to perform 
division= @(x,y) 100*x./y;
ndivision = @(x,y) x./y;

% Calculate # of neurons ( NeuN Pos(n))
% excelmath('New Decision Tree NeuN +,cFos+ (n)&New Decision Tree NeuN +, cFos- (n)',...    
%     'NeuN Pos (n)',addition);

% % Calculate percentage of cells that are neurons 
%excelmath('NeuN Pos (n)&NaN Cell Count','NeuN Pos (%)',division) 
%  
% % % Calculates the % of neurons that are cFos active
%excelmath('New Decision Tree NeuN +,cFos+ (n)&NeuN Pos (n)','Percent cFos+ Neurons',...
%    division);  

% % Normalize treatment values for cFos activity 
excelmath({'WT,N4&N8','KO,N4&N8'},...
    'BrdU+ cells(Normalized to Age)','BrdU+ cells',ndivision,'across');

% % Normalized to wild type average value for cFos activity (Inhib Plates);
% excelmath({'SynGluR2,WT&KO','GADgamma,WT&KO','SynPSD,WT&KO','SV2GluR1,WT&KO',...
%     'GADGeph,WT&KO'},'Total Puncta 2 (Normalized to WT)','Total Puncta 2',ndivision,'across');
% % 
%% Jeff's old code - Not using
% This cell will re-read the output files generated above and plot
% regression lines for the data - note: must be in the directory with the
% files

%params.dep_var_header = 'Total Puncta 1';
%params.ind_var_header = 'Neuron (n)';
%params.group_designation = 'Genotype';
%params.other_selections = {'Marker=SynPSD' 'Trt=CTL'};

%dataFiles = {'Synap 4_field.xls' 'Synap 4_well.xls'};

%dataDicts = HTS_GroupDataExtract(params,dataFiles);
%HTS_LinearRegression(dataDicts);

% params.dep_var_header = 'Total Puncta';
% params.ind_var_header = 'Neuronal (n)';
% params.group_designation = 'Genotype';
% params.other_selections = {'Marker=GluR1'};
% 
% dataFiles = {'Synap 2_field.xls' 'Synap 2_well.xls'};
% 
% dataDicts = HTS_GroupDataExtract(params,dataFiles);
% HTS_LinearRegression(dataDicts);

