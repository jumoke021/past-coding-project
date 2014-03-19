function excelmath(input1,input2,input3,input4,input5)
%%
% Allows for the math processing of excel sheets in the 3 following ways: 

% Arthimetic - allows you to perform math operations between data in two
% columns.Inputs are numbered according to the number of arguments(nargin).
%    input1 = {'column1name&column2name'} 
%    input2 = 'name of new column which will contain data'
%    input3 = functionhandle 
% Input 1 can be a cell array or a string. Input2 should be a string.

% Normalize - allows you to normalize specific data by other data
%    input1 = {'WT,CTL&NMDA'} means for all wildtype data normalize NMDA by
%              CTL while {'WT,CTL&NMDA','KO,CTL&NMDA'} will normalize 
%              wildtype NMDA by CTL, and then normalize knockout NMDA by 
%              CTL and store this data in the column specified by input2;
%              Another example: Grouping by marker (instead of genotype):
%              {'GluR2, WT&KO'}. First term is always denominator proceeding '&' and can
%              have many treatments following after ',' 
%    input2 = 'name of new column which will contain the normalized data';
%    input3 = 'column name of data you want to normalize'
%    input4 = functionhandle
%    input5 = 'across' or 'within' (the only two strings it accepts)
%             'across' if you want to normalize across rows
%             'within' if you want to normalize KO from one row to its 
%              corresponding WT.
% Input 1 must be a cell array. Input 2, 3 and 4 must be strings.
              
              
% Erase -  allows you to erase specific columns of data entered into an 
% excelsheet if you discover that you have perfored an operation 
% incorrectly. It only takes one input (input1).
%    input1 = number of columns to erase
    
% Williams  v1.0 Jan.13,2012    Code based on  Jeff Gavornik's 
%                               HTS_GroupDataExtract    
% Williams  v2.0 Jan.18,2012    Added arthimetic capabilities 
% Williams  v2.1 Feb.10,2012    Now throws an error if input4 is not a 
%                               functionhandle


% Determine what type of operation you are performing 

if nargin == 3
    type = 'arithmetic'; 
elseif nargin ==  5
    type = 'normalize'; 
elseif nargin == 1;
    type = 'erase';
end

    
    % Select files based on whether you are processing files at the same time. 
    processing = input('Are you processing files at the same time\n Please enter y or n \n','s');   
    % If not processing pull up FileSelector and select files
    
    if ~strcmpi(processing,'y') 
        allFiles = find_xls_files('.');
        FileSelector(allFiles)
        %extend scope of where selected files can be called from
        selected_files =evalin('base','selected_files'); 
    % If processing pull up processed files. 
    else    
        selected_files= evalin('base','fieldOutputFiles');
        selected_filesWells = evalin('base','wellOutputFiles');
        for ii=1:length(selected_filesWells)
            selected_files{end+1}=selected_filesWells{ii};
        end
    end


%-------------------% General File processing----------------------------%

% This cell will iterate over all selected files write columns into them
% based on inputs specified in the excelmath func.

nFiles = numel(selected_files);
for iFile = 1:nFiles 
    %Start with fresh indici for all groups
    dataFile = selected_files{iFile};
    [a,sheetNames] = xlsfinfo(dataFile);
    if ~strcmp(a,'Microsoft Excel Spreadsheet')
        error('excelmath: %s if not an excel spreadsheet',dataFile);
    end
    if sum(strcmp(sheetNames,'Math'))
        sheetName = 'Math';
    elseif sum(strcmp(sheetNames,'Corrected'))
        sheetName = 'Corrected';
    elseif sum(strcmp(sheetNames,'AutoCreate'))
        sheetName = 'AutoCreate';
    end
    
    % Read data from dataFile into ndata(only numberical data) and 
    % tdata(only char/string data)
    if ismac
        warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
    end
    [ndata,tdata,data] = xlsread(dataFile,sheetName);
    % Get dimension of matrix/cellarray 
    [row,col]=size(tdata); [~,ncol]=size(ndata); 
    % Find difference between column dimensions in ndata and tdata 
    differencecol = col-ncol; 
    % Set size of matrix in which calculated data will be stored. 
    newdata=zeros(row,1); % 

% Perform operations based on type 

    switch type 
        case 'arithmetic'  
            % define operation to perform
            fhandle = input3; 

            %extract header names 
            header1 = tdata(1,:); 
            header2 = tdata(2,:);
            cHeader = cell(1,numel(header1));
            for ii = 1:numel(header1)
            cHeader{ii} = strtrim(sprintf('%s %s',header1{ii},header2{ii}));
            %removes NAN in headers
            end

            % Find column indices of header names specified by input1

            [splitstring] = regexp(input1,'&','split'); 
            % Input 1 contains headers names of columns you want to perform 
            % arithmetic on.These names are separated by a '&'so you splice
            % the string in order to access the individual column headers

            colheaders=zeros(1,length(splitstring));%store column indices  
            for col = 1:numel(cHeader)
                hv = cHeader{col};
                if strcmp(hv,splitstring{1})   
                    colheaders(1) = col;  
                % sprintf('header1 %s\n',cHeader{col})
                elseif strcmp(hv,splitstring{2})  
                    colheaders(2)= col;
                    %sprintf('header2 %s\n',cHeader{col})
                end
            end

            if length(colheaders)<2
                error('Column headers specified not found in %s\n Please check xls file\n',...
                    dataFile);
            end

            % Extract specified columns from data from file. Because ndata 
            % removes columns that contain only text, the dimensions of 
            % ndata's columns have been decreased by the value calculated 
            % as "differencecol" 

            % place data in matrix x 
            varsdata = ndata(:,colheaders-differencecol);

            %perform operation specified by function_handle
            newdata(3:row,1)=fhandle(varsdata(:,1),varsdata(:,2));
            fprintf(1,'\n------------------------------------\n');
            fprintf('Added math to file: %s, sheetname %s\n',dataFile,sheetName);
            
        case 'normalize'
            % Resize ndata to fit original size of cell array of xls file data
            temp_data(3:row,differencecol+1:col)= ndata; ndata = temp_data;

            % Retrieve column with the dependent data values    
            dependentdata = input3; %dependent variable to normalize
            [~,headerCol]= find(ismember(tdata(2,:),dependentdata));
            
            % Check to see if data has been properly pulled from xls file
            if isempty(headerCol)
                fprintf('Your variable name is incorrect\n');
                fprintf('Please check %s and make sure your header name is correct\n',...
                    dataFile);
            end
            
            dependentCol = ndata(:,headerCol(1));
            
            % Check to see if normalization groups have been defined
            if isempty(input1)
                error('excelmath: normalization parameters have not been specified\n') 
            elseif ~iscell(input1)
                error('excelmath: input1 is in not a cell array:{}\n')
            end

            varsdata=cell(1,length(input1)); % store the calcuated data
            rowsIndices=[]; %stores appropriate column indice for each data

            % Start parsing normalization groups
            for groupsNormalize = 1:length(input1)
                checkIndices = [];
                group = input1{groupsNormalize};
                if ~find(group =='&')
                    error('excelmath: normalization parameters not correctly defined\n')
                end

                %Find 
                index=find(group =='&');          
                baselineVars = regexp(group(1:index-1),',','split');
                specifiedVars = regexp(group(index+1:end),',','split');

                %index through data based on class of baselineVars
                for j=1:length(baselineVars)
                    if j== 1 
                       if ischar(baselineVars{j})
                            [indexrow,~] = find(ismember(tdata,baselineVars{j}));
                            %retrieves index of rows that match baselineVars{j}
                        elseif strcmp(class(baselineVars(j)),'double')
                            [indexrow,~] = find(ismember(ndata,baselineVars(j)));
                            %retrieves index of rows that match baselineVars{j}
                       end
                    else
                        [checkIndices,~] = find(ismember(tdata(indexrow,:),...
                            baselineVars{j}));
                    end
                end
              
                %Extract the data of control group
                extract_data = dependentCol(indexrow);
                new_dependentCol = extract_data(checkIndices);

                % Find mean of the control group but first remove nan
                new_dependentCol = new_dependentCol(~isnan(new_dependentCol)); 
                data_mean(groupsNormalize) = mean(new_dependentCol); %mean

                % Find std of all values used for normalization 
                data_std(groupsNormalize)=  std(new_dependentCol);%std
                fprintf(1,'\n------------------------------------\n');
                fprintf('excelmath:processing file %s sheet %s\n',dataFile,...
                    sheetName);
                fprintf('The mean for column %s is %d and the stdev is %d\n',...
                input3, data_mean(groupsNormalize),data_std(groupsNormalize));
  
                %Limit rows that are indexed// helps remove redundacy 
                for ii=1:length(specifiedVars)      
                    switch class(specifiedVars{ii})% 
                        case 'char'
                            [tcheckIndices,~]= find(ismember(tdata(indexrow,:),....
                                            specifiedVars{ii}));  
                            checkIndices(end+1:end+length(tcheckIndices)) = tcheckIndices;                      
                        case 'double'
                            [tcheckIndices,~]= find(ismember(ndata(indexrow,:),....
                                            specifiedVars{ii}));  
                             checkIndices(end+1:end+length(tcheckIndices)) = tcheckIndices;  
                    end
                end


                 dataidentifiers = tdata(indexrow,1);%data you want to extract
                 dataidentifiers = dataidentifiers(checkIndices);

                % Need to find matching row indices to write new column back
                % into appropriate rows in excel sheet
                [rowsIndices,~] =find(ismember(tdata(:,1),dataidentifiers));  

                % Now actually extract the data you are normalizing 
                varsdata{groupsNormalize}= dependentCol(rowsIndices);   

                % Check to see function handle defined and apply specified function 
                if isa(input4,'function_handle')
                            fhandle = input4;
                else 
                    error('Must declare a function_handle');
                end

                % Check to see if you are performing the operation defined by
                % input 4 across wells are within a well.
                if strcmp(input5 ,'across')
                    newdependentdata = fhandle(varsdata{groupsNormalize},...
                        data_mean(groupsNormalize));
                    newdata(rowsIndices) = newdependentdata;%match indices with data
                    fprintf('Normalized within row for file: %s, sheetname %s\n',dataFile,sheetName);    
                elseif strcmp(input5 ,'within')
                    newdata = fhandle(varsdata{1},varsdata{2});
                    fprintf('Normalized within row for file: %s, sheetname %s\n',dataFile,sheetName);
                end

            end %end of for loop with input1 in case 'normalize'
        
        case 'erase'
            columnNumbers = input1;
            newdata = cell(row,columnNumbers);
            fprintf(1,'\n------------------------------------\n');
            fprintf('For file %s:\n',dataFile);
            columnIndex = tdata(2,end-columnNumbers+1:end);
            for headers = 1:length(columnIndex)
                headerName = columnIndex{headers};
                fprintf('Erasing column header %s\n',...
                    headerName);
            end
    end % end of switch / case 

% -------------------End of Math Processing ---------------------------%

    % Write new columns and rows to existing xls file. Final processing of
    % data.
        if ~strcmp(type,'erase')
            newdata=num2cell(newdata);% change data to cell class
            newdata{1} = ''; % add header row 1
            newdata{2} = input2; %add header row 2 
            
            % add one beacuse you are adding one column to the xls file
            col = col+1; 
            %xlswrite saves inf as 65535, change to empty cell
            for rows=3:length(newdata)
                dv=double(newdata{rows});
                if dv == Inf
                    newdata{rows} = [];
                end
            end
        else
            col = col - columnNumbers + 1;
        end
  
    %Find column headers (as specified by excel) that will specify the
    %exact column newdata should be written into. 
        alphabet = 'abcdefghijklmnopqrstuvwxyz'; % for accessing columns
        
        %Determine column name 
        if col<27
            excelrange=alphabet(col);
        elseif col>26
            if rem(col,26) ==0
                excelrange = sprintf('%sz',alphabet(col/26 -1));
            elseif rem(col,26)>0
                excelrange = sprintf('%s%s',...
                alphabet(idivide(int32(col),26)),alphabet(rem(col,26)));
            end
        end
        %fprintf('The column name is %s \n',excelrange);

        if ispc
            % Write file results to a xls file
            [success,message]=xlswrite(dataFile,newdata,sheetName,excelrange);
            warning('on','MATLAB:xlswrite:AddSheet');
            if ~success
                fprintf('%s\n',message.message);
                warning('excelmath: xlswrite failed for %s',dataFile); %#ok<WNTAG>
            end
        elseif ismac
            % Write out results to a csv file 
            data(:,end+1) = newdata(:,1);
            [splitstring]=regexp(dataFile,'.xls','split');
            dataFile = sprintf('%s.csv',splitstring{1});
            csvCellWriter(dataFile,data);
        end

end






        
                    

    
            

    
            
    


           

