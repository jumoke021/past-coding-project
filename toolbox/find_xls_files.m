function xls_files = find_xls_files(root_dir)
%
% Function to return a 1xN cell array with paths to all .xls files in
% subdirectories below the some root directory.  
% By default, root is current working directory determined by pwd
% Root can be specified by an optional input argument
%
% Usage: xls_files = find_xls_files(root_dir)
%
% For example, assume that below the root directory are two folders called
% 'folder_1' and 'folder_2' and that there are subfolders called 'sub_1'
% and 'sub_2' inside of folder_1 and that there are  xls files inside
% each of these 3 sub folders called data.xls.  Given the command 
% xls_files = find_xls_files('.');
%   xls_files{1} = './folder_1/sub_1/data.xls'
%   xls_files{2} = './folder_1/sub_2/data.xls'
%   xls_files{3} = './folder_2/data.xls'
%
% Note: finds any files that end with .xls or .XLS
%
%   v1.0    J.Gavornik    8 Jan 2011

if nargin == 0
    root_dir = pwd;
end
xls_files = {};
diveDeep(root_dir);
    
    % Define a recursive search algorithm that follows all sub-directories
    % looking for .xls files
    function diveDeep(aRootDir)
        listing = dir(aRootDir);
        nF = numel(listing); % number of files/folders
        for ii = 1:nF
            aName = listing(ii).name;
            if ~strncmp('.',aName,1) % Ignore dot files
                if ~listing(ii).isdir
                    iStr = strfind(lower(aName),'.xls');
                    if ~isempty(iStr)
                        if iStr == length(aName) - 3 % .xls at the end
                            % This is an .xls file so add it
                            theFilePath = sprintf('%s/%s',aRootDir,aName);
                            % fprintf('File Found: %s\n',theFilePath);
                            xls_files{end+1} = theFilePath; %#ok<AGROW>
                        end
                    end
                else
                   aDirectoryPath = sprintf('%s/%s',aRootDir,aName);
                   % fprintf('Diving into directory: %s\n',aDirectoryPath);
                   diveDeep(aDirectoryPath);
                end
            end            
        end
    end

end

