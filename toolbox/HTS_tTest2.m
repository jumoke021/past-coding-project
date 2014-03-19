function [statsStruct] = HTS_tTest2(dataDict,type,printToFile,alpha)

% Draws bar plots and performs pairwise t-test between each group data
%
% v1.0  Gavornik    3/12/2011
% v1.1  Williams    2/12/2012 Changed way files were named 
% v1.2  Williams    3/12/2012 Added subplot feature and printToFile(2)
                    % which conrols stats printing


if nargin < 2
    type = 'CrossPlate';
end

if nargin < 3
    printToFile = false;
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

% Plot Specifications 
plotMode = evalin('base','mode');
            
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

%Iterate over data files
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
                    titleStr = sprintf('CrossPlate Analysis');
                end
            case 'inplate'
                theDataSet = dataDict(fileKeys{iData});
                dataSource = fileKeys{iData};
                titleStr = sprintf('''%s''',dataSource);
        end
        
        % Open a figure 
        % Set subplot parameters
        rsubplot = evalin('base','rsubplot');
        csubplot = evalin('base','csubplot');
        if ~exist('isubplot','var') 
            fh = figure('Visible','off');
            legendtitle ={};
            isubplot=1;
        elseif exist('isubplot','var')
            if isubplot == (rsubplot* csubplot + 1)
                isubplot = 1;
            end
        end
        hold(gca,'on');
        
        % ---------- Perform the analysis ------------------------------------
        
        bh = zeros(1,nGroups); % handles to bar plots
        % Loop over groups estimating the ECDFs and plotting the data
        
        for iGrp = 1:nGroups   
            
            grpKey = groupKeys{iGrp};
            grpProperties = dataSel.pairDefinitions(grpKey);
            depData = theDataSet(grpKey).dependentData;
            depData = depData(~isnan(depData)); % remove NaNs
            
            if isempty(depData)
                warning('HTS_tTest: %s\nEmpty data for group %s\n',dataSource,grpKey);
            end
            
            if strcmp(plotMode,'noalternate') 
                if length(legendtitle) < nGroups+1
                    legendtitle = vertcat(legendtitle,grpKey);
                end
            else
                legendtitle ={'WT','KO'};
            end
            mu = mean(depData);
            stderr = std(depData)/sqrt(numel(depData));
            
            
            % Use plot mode to determine when row,column indicies for plot        
            if strcmpi(plotMode,'alternate') && sum(strcmpi('Marker',horzcat(grpProperties{:})))
                if iGrp >=3
                    if rem(iGrp,2)~= 0
                        isubplot = isubplot + 1;
                    end
                end 
            end
           
            subplot(rsubplot,csubplot,isubplot);   
            bh(iGrp) = bar(iGrp,mu,'grouped','facecolor',plotColors{iGrp});
%             ylim([0 250]);

            hold on;
            if iData == 1 && iGrp == nGroups
                figure(fh);
                get(gcf,'CurrentAxes');
                legend(bh,legendtitle,'Orientation','Vertical','Location','SouthWestOutside');
            end
            plot([iGrp iGrp],[mu mu+stderr],'k');
            
            %Formate Axis for alternating groups
            
            if strcmpi(plotMode,'alternate') && sum(strcmpi('Marker',horzcat(grpProperties{:}))) 
                if rem(iGrp,2) == 0
                    currentAxis = get(gcf,'CurrentAxes');
                    markerTitle = grpProperties{2};
                    formatFigures(markerTitle{2},currentAxis,nDataSets,iData,dataSel,5);
                end
            end
            
        end
        
        isubplot = isubplot + 1;
        
        % Perform between group t tests and store the results in a dictionary
        statValues = containers.Map;
        statValues('dataSource') = dataSource;
       
        for iGrp1 = 1:nGroups
            for iGrp2 = iGrp1+1:nGroups
                grp1Key = groupKeys{iGrp1};
                depData1 = theDataSet(grp1Key).dependentData;
                grp2Key = groupKeys{iGrp2};
                depData2 = theDataSet(grp2Key).dependentData;
                  
                try 
                   % Test if both data are normal 
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
                    warning('HTS_tTest2:statsFailed','Group:%s maybe be empty; graph will not be shown \n',grp1Key);
                end
                
            end
        end
        
        % Format the figure 
        currentAxis = get(gcf,'CurrentAxes');    
        formatFigures(titleStr,currentAxis,nDataSets,iData,dataSel,5);
        if strcmpi(plotMode,'alternate') && sum(strcmpi('Marker',horzcat(grpProperties{:})))>0
         h = get(currentAxis,'Title');
         strH = get(h,'String');
            newTitle = strcat(strH,':',markerTitle{2});
            title(newTitle);   
        end
           
        % Save graphs
        % Prints to currentfolder/subplotGraphs/selectionStr/epsFileName.eps
        
       if printToFile{1}
           
           %Create Directories if they do not already exist 
           if exist('subplotGraphs','dir') ~= 7
                mkdir('subplotGraphs');     
           end
            
            selectionStr = evalin('base','selectionStr');
            directory = sprintf('subplotGraphs/%s',selectionStr);
            
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
                filename = sprintf('%s%sbarcrossplate',fileMarker,dataSel.dependentVariable);  
            else
                filename = sprintf('%s%sbar%s%s',fileMarker,dataSel.dependentVariable,...
                    splitstring{1},matchstring{1});
            end
            
            epsFileName = sprintf('%s/%s.eps',directory,filename);
           
            %print and make fh visible only if all rows and columns of page have 
            % have been filled or if all datasets have been analyzed 
            
            if isubplot == (rsubplot*csubplot + 1) || iData == nDataSets
                print(fh,'-depsc',epsFileName);
                fprintf('distributionTest: EPS file created: %s\n',epsFileName);
                %figSpecifyStr = sprintf('-f%i',fh);
                set(fh,'Visible','on'); 
            end
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
        close(fh);
        warning('HTS_distributionTest: failed for data source ''%s''',dataSource); %#ok<WNTAG>
        fprintf('Error report:\n%s\n',getReport(ME));
    end
% var1=depData1_all;
end
reportStats(statsStruct);
end
