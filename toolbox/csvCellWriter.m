function csvCellWriter(filename,cellMat)
% Writes all data in a cell matrix to a file separated by commas
% Leaves doubles with value NaN empty
%
%  v1.0    J.Gavornik    8 Jan 2011
%  v1.1    J.Gavornik    17 Feb 2011 Replace commas in char strings

[rows,cols] = size(cellMat);

fid = fopen(filename ,'Wb');

for row = 1:rows
    for col = 1:cols
        data = cellMat{row,col};
        if ~isempty(data)
            switch class(data)
                case {'double' 'single'}
                    % If there is no difference between the float and int
                    % representation of the data, format print statement as an
                    % integer.  Otherwise, format as a float.
                    if ~isnan(data)
                        integerVersion = cast(data,'int32');
                        diff = data - cast(integerVersion,'double');
                        if diff > 0
                            fprintf(fid,'%g',data);
                        else
                            fprintf(fid,'%i',data);
                        end
                    end
                case 'char'
                    data = regexprep(data,',',' '); % get rid of any commas
                    fprintf(fid,'%s',data);
                otherwise
                    fprintf(fid,'nan');
            end
        end
        if col == cols
            fprintf(fid,'\n');
        else
            fprintf(fid,',');
        end
    end
end

fclose(fid);