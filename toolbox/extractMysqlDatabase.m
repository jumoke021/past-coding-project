% Notes of extractMysqlDatabase 
% maybe I should create a function that handles creating database groups? 
function returnDict = extractMysqlDatabase (dataSelector,plateType,metadata)
%% Connects to MySQL Database and extracts data based on specifications of
%  group pairs. Stores data in structure defined by HTSdataDict;

% v1.0  Williams 5/27/2012


%% Connect to Database: set javapath & vpn into Broad
javaaddpath('/Applications/mysql-connector-java-5.1.20/mysql-connector-java-5.1.20-bin.jar');
connection= database('2010_08_06_BearLab_Bhakar','cpuser','cPus3r','com.mysql.jdbc.Driver',...
    'jdbc:mysql://imgdb02/2010_08_06_BearLab_Bhakar');

%% Create datastructure to store extracted data

returnDict = HTS_dataDict(dataSelector);
dataSet = containers.Map;

dataSel = dataSelector ;
nGroups = dataSel.nGroups;
groupKeys = dataSel.getGroupDescriptions;


% Variables for Mysql db
db_table = plateType;%use plateType to define tables
tmp = struct;
tmp.dependentData = [];dep=dataSel.dependentVariable;
tmp.independentData = [];indep=dataSel.independentVariable;

% Create beginning part of query statements for independent and dependent
% variables 
beginsql1 = sprintf('Select %s FROM %s LEFT JOIN %s  ON %s.ImageNumber = %s.ImageNumber',...
   dep,db_table{1},metadata,metadata,db_table{1});
% Some analysis routines do not require a independent variable so only set 
% independent variable if analysis routine requires it
% If indepedent variable not required plateType{2} = ''; thus
% db_table{2}='';
if ~strcmp(db_table{2},'')
  beginsql2 = sprintf('Select %s FROM %s LEFT JOIN %s ON %s.ImageNumber = %s.ImageNumber ',...
   indep,db_table{2},metadata,metadata,db_table{2});
else
    beginsql2 = 0;
end
       
        
%Create SQL query
for iGrp = 1:nGroups %nGroups defined in beg of code
    grpKey = groupKeys{iGrp};
    grpProperties = dataSel.pairDefinitions(grpKey);
    % create WHERE clause for sql query 
    sql =[ ' WHERE ' ];
    for ii = 1:numel(grpProperties)
        pair = grpProperties{ii};
        
        if ii == numel(grpProperties)
            sql = [ ' ' sql pair{1} '=' '''' pair{2} '''' ' '];
        else
            sql = ['' sql pair{1} '=' '''' pair{2} ''''  ' AND '];
        end
    end 
    
% Extract data from database
    sqlquery = [beginsql1 ' ' sql];
    %fetch command use to retrieve data
    temp = cell2mat(fetch(connection,sqlquery));
    combinedDep = [tmp.dependentData;temp];
    tmp.dependentData = combinedDep;
    if ischar(beginsql2)
        sqlquery2 = [beginsql2 ' ' sql];
        temp= cell2mat(fetch(connection,sqlquery2));
        combinedIndep = [tmp.independentData;temp];
        tmp.independentData= combinedIndep;
    end
    dataSet(grpKey) = tmp; % set keys of dataSet 
end
% mysql_db the only 'file'/key for returnDict
returnDict('mysql_db') = dataSet; % return extracted data in returnDict





    

