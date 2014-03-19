function reportStats(statsStruct,FID)
% Williams 18 Feb.2012: Changed so that data is only printed xls sheet which
%                        opens after all data has been written into it. 
% Williams 14 Mar.2012: Changed so only prints to csv sheets

if nargin < 2
    FID = 1;
end


fprintf(FID,'\n------------------------------------\n');
fprintf(FID,'Statistics report\nTest type = %s\n',statsStruct.testType);
statsRep ={};

for ii = 1:numel(statsStruct.results)
    theDict = statsStruct.results{ii};
    keys = theDict.keys;
    fprintf('Statistics report for files %s\n',theDict('dataSource'));
    statsRep{(2*ii-1),1} = sprintf('dataSource:%s',theDict('dataSource'));
    fprintf('\n''%s''\n',theDict('dataSource'));
    for jj = 1:numel(keys)
        theKey = keys{jj};
        if ~strcmp(theKey,'dataSource')
            strct = theDict(theKey);
            fprintf('   ''%s'': h = %i , p = %f\n',theKey,strct.h,strct.p);
            if strcmp('Multiple Files',theDict('dataSource'))
              statsRep{(2*jj),2}    = sprintf('''%s'':',theKey); 
              statsRep{(2*jj),3} = sprintf('h=%i',strct.h);
              statsRep{(2*jj),4} = sprintf('p=%f',strct.p); 
            else
              statsRep{(2*ii),2}    = sprintf('''%s'':',theKey); 
              statsRep{(2*ii),3} = sprintf('h=%i',strct.h);
              statsRep{(2*ii),4} = sprintf('p=%f',strct.p);      
            end
        end
    end
end
fprintf(FID,'------------------------------------\n');

%Use to determine if statistics should be printed
printToFile = evalin('caller','printToFile');

if printToFile{2}
    if exist('Statistics','dir')~=7
        mkdir('Statistics');
    end    
    wbkName = evalin('caller','wbkName'); % Write results to a csv file
    csvCellWriter(wbkName,statsRep);
end
    



