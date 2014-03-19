function varargout = FileSelector(varargin)
% Simple GUI to let Asha select which XLS files to process for high
% throughput analysis
%
%  v1.0    J.Gavornik    8 Jan 2011
%  v1.1    J.Gavornik    20 Jan 2011 - added ability to filter results
%  v1.2    J.Gavornik    14 March 2011 - update regexp matching algorithm

%#ok<*INUSD>
%#ok<*INUSL>
%#ok<*DEFNU>

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @FileSelector_OpeningFcn, ...
    'gui_OutputFcn',  @FileSelector_OutputFcn, ...
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

% --- Executes just before FileSelector is made visible.
function FileSelector_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for FileSelector
handles.output = hObject;

% Get the passed file list
if nargin > 3
    files = varargin{1};
    nFiles = numel(files);
    handles.files = files;
    handles.nFiles = nFiles;
    handles.filterIndici = true(1,nFiles);
    % Filter choices if a challenge string was passed
    if numel(varargin) > 1
        filterData = true;
        set(handles.filterStringField,'String',varargin{2});
    else
        filterData = false;
    end
else
    error('FileSelector usage: FileSelector(file_cell_array)');
end
% Populate the table
selections = cell(nFiles,1);
for ii = 1:nFiles
    selections{ii} = true;
end
data = [files' selections];
set(handles.tableView,'data',data,'ColumnEditable',[false true]);
% Create labels and size the columns
label1 = createColumnLabel('Files',files,2.1);
set(handles.tableView,'ColumnName',{label1 'Include'});

% Update handles structure and call functions to populate the table
guidata(hObject, handles);

if filterData
    filterString_Callback(hObject,[],handles);
end

uiwait(handles.figure1);


function varargout = FileSelector_OutputFcn(hObject, eventdata, handles)  %#ok<STOUT>
% This function intentionally does nothing so that uiwait doesn't screw
% things up - this is something of a hack
% varargout{1} = handles.output;

function pushbutton1_Callback(hObject, eventdata, handles)
% Return logical indici of selections back to the base workspace and close
% the GUI
data = get(handles.tableView,'data');
selection_indici = false(1,handles.nFiles);
filteredInd = find(handles.filterIndici);
nFiltered = numel(filteredInd);
for ii = 1:nFiltered
    selection_indici(filteredInd(ii)) = data{ii,2};
end
files = handles.files(selection_indici);
assignin('base','selection_indici',selection_indici);
assignin('base','selected_files',files);
uiresume(gcbf);
close(handles.figure1);

function selectDeselect_Callback(hObject, eventdata, handles)
switch hObject
    case handles.selectAllButton
        value = true;
    case handles.deselectAllButton
        value = false;
    otherwise
        error('selectDeselect_Callback: unknown object');
end
data = get(handles.tableView,'data');
for ii = 1:handles.nFiles
    data{ii,2} = value;
end
set(handles.tableView,'data',data);

function sizedLabel = createColumnLabel(label,cellArray,multiplier) %#ok<INUSL,STOUT>
if nargin == 2
    multiplier = 1;
end
maxChars = 0;
for ii = 1:numel(cellArray)
    charCnt = numel(cellArray{ii});
    if charCnt > maxChars
        maxChars = charCnt;
    end
end
cmdStr = sprintf('sizedLabel = sprintf(''%%%is%%s%%%is'','''',label,'''');',...
    floor(maxChars*multiplier/2),floor(maxChars*multiplier/2));
eval(cmdStr);

function filterString_Callback(hObject, eventdata, handles)
% Get the filter string from the gui
filterString = get(handles.filterStringField,'String');
if iscell(filterString)
    filterString = cell2mat(filterString);
end
handles.filterString = filterString;
% Update the filterIndici and call function to update the table
if isempty(filterString)
    % show all files
    handles.filterIndici = true(1,handles.nFiles);
else
    for ii = 1:handles.nFiles
        if regexp(handles.files{ii},filterString)
            handles.filterIndici(ii) = true;
        else
            handles.filterIndici(ii) = false;
        end
    end
end
guidata(hObject,handles);
updateTable(hObject);

function updateTable(hObject)
handles = guidata(hObject);
% Regenerate data array
selections = cell(handles.nFiles,1);
for ii = 1:handles.nFiles
    selections{ii} = true;
end
data = [handles.files' selections];
% Remove filtered items
data = data(handles.filterIndici,:);
set(handles.tableView,'data',data);
label1 = createColumnLabel('Files',handles.files,2.1);
set(handles.tableView,'ColumnName',{label1 'Include'});
