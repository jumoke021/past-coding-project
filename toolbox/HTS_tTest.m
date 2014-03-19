function [statsStruct] = HTS_tTest(dataDict,type,printToFile,alpha)

% Draws bar plots and performs pairwise t-test between each group data
%
% v1.0  Gavornik    3/12/2011
% v1.1  Williams    2/12/2012 Changed way files were named 


if nargin < 2
    type = 'CrossPlate';
end

if nargin < 3
    printToFile{1} = false;
    printToFile{2}=false;
end

if nargin < 4
    alpha = 0.05;
end

% Get data from the selector
dataSel = dataDict.dataSelector;
nGroups = dataSel.nGroups;
groupKeys = dataSel.getGroupDescriptions;
fileKeys = dataDict.keys;
nFiles = numel(fileKeys);
plotColors = dataSel.getPlotColors;

% Create a structure that will hold the statistics
statsStruct = struct;
statsStruct.results = {};
statsStruct.testType = '2 sample t-test';

switch lower(type)
    case 'crossplate'
        % combine data from all files into one data set then analyze
        nDataSets = 1;
        combinedData = dataDict('combinedData');
    case 'inplate'
        % analyze data from each file separetely
        nDataSets = nFiles;
    otherwise
        error('HTS_ttest: unknown type ''%s''',type);
end

fprintf(1,'------------------------------------\n');
fprintf('Dependent Variable: %s\n',dataSel.dependentVariable);
   
% Iterate over data sets.
for iData = 1:nDataSets   
    try 
        switch lower(type)
            case 'crossplate'
                theDataSet = combinedData;
                if nFiles == 1
                    dataSource = fileKeys{iData};
                    titleStr = sprintf('''%s''',dataSource);
                else
                    dataSource = 'Multiple Files';
                    titleStr = sprintf('CrossPlate Analysis, Multiple Files');
                end
            case 'inplate'
                theDataSet = dataDict(fileKeys{iData});
                dataSource = fileKeys{iData};
                titleStr = sprintf('''%s''',dataSource);
        end
        
        % Open a figure
         
        fh = figure('Visible','off');
        hold(gca,'on');
        
        % ---------- Perform the analysis ------------------------------------
        
        bh = zeros(1,nGroups); % handles to bar plots
        legStrings = cell(1,nGroups);
        % Loop over groups estimating the ECDFs and plotting the data
        
        for iGrp = 1:nGroups     
            grpKey = groupKeys{iGrp};
            depData = theDataSet(grpKey).dependentData;
            depData = depData(~isnan(depData)); % remove NaNs
            if isempty(depData)
                warning('HTS_tTest: %s\nEmpty data for group %s\n',dataSource,grpKey);
            end
            mu = mean(depData);
            stderr = std(depData)/sqrt(numel(depData));
            
            % Different Graphs
            
            bh(iGrp) = bar(iGrp,mu,0.75,'facecolor',plotColors{iGrp});
            plot([iGrp iGrp],[mu mu+stderr],'k');
%             ylim([0 100]);
%             xlim([0 3]);
%             grpProperties = dataSel.pairDefinitions(grpKey);
            legStrings{iGrp} = sprintf('%s (n=%i)',grpKey,numel(depData));
        end
        
        % Perform between group t tests and store the results in a dictionary
        statValues = containers.Map;
        statValues('dataSource') = dataSource;
       
        for iGrp1 = 1:nGroups
            for iGrp2 = iGrp1+1:nGroups
                grp1Key = groupKeys{iGrp1};
                depData1 = theDataSet(grp1Key).dependentData;
                grp2Key = groupKeys{iGrp2};
                depData2 = theDataSet(grp2Key).dependentData;
% 
                try 
                      Test if both data are normal 
                    np1 = lillietest(depData1); 
                    np2 = lillietest(depData2);

                    if np1 && np2 
                        [tmp.h,tmp.p] = ttest2(depData1,depData2,alpha);

                    else 
                        [tmp.p,tmp.h] = ranksum(depData1,depData2,'alpha',alpha);
                    end

                    statsKey = sprintf('%s vs %s',grp1Key,grp2Key);
                    statValues(statsKey) = tmp;
                    depData1_all{iGrp1,iGrp2}=depData1; %#ok<*AGROW>
                catch err
                    warning('HTS_tTest2:statsFailed','Group:%s maybe be empty.\n',grp1Key);
                end

            end
        end
        
        % ---------- Analysis Complete    ------------------------------------
        
        % Create the legend
        propargs = {};
        scribe.legend(gca,'vertical','NorthEastOutside',-1,bh',false,...
            legStrings,propargs{:});
        
        % Format the figure
        titleStr = regexprep(titleStr, '_', '/_');
        title(titleStr);
        ylabel(dataSel.dependentVariable,'fontsize',14);
        set(gca,'XTickLabelMode','manual')
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',{})
        set(gca,'XTick',[]);
        hold(gca,'off');
       
      
       % Added printing to specific directory  
       %Save to currentfolder/subplotGraphs/selectionStr/epsFileName.eps
       if printToFile{1} 
           %Create Directories
           if exist('Graphs','dir') ~= 7
                mkdir('Graphs');     
           end
            
            selectionStr = evalin('base','selectionStr');
            directory = sprintf('Graphs/%s',selectionStr);
            
            if exist(directory,'dir') ~= 7
                mkdir(directory);
            end
            
            % Naming convention for eps files for graphs
            % eg. if xls file named "AP47NFc14Synap
            % epsfilename will be "fileMarker DependentVariable bar AP47.eps"
            
           
            parseFile=regexp(dataSource,'/','split');
            [splitstring,matchstring] = regexp(parseFile{end},'[1-9999]\d',...
                'split','match');
            fileMarker = evalin('base', 'fileMarker');
            
            if isempty(matchstring) 
                crossplatePrefix = evalin('base','crossplatePrefix');
                filename = sprintf('%s%sbarCrossplate-%s',fileMarker,dataSel.dependentVariable,...
                    crossplatePrefix);  
            else
                filename = sprintf('%s%sbar%s%s',fileMarker,dataSel.dependentVariable,...
                    splitstring{1},matchstring{1});
            end
            
            epsFileName = sprintf('%s/%s.eps',directory,filename);
             print('-depsc',epsFileName);
            %figSpecifyStr = sprintf('-f%i',fh);
            fprintf('distributionTest: EPS file created: %s\n',epsFileName);
            set(fh,'Visible','on');   
            
        % If not true:
        else
            set(fh,'Visible','on');
       end
       
        % Create filename for stats csv
        if printToFile{2}
            wbkName = sprintf('./Statistics/%s-Ttest-Stats.csv',filename);
            fprintf('You are saving Ttest stats for file %s\n',dataSource);
        end
        
        switch lower(type)
            case 'crossplate'
                statsStruct.results{end+1} = statValues;
            case 'inplate'
                statsStruct.results{end+1} = statValues;
        end
          
    catch ME
        close(fh)
        warning('HTS_tTest: failed for data source ''%s''',dataSource); %#ok<WNTAG>
        fprintf('Error report:\n%s\n',getReport(ME));
    end
% var1=depData1_all;
end
reportStats(statsStruct);
end
