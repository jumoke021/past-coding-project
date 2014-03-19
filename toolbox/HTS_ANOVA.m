function[statsStruct]= HTS_ANOVA(dataDict,type,levels,modeltype,printToFile,alpha)
%% Performs n-level anova test and applies appropiate specified modeltype

% N-way interaction of the n level test,
% specify groups of the test by 'levels' variable; also returns significant
% pair differences test using the group key descriptions. No graphs - just
% stats
%
% v1.0  Gavornik    3/12/2011
% v1.1  Williams    11/18/2011
% v1.2  Williams    11/22/2011 Create Structure to store columns for ANOVA
%                               test
%                   11/23/2011 Fixed so data is properly labelled on graph
% v1.3              11/24/2011 
% 
% 
if nargin < 5
    printToFile{1} = false; 
end

if nargin < 6
    alpha = 0.05;
end

% Get data from the selector
dataSel = dataDict.dataSelector;
nGroups = dataSel.nGroups;
groupKeys = dataSel.getGroupDescriptions;
fileKeys = dataDict.keys;
nFiles = numel(fileKeys);

fprintf(1,'------------------------------------\n');
fprintf('Dependent Variable: %s\n',dataSel.dependentVariable);

switch lower(type)
    case 'crossplate'
        % combine data from all files into one data set then analyze
        nDataSets = 1;
        combinedData = dataDict('combinedData');
    case 'inplate'
        % analyze data from each file separetely
        nDataSets = nFiles;
    otherwise
        error('HTS_ANOVAtrial: unknown type ''%s''',type);
end
%
statsStruct = struct;
for iData = 1:nDataSets   
    try
        switch lower(type)
            case 'crossplate'
                theDataSet = combinedData;
                if nFiles == 1
                    dataSource = fileKeys{iData};
                else
                    dataSource = 'Multiple Files';
                end
            case 'inplate'
                theDataSet = dataDict(fileKeys{iData});
                dataSource = fileKeys{iData};
        end
     

    %------------------- Perform the analysis---------------------------------%
     % Perform ANOVA (n way analysis of variance) by iterating through groups, 
     % specified by Groups structure. 
     % NOTE: A new naming convention of variables should be adopted.

    % Create structure to hold data which ANOVA is being performed on
    Fmatrix = []; 

    % Specifies maximum groups of anova test
    anovaGroups=cell(1,length(levels));

    for iGrp = 1:nGroups
        grpKey = groupKeys{iGrp}; % get group key 
        depData =theDataSet(grpKey).dependentData;%get dependent

        depData = depData(~isnan(depData)); %remove NaN
        

        % extract group pairs from dataSel object
        grpProperties = dataSel.pairDefinitions(grpKey);

        % add data to perform anova analysis on into Fmatrix
        if isempty(Fmatrix)
            Fmatrix(1,1:length(depData)) = depData;
        else
            Fmatrix(1,end+1:end+length(depData)) = depData;    
        end
        dependentDataSize = length(depData);
        
        % For each data point, create corresponding columns that specify
        % the values grpPair values each data point corresponds to.
        % For example, if the depData contains the values of each
        % NucleiArea: [ 5, 3 , 6, 7], with the first two row as part of 
        % group pair Genotype WT w/Marker NeuN and the last two rows as part
        % of Genotype KO w/Marker NeuN. Then you need to create columns:
        %{ WT;WT;KO;KO;} and {NeuN,NeuN,NeuN,NeuN} in order to pair the data
        % with the respective groups.
       
        for nlevel=1:length(levels)
            for ngrpPairs = 1:length(grpProperties)
                if sum(strcmp(levels{nlevel},grpProperties{ngrpPairs}))
                    anovaGrps = grpProperties{ngrpPairs};
                     tempanovaGroups = cell(dependentDataSize,1);
                     for ndepData = 1:dependentDataSize
                        tempanovaGroups{ndepData}= anovaGrps{2};
                     end  
                     anovaGroups{nlevel}= vertcat(anovaGroups{nlevel},tempanovaGroups);  
                     break;
                end
                
            end
        end
    end 
    %Perform anova analysis, retrieve data, and perform multicompare
    %analysis, and name the column headers returned in multicompare
    %analysis
        if length(levels) == 1
            [~,ANOVAtable,statsStruct.results] = anovan(Fmatrix',anovaGroups,...
                'varnames',levels,'display','on');
            multcompareNames = {'Groups 1& 2';'lower bound of difference';'estimate of difference';'upper bound of difference'};
        else
         [~,ANOVAtable,statsStruct.results] = anovan(Fmatrix',anovaGroups,...
             'varnames',levels,'model',modeltype,'display','on');
         multcompareNames = {'group1';'group2';'lower bound of difference';'estimate of difference';'upper bound of difference'};
        end

        [MC] = multcompare(statsStruct.results,'display','off'); 
       
        MC = num2cell(MC'); % change type 

        % Modify c table so that it is the same lenght as table (returned
        % from the anovan function)
        if length(multcompareNames) < size(ANOVAtable(:,1),1)
            for ii = 1:(size(ANOVAtable(:,1),1) - length(multcompareNames))
                multcompareNames{end+ii} = '';
                MC{end+ii} = [];   
            end
        elseif length(levels) == 1
            MC = MC(2:end);
        end
        % Join the three tables, table,multcompareNames,c
        ANOVAtable = horzcat(ANOVAtable, multcompareNames,MC); 
        % Make the first row of the first column specify the name of file
        % which the ANOVA was run on
        ANOVAtable{1,1} = dataSource; 
    
%-------------------------ANOVA-Stats Printing ---------------------------- 

% Prints statistics to currentfolder\Statisitics\filename

       % Write statistics to csv files 
        if printToFile{1}
            if exist('Statistics','dir')~=7
                mkdir('Statistics');
            end

            %Set up naming convention for stats.csv files
            parseFile=regexp(dataSource,'/','split');
            [splitstring,matchstring] = regexp(parseFile{end},'[1-9999]\d',...
                'split','match');
            fileMarker = evalin('base', 'fileMarker');
            if isempty(matchstring) 
                filename = sprintf('%s%scrossplate',fileMarker,dataSel.dependentVariable); 
            else
                filename = sprintf('%s%s%s%s',fileMarker,dataSel.dependentVariable,...
                    splitstring{1},matchstring{1});
            end         
                
            %print to csv
            wbkName = sprintf('./Statistics/%s-ANOVAStats.csv',filename);
            fprintf('You are saving ANOVA stats for file %s\n',dataSource);
            csvCellWriter(wbkName,ANOVAtable);
        end

    catch ME
        warning('HTS_ANOVA: failed for data source ''%s''',dataSource); %#ok<WNTAG>
        fprintf('Error report:\n%s\n',getReport(ME));
    end

end








      
    


      
        
           
            
       