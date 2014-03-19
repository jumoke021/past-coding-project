function statsStruct = HTS_regressionCoincidenceTest(dataDict,type,printToFile,alpha)

% Scatter plot data, plot linear regression lines and use the pair-wise F
% statistic to determine whether a linear fit based on combined data is
% better than the individual fits
%
% v1.0  Gavornik    3/12/2011

if nargin < 2
    type = 'CrossPlate';
end

if nargin < 3
    printToFile(1) = false;
    printToFile(2) = false;
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
statsStruct.testType = 'Regression Coincidence';
csvStats = {}; %create cell array to hold staats value for Asha's method for    
                

switch lower(type)
    case 'crossplate'
        % combine data from all files into one data set then analyze
        nDataSets = 1;
        combinedData = dataDict('combinedData');
    case 'inplate'
        % analyze data from each file separetely
        nDataSets = nFiles;
    otherwise
        error('HTS_regressionCoincidence: unknown type ''%s''',type);
end

for iData = 1:nDataSets
    
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
    
    % Loop over groups fitting the data and plotting
    minX = inf; maxX = -inf;
    fitParams = cell(1,nGroups);
    legStrings = cell(1,nGroups);
    for iGrp = 1:nGroups
        grpKey = groupKeys{iGrp};
        y = theDataSet(grpKey).dependentData;
        x = theDataSet(grpKey).independentData;
        iNaN = isnan(x);
        x = x(~iNaN)'; % remove NaNs
        y = y(~iNaN)'; % remove NaNs
        x = x(:);
        y = y(:);

        % Calculate the slope and y-intercept values
        n = numel(x);
        B = [ones(n,1) x]\y;
        a = B(1);
        b = B(2);
        
        % Calculate the slope error estimates
        s_yx = sqrt(((n-1)/(n-2))*(std(y)^2-b^2*std(x)^2));
        % Calculate the correlation coefficient
        r_yx = 1/(n-1)^2*sum((x-mean(x)/std(x)).*(y-mean(y)/std(y)));
        % Save all in a structure
        tmpStruct.n = n;
        tmpStruct.int = a; % y intercept
        tmpStruct.slope = b; % slope
        tmpStruct.s_yx = s_yx;
        tmpStruct.r_yx = r_yx; % coefficient of correlation
        tmpStruct.x = x;
        tmpStruct.y = y;
        % Added by AJ
        tmpStruct.stdx = std(tmpStruct.x);
        tmpStruct.stdy = std(tmpStruct.y);
        fitParams{iGrp} = tmpStruct;
        % Scatterplot the data
        plot(x,y,'o','MarkerFaceColor',plotColors{iGrp},'MarkerEdgeColor',...
            plotColors{iGrp},'MarkerSize',7);
        xlimits = xlim; ylimits = ylim;
        xlim([0,xlimits(2)]);
        xlim([0,300]);
        ylim([0,ylimits(2)]);
%         ylim([0,200000]);
        legStrings{iGrp} = sprintf('%s (n=%i)',grpKey,n);
        if min(x) < minX
            minX = min(x);
        end
        if max(x) > maxX
            maxX = max(x);
        end
    end
    legend(legStrings,'Vertical','Location','Best')
    % Add the fit lines
    x_ = [0 minX maxX];
    x_ = [0 minX 300];
    for iGrp = 1:nGroups
        fp = fitParams{iGrp};
        % Scatterplot the data
        plot(x_,fp.slope*x_+fp.int,'color',plotColors{iGrp},'linewidth',1.7);
    end
    
    % Calculate F statistic for improvement of fit for grouped data and
    % store the results in a dictionary
    statValues = containers.Map;
    statValues('dataSource') = dataSource;

    for iGrp1 = 1:nGroups
        for iGrp2 = iGrp1+1:nGroups
            grp1Key = groupKeys{iGrp1};
            fp1 = fitParams{iGrp1};
            grp2Key = groupKeys{iGrp2};
            fp2 = fitParams{iGrp2};
            
            %Get standard deviations and slope
            std_x1 = fp1.stdx;
            std_x2 = fp2.stdx;
            std_y1 = fp1.stdy;
            std_y2 = fp2.stdy;
            % Get the slope error estimates for the individual fits
            s_yx1 = fp1.s_yx;
            n1 = fp1.n;
            s_yx2 = fp2.s_yx;
            n2 = fp2.n;
            % Compute the pooled estimate of variance around the regression lines
            s_yxp = ((n1-2)*s_yx1^2+ (n2-2)*s_yx2^2)/(n1+n2-4);
            
            % Fit all data with a single regression line and calculate the variance
            % around this fit
            x = [fp1.x;fp2.x];
            y = [fp1.y;fp2.y];
            n = numel(x);
            B = [ones(n,1) x]\y;
            a = B(1);
            b = B(2);
            s_yx = sqrt(((n-1)/(n-2))*(std(y)^2-b^2*std(x)^2));
            
            % Compute how much using two sets improves the fit
            s_yximp = ((n1+n2-2)*s_yx^2 - (n1+n2-4)*s_yxp)/2;
            
            % Compute the F test statistic for improvement of fit
            F = s_yximp / s_yxp;
            df1 = 2; % numerator degrees of freedom
            df2 = n1+n2-4; % denominator degrees of freedom
            p = fcdf(F,df1,df2);
            tmp.p = 2*min(p,1-p);
            tmp.h = tmp.p<alpha;
            
            statsKey = sprintf('%s vs %s',grp1Key,grp2Key);
            statValues(statsKey) = tmp;
        
        
            % Regression Analysis : Second Method 
  
            %Regression Analysis calculating covariance and the "parallel
            %model SSE" calculated using pooled estimate of variance
            
                        
            r1 = 0.5*log(abs(1+fp1.r_yx/(1-fp1.r_yx)));
            r2 = 0.5*log(abs(1+fp2.r_yx/(1-fp2.r_yx)));
            zstatistic = r1-r2/(sqrt(1/(n1-3) + 1/(n2-3)));
            
            SSE= sqrt(s_yxp/((n1-1)*std_x1^2) + s_yxp/((n2-1)*std_x2^2));
            tstatistic = (fp1.slope - fp2.slope)/SSE;
            totalN = df2 + 4;
            
            titles = { dataSource, 'Slope Group1','Slope Group2','SSE',...
                'Total Number of Elements','Degrees of Freedom (df)',...
                'tvalue','Regression Coefficents: Grp1,Grp2','Fishers Test(zvalue)'};
            grp1slope = sprintf('%s = %i',grp1Key,fp1.slope);
            grp2slope = sprintf('%s =%i',grp2Key,fp2.slope);
            for ii = 1:9
                csvStats{1,ii} = titles{ii};
            end
            csvStats = vertcat(csvStats,{dataSel.dependentVariable,grp1slope,grp2slope,SSE,...
                totalN,df2,tstatistic,[r1,r2],zstatistic});          
        end
    end

    
    % ---------- Analysis Complete    ------------------------------------
    
    % Format the figure
    titleStr = regexprep(titleStr, '_', '/_');
    title(titleStr);
    ylabel(dataSel.dependentVariable,'fontsize',14);
    xlabel(dataSel.independentVariable,'fontsize',14);
    set(gca,'Box','on')
    set(gca,'TickDir','out')
    set(gca,'FontSize',9);
    hold(gca,'off');
    hold(gca,'off');
   
    % Saves to currentfolder/subplotGraphs/selectionStr/epsFileName.eps
    if printToFile{1}

        %Create Directories if they do not already exist 
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
        % epsfilename will be "fileMarker DependentVariable reg AP47.eps"

        parseFile=regexp(dataSource,'/','split');
        [splitstring,matchstring] = regexp(parseFile{end},'[1-9999]\d',...
            'split','match');
        fileMarker = evalin('base', 'fileMarker');
        
        if isempty(matchstring) 
            crossplatePrefix = evalin('base','crossplatePrefix');
            filename = sprintf('%s%sRegCrossplate-%s',fileMarker,dataSel.dependentVariable,...
                crossplatePrefix); 
        else
            filename = sprintf('%s%sReg%s%s',fileMarker,dataSel.dependentVariable,...
                splitstring{1},matchstring{1});
        end

        epsFileName = sprintf('%s/%s.eps',directory,filename);
        print('-depsc',epsFileName);
%             figSpecifyStr = sprintf('-f%i',fh);
        fprintf('distributionTest: EPS file created: %s\n',epsFileName);
        set(fh,'Visible','on');
        
    else
        set(fh,'Visible','on');
    end
    
    switch lower(type)
        case 'crossplate'
            statsStruct.results{end+1} = statValues;
        case 'inplate'
            statsStruct.results{end+1} = statValues;
    end
     
      %Saving and priting statistics structure
    if printToFile{2}
        wbkName = sprintf('./Statistics/%s-Reg-Stats.csv',filename);
        wbkName2=sprintf('./Statistics/%s-Reg-Stats2.csv',filename);
        fprintf('You are saving Reg stats for file %s\n',dataSource); 
    end

    switch lower(type)
        case 'crossplate'
            statsStruct.results{end+1} = statValues;
        case 'inplate'
            statsStruct.results{end+1} = statValues;
    end 
end
    if printToFile{2}
        %Saving other statistics (Asha's method)
        csvCellWriter(wbkName2,csvStats);
    end
        reportStats(statsStruct);
end