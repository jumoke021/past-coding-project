classdef HTS_dataDict < containers.Map
    
    properties
        dataSelector;
    end
    
    methods 
        
        function obj = HTS_dataDict(dataSelector)
            obj.dataSelector = dataSelector;
        end
        
    end
    
end
          