function statsStruct = HTS_distributionTest2(dataDict,type,printToFile,alpha)

% Calculates estimated CDFs for the all groups and plots, performs KS test
% between each pair
%
% v1.0  Gavornik    3/12/2011

if nargin < 2
    type = 'CrossPlate';
end

if nargin < 3
    printToFile{1} = false;
    printToFile{2} = false;
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
statsStruct.testType = '2 sample KS';


switch lower(type)
    case 'crossplate'
        % combine data from all files into one data set then analyze
        nDataSets = 1;
        combinedData = dataDict('combinedData');
    case 'inplate'
        % analyze data from each file separetely
        nDataSets = nFiles;
    otherwise
        error('HTS_distributionTest: unknown type ''%s''',type);
end


fprintf(1,'------------------------------------\n');
fprintf('Dependent Variable: %s\n',dataSel.dependentVariable);
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
        if ~exist('isubplot','var') 
            fh = figure('Visible','off');
            isubplot=1;
        elseif exist('isubplot','var')
            if isubplot == 5
                isubplot = 1;
                fh = figure('Visible','off');
            end
        end
        hold(gca,'on');
        
        % ---------- Perform the analysis ------------------------------------
        
        % Loop over groups estimating the ECDFs and plotting the data
        legStrings = cell(1,nGroups);
        for iGrp = 1:nGroups
            grpKey = groupKeys{iGrp};
            depData = theDataSet(grpKey).dependentData;
            depData = depData(~isnan(depData)); % remove NaNs
            if isempty(depData)
                warning('HTS_distributionTest: %s\nEmpty data for group %s\n',dataSource,grpKey);
            end
            [f x] = ecdf(depData);
            subplot(1,4,isubplot);
            stairs(x,f,'color',plotColors{iGrp});
            legStrings{iGrp} = sprintf('%s (n=%i)',grpKey,numel(depData));
        end
        isubplot = isubplot + 1;
       
        
        % Perform between group KS tests and store the results in a dictionary
        statValues = containers.Map;
        statValues('dataSource') = dataSource;
        for iGrp1 = 1:nGroups
            for iGrp2 = iGrp1+1:nGroups
                grp1Key = groupKeys{iGrp1};
                depData1 = theDataSet(grp1Key).dependentData;
                grp2Key = groupKeys{iGrp2};
                depData2 = theDataSet(grp2Key).dependentData;
                [tmp.h,tmp.p] = kstest2(depData1,depData2,alpha);
                statsKey = sprintf('%s vs %s',grp1Key,grp2Key);
                statValues(statsKey) = tmp;
            end
        end
        
        % ---------- Analysis Complete    ------------------------------------
        
        % Format the figure       
        titleStr = regexprep(titleStr, '_', '/_');
        if nDataSets ~=1 && iData ~= nDataSets
            [parseTitleStr]=regexp(titleStr,'/','split');
            [newTitleStr] = regexp(parseTitleStr{end-1},'\w\w[1-9999]\d','split');
            title(newTitleStr,'fontsize',8);
        else
            title(titleStr,'fontsize',8);
        end

        %Format overall legend
        figure(fh);
        get(gcf,'CurrentAxes')   
        legend(legStrings,'Location','Best')
        
        % Axes Labels
        ylabel('P(X\leqx)','fontsize',6);
        xlabel(dataSel.dependentVariable,'fontsize',6);
        set(gca,'TickDir','out')
        hold(gca,'off');
        
        if exist('set_all_properties','file') == 2
            set_all_properties(fh,'hggroup','LineWidth',2);
            % set_all_properties(fh,'text','FontSize',14);
        end
        
        % Save graphs
        % Prints to currentfolder/subplotGraphs/selectionStr/epsFileName.eps
        if printToFile{1}
           
            %Make Directories
            if exist('subplotGraphs','dir') ~= 7
                mkdir('subplotGraphs');     
            end

            selectionStr = evalin('base','selectionStr');
            directory = sprintf('Graphs/%s',selectionStr);
            
            if exist(directory,'dir') ~= 7
                mkdir(directory);
            end
            
            %Name eps files
            parseFile=regexp(dataSource,'/','split');
            [splitstring,matchstring] = regexp(parseFile{end},'[1-9999]\d',...
                'split','match');
            fileMarker = evalin('base', 'fileMarker');
            
            if isempty(matchstring) 
                filename = sprintf('%s%sDistcrossplate',fileMarker,dataSel.dependentVariable);
            else
                filename = sprintf('%s%sDist%s%s',fileMarker,dataSel.dependentVariable,...
                    splitstring{1},matchstring{1});
            end         
            
            if isubplot == (rsubplot*csubplot + 1) || iData == nDataSets
                epsFileName = sprintf('%s/%s.eps',directory,filename);
                print('-depsc',epsFileName);
                %figSpecifyStr = sprintf('-f%i',fh);
                fprintf('distributionTest: EPS file created: %s\n',epsFileName);
                set(fh,'Visible','on');
            end
            %Set printing instructions for stats

                wbkName = sprintf('./Statistics/%s-distribution-Stats.csv',filename);
                fprintf('You are saving KS stats for file %s\n',dataSource);
%             end
            
        else
            set(fh,'Visible','on');
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
end
end