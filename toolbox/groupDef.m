classdef groupDef < handle
    % groupDef is an object that is used to define data extraction
    % groupings for HTS screens.  It hold pairs (eg. "Genotype=KO") that
    % define which data constitutes a group.  It is used by
    % dataSelectionObjects to find  desired data within an xls file.  It
    % has a user defined group description and a designated color to use
    % when plotting data extracted for this group.
    %
    % Pairs consist of a group description, which is equivalent to the
    % column header row (or rows) from the xls file, and a target string 
    % that describes the values for this description that should be
    % included in the group.
    %
    % Pairs may include relational (>,<,>=,<=) and boolean operators (&,|)
    % as well as the not operator (~).  Boolean operator go between target
    % values, other operators go at the beginning of the target
    % description.  For example, to select for "Neuronal Phenotype Neuronal
    % (n)" > 5 and <= 10, the group pairing would be defined using:
    % grp.addPair('Neuronal Phenotype Neuronal (n)','>5|<=10');
    %
    % If no relational operator is assigned, the group will select for
    % equivalence (i.e. dataValue == targetValue)
    %
    % Empty cells can be selected by defining the target string as 'empty'
    %
    % The method recursiveComparison is responsible for interpreting the
    % target definition string and making comparisons to data values.
    %
    % See dataSelectionObjects and HTS_GroupDataExtract for more details on
    % group data extraction
    %
    % Note: a groupDef instantiation will throw a warning when
    % checkMatchCount is called if not all of the group pairings have
    % matched against data
    %
    % v1.0    J.Gavornik    28 Feb 2011
    % v1.1    J.Gavornik    10 May 2011 - removed error message when using
    %                                     empty to indicate control and a
    %                                     char was returned
    
    %#ok<*NASGU>
    
    
    properties
        nPairs % number of description-values pairs defining the group
        plotColor % RGB color to use when plotting the group
        description % string to identify the group, will show up in plot legends
        pairsDict % holds all description-value pairs that define the group
        validIndici % row-wise indici corresponding to the group within the xls data
        matchCount % increments when pair descriptions match against xls headers
    end
    
    methods
        function obj = groupDef()
            % Initialize the object
            obj.nPairs = 0;
            obj.pairsDict = containers.Map;
            obj.plotColor = [0 0 1];
            obj.description = 'groupDef';
            obj.validIndici = [];
            obj.matchCount = 0;
        end
        
        function setDescription(obj,description)
            % Define a string to describe the grouping
            obj.description = description;
        end
        
        function setPlotColor(obj,color)
            % Set the plot color to be any valid RGB pair or matlab color
            % designator.
            obj.plotColor = color;
        end
        
        function reportContents(obj,FID)
            % Print the groupDef contents to FID.  By default, sends to
            % STDIO.
            if nargin < 2
                FID = 1;
            end
            fprintf(FID,'''%s'' %i pairs\n',obj.description,obj.nPairs);
            keys = obj.pairsDict.keys;
            for ii = 1:obj.nPairs
                theKey = keys{ii};
                theValue = obj.pairsDict(theKey);
                fprintf(FID,'\t%i: ''%s'' = ''%s''\n',ii,theKey,theValue);
            end
            
        end
        
        function addPair(obj,description,valueMatchingString)
            % Add a header value pair to the groupDef container.  For
            % example, addPair('Genotype','KO')
            obj.nPairs = obj.nPairs+1;
            keyStr = strrep(description,' ',''); % remove all spaces
            obj.pairsDict(keyStr) = valueMatchingString;
        end
        
        function updateValidIndiciFromDataColumn(obj,headerStr,dataValues)
            % Finds indici into the values that match against any value
            % pairings present in the group definition
            headerStr_ = strrep(headerStr,' ',''); % remove all spaces
            % fprintf('Passed %s...\n',headerStr_);
            if obj.pairsDict.isKey(headerStr_)
                % fprintf('Matched %s\n',headerStr_);
                % indici = false(size(dataValues));
                matchValue = obj.pairsDict(headerStr_);
                obj.matchCount = obj.matchCount + 1;
                indici = obj.recursiveComparison(matchValue,dataValues);
                if isempty(obj.validIndici)
                    obj.validIndici = indici;
                else
                    obj.validIndici = indici & obj.validIndici;
                end
            end
        end
        
        function checkMatchCount(obj)
            % Display a warning if some of pairs have not been matched.
            % This means something in the data selection was incorrect and
            % data extracted using this groupDef might not be what is
            % expected.
            if obj.matchCount ~= obj.nPairs
                warning('groupDef: %s Not all pairs were successfully matched.  DATA MAY BE INCORRECT',obj.description);
            end
            if ~sum(obj.validIndici)
                warning('groupDef: %s Empty set, no data will be selected for this group',obj.description);
            end
        end
        
        function clearAllIndici(obj)
            obj.validIndici = [];
            obj.matchCount = 0;
        end
        
        function n = nData(obj)
            n = sum(obj.validIndici);
        end
        
        function match_indici = recursiveComparison(obj,challengeStr,data)
            % Function to return indici of data that match against the
            % challengeStr
            
            %fprintf('recursiveComparison: challengeStr = ''%s''\n',challengeStr);
            try
                % Recurse at any boolean operators
                [parts ind] = regexp(challengeStr,'&','once','split');
                if ind
                    match_indici = obj.recursiveComparison(parts{1},data) & ...
                        obj.recursiveComparison(parts{2},data);
                    return
                end
                [parts ind] = regexp(challengeStr,'\|','once','split');
                if ind
                    match_indici = obj.recursiveComparison(parts{1},data) | ...
                        obj.recursiveComparison(parts{2},data);
                    return
                end
                
                % Look for the NOT operator
                notFlag = false;
                index = regexp(challengeStr,'~');
                if index == 1
                    challengeStr = challengeStr(index+1:end);
                    notFlag = true;
                elseif ~isempty(index)
                    error('recursiveComparison: NOT operator must be in position 1');
                end
                
                % Look for any relational operators
                index = regexp(challengeStr,'[><]=');
                if ~isempty(index)
                    operator = challengeStr(index:index+1);
                    challengeStr = challengeStr(index+2:end);
                end
                index = regexp(challengeStr,'[><]');
                if ~isempty(index)
                    operator = challengeStr(index);
                    challengeStr = challengeStr(index+1:end);
                end
                if exist('operator','var')
                    if index ~= 1
                        error('recursiveComparison: operator must be in position 1');
                    end
                else
                    operator = '=';
                end
                
                % Match data based on operator and data type
                match_indici = false(size(data));
                for ii = 1:numel(data)
                    theData = data{ii};
                    dataClass = class(theData);
                    if ~strcmp(operator,'=') && ~strcmp(dataClass,'double')
                        warning('recursiveComparison: relational operator used on class %s data',dataClass);
                    end
                    switch operator
                        case '='
                            switch dataClass
                                case 'double'
                                    % Note: empty cells in an XL file are
                                    % read into matlab as NaN which are
                                    % class double, so handle 'empty'
                                    % designation here
                                    if strcmpi(challengeStr,'empty')
                                        match_indici(ii) = isnan(theData);
                                        
                                    else
                                        match_indici(ii) = theData == str2double(challengeStr);
                                    end
                                case 'char'
                                        match_indici(ii) = strcmp(theData,challengeStr);
                                otherwise
                                    warning('groupDef.findMatches: unknown class %s for data selections',class(theData));
                            end
                        case '<'
                            match_indici(ii) = theData < str2double(challengeStr);
                        case '>'
                            match_indici(ii) = theData > str2double(challengeStr);
                        case '>='
                            match_indici(ii) = theData >= str2double(challengeStr);
                        case '<='
                            match_indici(ii) = theData <= str2double(challengeStr);
                        otherwise
                            error('recursiveComparison: unknown operator');
                    end
                end
                if notFlag
                    match_indici = ~match_indici;
                end
                
            catch ME
                match_indici = false(size(data));
                fprintf('Data extraction error:\n%s\n',getReport(ME));
            end
        end % recursiveComparison
        
    end % methods
    
    
end