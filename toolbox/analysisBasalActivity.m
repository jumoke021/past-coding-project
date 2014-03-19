%% BasalActivity Analysis 

% Based on Jeff Gavornik's code Analysis Demo 

% Automated processsing for Inhib and Activity Plates according to
% cell type and age. Analysis of basal activity and neuronal features of 
% WT and KO cells receiving no treatments ('empty' or '-').
% Compares effects of treatments (Veh, Bic, TTX+APV and CTL,NMDA) in 
% KO vs WT cells for activity plates only. 
% Note : in Inhib Plates Marker is NeuFos, 
%        in Activity Plates Marker is  NeuNFos (extra N)
%
% v1.0   Williams       2/5/2012
% v2.0   Williams       2/21/2012   Changed so that you don't have to
%                                   specify plateTypes. Leave plateTypes as 
%                                   {''} if you want to run data across 
%                                   multiple cohorts. 

%% Select Files and group them according to groups specified in plateType

% selected_files ={''}; % Comment this line out if analyzing data from xls sheets. 
                        % Leave uncommented if using mysql data 
                      
 if ~exist('selected_files','var')
      allFiles = find_xls_files('.');
      FileSelector(allFiles)
 end

%Specify (cell types and age) plates you are processing using xls header

%    plateType = {'H14','H21','C14','C21'};%Use this for Inhib Plates
%    plateType = {'h14','h21','c14','c21'}; % Use this for Activity  Plates
%    plateType = {'h21'};
   plateType = {''};

% Or for MySQL: Specify 'dependent variable table name'then ,'independent
% variable table name'
%    plateType ={'avg_nuclei_area_shape_perimeter',''};
   

  %% Create dataSelectionObject and set dependent and independent variables
    
   dataSelector = dataSelectionObject;

% Set dependent variables to analzye 

%    dependent = {'Percent cFos+ Neurons'};
%    dependent = {'Cell Count'};
%       dependent = {'NeuN Pos (n)','NeuN Pos (%)','Percent cFos+ Neurons'};
%        'Percent cFos+ Neurons (Normalized to Treatment)'};
%     dependent = {'Total Puncta 2 (Normalized to Treatment)'};
%         'Total Puncta 1 (Normalized to Treatment)',
      dependent = {'Total Puncta 2'};
%     dependent = {'Nuclei Count','NeuN+ cells','Apoptotic nuclei',...
%         'BrdU+ cells','BrdU+NeuN+ cells'};
%     dependent = {'NeuN Pos (%)','Apoptotic (%)','BrdU Pos (%)','BrdU Pos Neurons (%)'};
%     dependent = {'Change in Neuron number (from Day 1)',...
%         'Change in Apoptotic nuclei (from Day 1)','Change in BrdU+ cells (from Day 1)',...
%         'Change in BrdU+ neurons (from Day 1)','Change in % Neurons (from Day 1)',...
%         'Change in % Apoptotic Cells (from Day 1)','Change in % BrdU pos cells (from Day 1)',...
%         'Change in % BrdU pos Neurons (from Day 1)'};
%     dependent = {'Co-Localized Overlap Count','Colocalized Puncta Per Neuron'};
%     dependent = {'Cell Count','Neuronal Phenotype Neuron (n)',...
%         'Neuronal Phenotype Non neuronal (n)'};
%     dependent = {'Puncta 2 per Neuron','Puncta 1 per Neuron'};
%         'Puncta 2 per Neuron','Neuronal Phenotype Neuron (n)'
%     'Puncta Intensity Per Neuron 2','Total Puncta Intensity 2'};
%    'Puncta 1 per Neuron','Total Puncta 1','Puncta Intensity Per Neuron 1',...
%      'Total Puncta Intensity 1'};

% For MySQL: Can only call dependent (or independent) variables within one table

%   dependent = {'average_nuclei'};

% Set independent variable to analyze

    dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');
    
% dataSelector.setIndependentVariable('ImageNumber');


%% Automatically Generate Group Pairs

% set name of groups "descriptions"

   descriptions={'WT','WT + CTL','WT + NMDA','WT + Veh','WT + TTXAPV','WT + Bic',...
       'KO','KO + CTL','KO + NMDA','KO + Veh','KO + TTXAPV','KO + Bic'};
%    descriptions ={'WT1','KO1','WT14','KO14',};
%    descriptions ={'WT Surface GluR2','KO Surface GluR2','WT Surface GluR1',...
%        'KO Surface GluR1','WT PSD','KO PSD','WT Gamma','KO Gamma','WT Gephyrin',...
%        'KO Gephyrin'};
%    descriptions ={'WTSyn','KOSyn','WTSV2','KOSV2','WTGAD','KOGAD'};
%    descriptions={'WT','KO'};
%     descriptions={'WTVEH','WTDHPG','WTVEH+med','WTDHPG+med','WTVEH+VEH','WTDHPG+VEH',...
%         'WTVEH+TA','WTDHPG+TA','WTVEH+med+VEH','WTDHPG+med+VEH','WtVEH+med+TA','WtDHPG+med+TA',...
%         'WTNMDA','WTAMPA','WTAMPA+VEH','WTAMPA+TA','KOVEH','DHPG','VEH+med','DHPG+med','VEH+VEH','DHPG+VEH',...
%         'VEH+TA','DHPG+TA','VEH+med+VEH','DHPG+med+VEH','VEH+med+TA','DHPG+med+TA',...
%         'NMDA','AMPA','AMPA+VEH','AMPA+TA'};
%     descriptions= {'B-GluR1','B-GluR2','A-GluR1','A-GluR2'};
  
%Define pairs 

pairs = containers.Map(); 

   pairs('Genotype') = {'WT','KO'};
%    pairs('DIV') = {'<=1','>=14'};
%    pairs('DIV') = {'>=14'};
%    pairs('Marker') = {'NeuFos'};
%    pairs('Marker') = {'SynGluR2','SV2GluR1','SynPSD','GADgamma','GADGeph'};
%    pairs('Marker') = {'SynGluR2|SynPSD|Syn','SV2GluR1','GADgamma|GADGeph|GADGamma'}; 
%    pairs('Trt') = {'-|empty'}; 
   pairs('Trt') = {'-','CTL','NMDA','Veh','TTX+APV','Bic'};
%    pairs('Trt') = {'VEH','DHPG','VEH+med','DHPG+med','VEH+VEH','DHPG+VEH',...
%         'VEH+TA','DHPG+TA','VEH+med+VEH','DHPG+med+VEH','VEH+med+TA','DHPG+med+TA',...
%         'NMDA','AMPA','AMPA+VEH','AMPA+TA'};

% --------MySQL Databse pair defintions ---------%
%     pairs('Genotype') = {'B','A'};
%     pairs('Marker') = {'GluR1','GluR2'};


% Two modes possible in terms of how data will be displayed on the graph:
% alternate (WT,KO,WT..) or noalternate ( WT,WT,KO,KO);
mode = 'noalternate'; %sets order in which groups will be graphed 
%creates Groups
[dataSelector,iteratePair] = createGrpPairs(dataSelector,pairs,descriptions,mode);

%% Pass extracted data to analysis routines

% Set dependent variable and parse selected files for cell type & age
% ONLY if you are processing xls files are the files parse by cell type and
% age defined in plateType

for j =1:length(plateType)
    crossplatePrefix = plateType{j};
    for ndependents=1:length(dependent)     
        % set dependent variable 
        dataSelector.setDependentVariable(dependent{ndependents});  
        
        % separate groups of files according to cell type and age 
        
        % if extracting data from mysql set dataDict here
        if strcmp(selected_files,'') 
            %Name of table that contains linked plate_number,celltype,etc
            %data
            metadata = 'Main_10plates_Synap_v2_Per_Image_ForExportNoBlobs';
            dataDict = extractMysqlDatabase (dataSelector,plateType,metadata);
        end
        
        % if extracting data from xls sheets, separate files according to 
        % cell type and age
        if ~exist('dataDict','var') 
            if ~strcmp('',plateType{j})
                tempFiles = strfind(selected_files,plateType{j});
                for indices = 1:length(tempFiles)
                    if ~isempty(tempFiles{indices})
                        tempFiles{indices}=indices;
                    end
                end
                
                tempFiles = cell2mat(tempFiles); 
                selected_cohorts = selected_files(tempFiles);%
           
            else 
                selected_cohorts = selected_files;
            end
        end
 
    % --------------define filenames for printed graphs ------------------%          
       
    % naming convention: Graphs(or subPlots)/selectionStr/filename 
    % with filename containing fileMarker and plateName labels 
    % Graphs printed from crossplate analysis are named with an extra
    % specification (plateType) 
    
    fileMarker = '';
    selectionStr = sprintf('Trial%s',plateType{j});    
    
    % if extracting xls data use HTS_GroupDataExtract,dataDict will not 
    % exist,at this point in the code, if you are NOT processing mysql data
    if ~exist('dataDict','var') 
        dataDict = HTS_GroupDataExtract(dataSelector,selected_cohorts);
    end
    
    dataDictViewer(dataDict); %view data    
    
    
    % ---------------- subplot specifications ---------------------------%
    % Use to print multiple graphs on one page 
    
   % sets number of columns and rows of graphs per page
    if strcmpi(mode,'alternate')
%         csubplot =length(pairs(iteratePair)); %use these for inplate as
%         the number of rows = number of xls sheets/plates
%         rsubplot = length(selected_cohorts)+1;
        csubplot = 5; %use for crossplate to avoid excess rows
        rsubplot = 1; 
    else 
        % feel free to change this number; columns are calculated based on
        % number of rows;
        rsubplot = 3; 
        csubplot = round(length(selected_cohorts)/rsubplot)+1;
    end

    % --------------------- perform desired analysis ---------------------%
    
    %Last parameter of HTS_*** functions( except for ANOVA) is a cell array
    % {}, it takes two logical values - either true or false eg.{false,false}. 
    % The first logical corresponds to whether you want to save the graphs
    % that are generated. The second logical corresponds to whether you 
    % want to save the statistics that are generated. 
    
    % T-test
    [statsStruct] = HTS_tTest2(dataDict,'crossplate',{true,true}); 

    % ANOVA : only saves stats ( does not have graph to save )
       
    levels = {'Genotype','Trt'}; %specify factors you want to test
    modeltype = [1 0; 0 1;1,1]; % specify interactions to observe
    [statsStruct2]=HTS_ANOVA(dataDict,'crossplate',levels,modeltype,{true}); 
      
    % Distribution
%    statsStruct3 = HTS_distributionTest(dataDict,'inplate',{false,false});
    
    % Regression 
%     statsStruc4 = HTS_regressionCoincidenceTest2(dataDict,'crossplate',{true,true});
        

   end
end   

%% Some more notes:

    %------------------- Mini - Essay on 'modeltype' ANOVA ---------------------%
    % modeltype tells you the main and interaction terms that the ANOVA
    % computes. modeltype takes a matrix, with the same number of elements
    % as levels, i.e., if levels has 2 elements ( like it does above ),
    % modeltype should have two elements per row;
    % To specify what elements the anova should compute use 1 or 0.
    % If levels = {'Genotype','Marker'} and modeltype = [1,1], then the
    % ANOVA would compute the effects of the interaction of factors
    % Genotype and Marker. You can also specify modeltype like this:
    % modeltype = [1,1;1,0;0,1]; (the semicolon within the brackets starts
    % a new row). The above signifies that the anova should compute the
    % p-value for the null hypothesis on the interaction effects of Genotype
    % and Marker, and then the p-values for the null hypothesis for the main 
    % effects of just Genotype and just Marker (separately). Remeber the 
    % effects you are computing depend in part on the levels you define,
    % and the levels you define are based on the grp.pairs that you define.
    %---------------------------------------------------------------------%
    