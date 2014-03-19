classdef dataSelectionObject < handle
    % dataSelectionObjects hold all data necessary to extract group data
    % from HTS xls files.  They define the dependent and independent
    % variables of interest and hold group definitions.  
    % HTS_GroupDataExtract() uses dataSelectionObjects to extract data 
    % for multiple xls files and put it all together in an HTS_dataDict 
    % for statistical analysis and plotting.
    %
    % v1.0    J.Gavornik    28 Feb 2011
    
    
    % Finding another way to separate between independent and dependent
    % variables for easy analysis without restricting the number of
    % independent variables to 1 and the number of dependent variables to 1
    % Start by commenting out if restrictions 
    % v2.0    Williams      20 Nov 2011
    % v1.0    Williams      24 Nov 2011  Abandoned previous plan 
    
    
    properties
        pairDefinitions % group pairs 
        dependentVariable % Header String
        independentVariable % Header String
        groupDefinitions % groupDefinitionObjects
        nGroups % number of data groups in the object
%         add pair property so pairs can be accessed
         
    end % properties
    
    methods
        
        function obj = dataSelectionObject()
            obj.pairDefinitions = containers.Map;
            obj.dependentVariable = {};
            obj.independentVariable = {};
            obj.groupDefinitions = {};
            obj.nGroups = 0;
            % group pairs 
           
        end
        
        function setDependentVariable(obj,value)
           if iscell(value)
                if numel(value) > 2
                    error('dataSelectionObject.setDependentVariable: more than two elements in header definition');
                end
            else
                value = {value};
            end
                obj.dependentVariable = value{:};
            end
        
        function setIndependentVariable(obj,value)
            if iscell(value)
                if numel(value) > 2
                    error('dataSelectionObject.setIndependentVariable: more than two elements in header definition');
                end
            else
                value = {value};
            end
                obj.independentVariable = value{:};
            end
        
        function addGroupDef(obj,grpDef)
            % Add a groupDef object
            tmplist={};
            if isa(grpDef,'groupDef')
                if sum(strcmp(grpDef.description,obj.getGroupDescriptions))
                    error('dataSelectionObject.addGroupDef: nonunique group name');
                end
                obj.groupDefinitions{end+1} = grpDef;
                obj.nGroups = obj.nGroups + 1;
               
                
                
               
                  for ii=1:length(grpDef.pairsDict.keys)
                      pairKeys = grpDef.pairsDict.keys;
                      theKey = strrep(pairKeys(ii),' ','');
                      theKey = char(theKey);
                      %Match group description to pairs (AJ added to get
                      %factors for ANOVA)
                      tmplist{ii}={theKey,grpDef.pairsDict(theKey)};      
                  end
                  obj.pairDefinitions(grpDef.description) = tmplist; 
            else
                error('dataSelectionObject.addGroupDef: not a groupDef');
            end
        end
        
        function findValidIndiciFromDataColumn(obj,headerStr,dataValues)
            % Update valid indici for each group based on the dataValues
            % associated with the headerStr
            for iGrp = 1:obj.nGroups
                obj.groupDefinitions{iGrp}.updateValidIndiciFromDataColumn(headerStr,dataValues);
            end
        end
        
        function clearAllIndici(obj)
            % Reset the validIndici for all groups
            for iGrp = 1:obj.nGroups
                obj.groupDefinitions{iGrp}.clearAllIndici;
            end
        end
        
        function dataDict = extractDataFromGroups(obj,dependentDataValues,independentDataValues)
            % Return a dictionary that with data extracted for each group
           dataDict = containers.Map;
           for iGrp = 1:obj.nGroups
               theGroup = obj.groupDefinitions{iGrp};
               theGroup.checkMatchCount;
               
            
               tmp.dependentData = cell2mat(dependentDataValues(theGroup.validIndici));
               
               tmp.independentData = cell2mat(independentDataValues(theGroup.validIndici));
               %added November 25
%                tmp.pairs = theGroup.pairsDict{theGroup.descriptions};
               %----------------------
               dataDict(theGroup.description) = tmp;
               
           end
        end
        
        function groupDescriptions = getGroupDescriptions(obj)
            % Return a cell array with all the group descriptions for the
            % selector
            groupDescriptions = cell(1,obj.nGroups);
            for ii = 1:obj.nGroups
                groupDescriptions{ii} = obj.groupDefinitions{ii}.description;
            end
        end
        

        
        function plotColors = getPlotColors(obj)
            % Return a cell array with all the group plot colors
            plotColors = cell(1,obj.nGroups);
            for ii = 1:obj.nGroups
                plotColors{ii} = obj.groupDefinitions{ii}.plotColor;
            end
        end
        
        function legStrs = formatLegendStrings(obj)
            % Return a cell array with formatted legend strings
            legStrs = cell(1,obj.nGroups);
            for ii = 1:obj.nGroups
                legStrs{ii} = sprintf('%s (n=%i)',...
                    obj.groupDefinitions{ii}.description,...
                    obj.groupDefinitions{ii}.nData);
            end
        end
        
        function reportContents(obj,filename)
            % Display the data selector contents
            if nargin < 2
                FID = 1;
                closeFile = false;
            else
                FID = fopen(filename);
                closeFile = true;
            end
            fprintf(FID,'dataSelectionObject: \ndependentVariable = ''%s''\nindependentVariable = ''%s''\n',...
                obj.dependentVariable,obj.independentVariable);
            fprintf('Groups:\n');
            for ii = 1:obj.nGroups
                fprintf(FID,'%i: ',ii);
                obj.groupDefinitions{ii}.reportContents(FID);
            end
            if closeFile
                fclose(FID);
            end
        end
        
    end % methods
      
end
        

