function formatFigures(titleStr,gca,nDataSets,iData,dataSel,Fontsize,numOfaxes)
%% Used to format figures generated in subplot figure; 


if nargin == 6
    numOfaxes = 1;% numOfaxes corresponds to whether a dependent and 
                  % indepdent variables are being graphed 
end
        if strfind(titleStr,'_') ~= 0
            titleStr = regexprep(titleStr, '_', '/_');
            if nDataSets ~=1 && iData ~= nDataSets
                [parseTitleStr]=regexp(titleStr,'/','split');
    % %             [newTitleStr] = regexp(parseTitleStr{end-1},'\w\w[1-9999]\d','split');
                newTitleStr = parseTitleStr{end-1};
    %             newTitleStr = newTitleStr{1};
                title(newTitleStr(1:4),'fontsize',Fontsize);
            else
                title(titleStr,'fontsize',Fontsize);
            end
        else
            title(titleStr,'fontsize',Fontsize);
        end
        
        % Axes Label
        ylabel(dataSel.dependentVariable,'fontsize',Fontsize);
        set(gca,'PlotBoxAspectRatio',[1 1 1],'Box','off');
        switch numOfaxes
            case 1
                set(gca,'XTickLabel',{})
                set(gca,'XTick',[]);
                set(gca,'XTickLabelMode','manual')
                set(gca,'TickDir','out')
            case 2
                xlabel(dataSel.independentVariable,'fontsize',6);
                set(gca,'TickDir','out')
                set(gca,'Box','on');
        end
        
        set(gca,'FontSize',Fontsize);
        hold(gca,'off');
end