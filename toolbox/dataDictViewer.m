function varargout = dataDictViewer(varargin)
% Show the contents of a dataDict produced by HTS_GroupDataExtract and
% allow the user to export it to an xls (or csv) file
%
% handle = dataDictViewer(dataDict);
%
%  v1.0    J.Gavornik    12 March 2011
%  v1.1    J.Gavornik    10 May 2011 - Fix indexing to include header rows,
%                                      Update width of columns to fit data

%#ok<*DEFNU>
%#ok<*INUSD>
%#ok<*INUSL>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dataDictViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @dataDictViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before dataDictViewer is made visible.
function dataDictViewer_OpeningFcn(hObject, eventdata, handles, varargin) 
    
% Choose default command line output for dataDictViewer
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);

set(handles.slider,'Visible','off');

if numel(varargin)
    dataDict = varargin{1};
    if isa(dataDict,'HTS_dataDict')
        dataDictViewer('addDataDict',hObject,dataDict)
    else
        error('dataDictViewer: requires HTS_dataDict');
    end
end

function addDataDict(hObject,dataDict)
handles = guidata(hObject);
handles.dataDict = dataDict;
handles.dataSources = dataDict.keys;
handles.index = 1;
nSources = numel(handles.dataSources);
if nSources > 1
    set(handles.slider,'Min',1,'Max',nSources,...
        'Value',1,'SliderStep',[1/(nSources-1) 1/(nSources-1)]);
    set(handles.slider,'Visible','on');
    % This sets up a listener to handle continuous plot updates for the slider
    handles.slideListener = handle.listener(handles.slider,'ActionEvent',...
        @slider_listener_callBack);
end
dataSel = dataDict.dataSelector;
handles.depVarName = dataSel.dependentVariable;
handles.indepVarName = dataSel.independentVariable;
guidata(hObject,handles);
updateTable(hObject);

function updateTable(hObject)
% Create a table of data based on the current selection
handles = guidata(hObject);
theSource = handles.dataSources{handles.index};
set(handles.dataSrcTxt,'String',theSource);
data = handles.dataDict(theSource);
groups = data.keys;
nGroups = numel(groups);
nCols = 2*nGroups;
dataCell = cell(500,nCols);
nRows = 0;
for iGrp = 1:nGroups
    theData = data(groups{iGrp});
    depData = theData.dependentData;
    indData = theData.independentData;
    nData = numel(depData);
    col = 2*(iGrp-1)+1;
    dataCell{1,col} = groups{iGrp};
    dataCell{2,col} = handles.indepVarName;
    dataCell{2,col+1} = handles.depVarName;
    for iD = 1:nData
        dataCell{iD+2,col} = indData(iD);        
        dataCell{iD+2,col+1} = depData(iD);
    end
    if nData > nRows
        nRows = nData;
    end
end
% Figure out how wide to make the columns - multiplication by 7 selected
% heurestically to make characters fit in the resized column
colWidths = cell(1,nCols);
for iCol = 1:nCols
    colWidths{iCol} = ...
        7*max([numel(dataCell{1,iCol}) numel(dataCell{2,iCol})]);
end
% Update the GUI
set(handles.uitable1,'Data',dataCell(1:nRows+2,:),... % +2 for header rows
    'ColumnWidth',colWidths); 

% --- Outputs from this function are returned to the command line.
function varargout = dataDictViewer_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on button press in exportButton.
function exportButton_Callback(hObject, eventdata, handles)
theSource = handles.dataSources{handles.index};
parts = regexp(theSource,'/','split');
srcName = parts{end};
srcName = regexprep(srcName,'.xls','');
if ispc
    [name,path] = uiputfile('*.xls','Export Extracted Data',srcName);
    outputFile = sprintf('%s%s',path,name);
    % Write file results to a xls file
    warning('off','MATLAB:xlswrite:AddSheet'); % supress sheet warning
    [success,message]=xlswrite(outputFile,...
        get(handles.uitable1,'Data'),'ExtractedData');
    warning('on','MATLAB:xlswrite:AddSheet');
    if ~success
        fprintf('%s\n',message.message);
        warning('dataDictViewer.exportButton_Callback: xlswrite failed for %s',theSource); %#ok<WNTAG>
    end
elseif ismac
    [name,path] = uiputfile('*.csv','Export Extracted Data',srcName);
    outputFile = sprintf('%s%s',path,name);
    % Write out results to a csv file
    csvCellWriter(outputFile,get(handles.uitable1,'Data'));
end

% Handles mouse clicks on any elements of the slider in a discreet manner
function slider_Callback(hObject, eventData, handles) 
newIndex = round(get(hObject,'Value'));
handles = guidata(hObject);
if newIndex ~= handles.index
    handles.index = newIndex;
    guidata(hObject,handles);
    updateTable(hObject);
end

% Responds to listener callbacks so that slider movement is handled in a
% continuous manner
function slider_listener_callBack(hObject, eventData)
newIndex = round(get(hObject,'Value'));
handles = guidata(hObject);
if newIndex ~= handles.index
    handles.index = newIndex;
    guidata(hObject,handles);
    updateTable(hObject);
end
