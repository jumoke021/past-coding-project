function  platemap  = createPlateMapFile(theXLSFile,logFileDict,thekeyValue)
% Function creates plateMap needed to do image processing in # Name1 and 
% # Name2. Must give either unprocessed XLSFile or a processed wells
% XLS File !! 

% Note this file is not able to remove the appropriate rows but it will
% color any rows that have problems (need to be removed have markers
% switched etc, BLUE )

% v1.0   Williams   12 Mar. 2012     First trial of platemap

% Appropriate logFile Pulled 

if nargin == 2
    challengeKey = '';
end
    
% Check to make sure only well sheets are used to create plateMap; if not 
% terminate script

if strfind(theXLSFile,'well') == 0
    ME = MException('maketables:invalidFormat', 'XLSfile is not a wells xls file');
    throw(ME);
end
    
    switch challengeKey
       case ''
            % if keyValue not specified then find the key value
            logFile = evalin('base','logFile');
            sheet = evalin('base','sheet');
            % Find thekey for processed sheets 
            [pathParts,~] = regexp(theXLSFile,'/','split','start');
            processedfile = pathParts{end};

            if ismac
                warning('off','MATLAB:xlsread:ActiveX'); %suppress ActiveX warning
            end
            [~,tdata,~] = xlsread(logFile,sheet);

            % find key value 
            names = {processedfile(1:2),processedfile(1:3),...
                    processedfile(1:4)};
                for ii = 1:length(names)
                    if sum(strcmpi(names{ii},tdata(:,6)))== 1
                        thekeyindex = strcmpi(names{ii},tdata(:,6));
                    end
                end
            
            if ~exist('thekeyindex','var')
                %warning
                warning('createPlateMap:keyvalue','Please select correct logFile for file %s',theXLSFile);
            else
                thekeyValue = tdata{thekeyindex,7};
                logFileDict = logFileDict(thekeyValue);
            end
    end

    % Pull data from appropriate sheet
    [~,sheetnames] = xlsfinfo(theXLSFile);
    if sum(strcmp('Corrected',sheetnames))
        sheetname = 'Corrected';
    else
        sheetname = 'AutoCreate';
    end
    
    [~,~,data] = xlsread(theXLSFile,sheetname);
    
    % Use logFileDict to get plate,div & celltype information
    plate = logFileDict('Plate No.');
    div = logFileDict('DIV');
    cellType = logFileDict('Cell type');

    % Using processed sheets find well name, markers,genotype and treatment

    wells = data(3:end,1);
    % Fix names 
    dashIndex = strfind(wells,'-');
    for ii = 1:length(wells)
        well = wells{ii};
        platemap{ii,1} = well([1:dashIndex{ii}-2 (dashIndex{ii}+2):end]);
        platemap{ii,2} = thekeyValue;
        platemap{ii,4} = plate;
        platemap{ii,9} = cellType; % change to 9
        platemap{ii,8} = div;  % change to 8 

    end

    headers = data(2,:);
    for ii= 1:length(headers)
        if strcmpi('Marker',headers(ii))
            ii_marker = ii;
        elseif strcmpi('Genotype',headers(ii))
            ii_genotype = ii;
        elseif strcmp('Mouse',headers(ii))
            ii_mouse = ii;
        elseif strcmp('Trt',headers(ii))
            ii_trt = ii;
        end
    end

    % set markers, genotype, mouse and trt ment values 
    platemap(:,5) = data(3:end,ii_marker); % extract marker data
    
    % for plates with multiple markers separate markers 
    for ii = 1:length(platemap(:,5))
        if strcmpi('GluR1SV2',platemap(ii,5))
            platemap{ii,5} = 'SV2';
            platemap{ii,6} = 'GluR1';
        elseif strcmpi('SynGluR2',platemap(ii,5))
            platemap{ii,5} = 'Syn';
            platemap{ii,6} = 'GluR2';
        elseif strcmpi('GADGamma',platemap(ii,5))
            platemap{ii,5} = 'Gamma';
            platemap{ii,6} = 'GAD';
        elseif strcmpi('SV2GluR1',platemap(ii,5))
             platemap{ii,5} = 'SV2';
             platemap{ii,6} = 'GluR1';
        elseif strcmpi('GADGeph',platemap(ii,5))
             platemap{ii,5} = 'Geph';
             platemap{ii,6} = 'GAD';
        elseif strcmpi('SynPSD',platemap(ii,5))
             platemap{ii,5} = 'PSD';
             platemap{ii,6} = 'Syn';
        elseif strcmpi('PhysGluR1',platemap(ii,5))
             platemap{ii,5} = 'Phys';
             platemap{ii,6} = 'GluR1';
        elseif strcmpi('NeuNFos',platemap(ii,5))
             platemap{ii,5} = 'NeuN';
             platemap{ii,6} = 'cFos';
        end
    end
    
    % add genotype,mouse and treatment data
    platemap(:,7) = data(3:end,ii_genotype);%change 7 
    platemap(:,3) = data(3:end,ii_mouse);
    platemap(:,10) = data(3:end,ii_trt); % change 10 
    % Read previous data
    
    if ispc
        [~,~,data] = xlsread('plateMapAll3.xls','Sheet2');
        data(end+1:end+length(platemap),:) = platemap;
        xlswrite('plateMapAll3.xls',data,'Sheet2');
    elseif ismac
        csvCellWriter('PlateMapAll3.csv',data);
        warning('on','MATLAB:xlsread:ActiveX');
    end
end
