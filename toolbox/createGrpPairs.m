function [dataSelector,iteratePair] = createGrpPairs(dataSelector,pairs,descriptions,mode)
% Automatically creates grps based on pairs defined in analysisBasalActivity
% v1.0   Williams       2/5/2012

if ~ischar(mode)
    error('Please enter a string\n');
end

  pairskeys = pairs.keys;
  keyslength = length(pairskeys);% to index into keys of pairs 
  
% Colors for WT and KO 
if strcmpi(mode,'noalternate')
        WTColors = {'black','light slate gray','light slate gray','dim gray',...
            'dim gray','dim gray','dim gray','dim gray','dim gray','dim gray'};
        KOColors = {'red','salmon','salmon','Firebrick','Firebrick','Firebrick',...
            'Coral','Coral','Coral','Coral'};
%     WTColors = {'black','light slate gray','black','light slate gray',...
%         'black','light slate gray','black','light slate gray','black','light slate gray',...
%         'black','light slate gray','black','light slate gray','black','light slate gray',};
%     KOColors = {'red','salmon','red','salmon','red','salmon','red','salmon',...
%         'red','salmon','red','salmon','red','salmon','red','salmon','red','salmon',...
%         'red','salmon','red','salmon','red','salmon','red','salmon'};
    Colors = {WTColors,KOColors};
else
    Colors = {{'black','black','black','black','black'},....
{'red','red','red','red','red'}};
end

  %Find pairs with longest elements
  for ii = 1:length(pairskeys)
      maxLength = max(1,length(pairs(pairskeys{ii})));
      if maxLength == length(pairs(pairskeys{ii}))
          iteratePair = pairskeys{ii};
      end
  end

  % Place all information into grp object defined by Jeff
  nGroups =1;pkeys =1;
  keyIndex =ones(1,keyslength);

for numberofkeys=1:keyslength
    keyIndex(numberofkeys) = 1;%initialize variable
end

while nGroups < length(descriptions)+1
    for ii = 1:2
        
        if strcmpi('alternate',mode)
            new_ii = ii;
        elseif strcmpi('noalternate',mode)
            if nGroups <= (length(descriptions)/2)
                new_ii=1; % Assign WT genotype
            else
                 new_ii = 2; % Assign KO genotype
            end
        end
        
        grp = groupDef;
        grp.setDescription(descriptions{nGroups})
        
        for pkeys=1:keyslength
            values = pairs(pairskeys{pkeys});
         
            while keyIndex(pkeys)<= length(values)
                    
                    if sum(strcmpi('WT',values))
                        grp.addPair(pairskeys{pkeys},values{new_ii})
                    else
                        grp.addPair(pairskeys{pkeys},values{keyIndex(pkeys)})
                    end

                    if strcmp(pairskeys{pkeys},iteratePair)
                         grp.setPlotColor(RGBColor(Colors{new_ii}{keyIndex(pkeys)}));
                    end

                    if strcmp(mode,'alternate')
                        if new_ii == 2 
                             keyIndex(pkeys) = keyIndex(pkeys)+1;
                        end
                    else
                         keyIndex(pkeys) = keyIndex(pkeys)+1;
                    end

                    if keyIndex(pkeys) == length(values)+1
                        keyIndex(pkeys) = 1;
                    end

                   break; 
            end
        end

        nGroups = nGroups+1;
        dataSelector.addGroupDef(grp);  
    
    end
end  