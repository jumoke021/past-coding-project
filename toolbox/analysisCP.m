%% Launch app to choose files for analysis
allFiles = find_xls_files('.');
FileSelector(allFiles);

% %% 
%clear
%selected_files = './LDDN3/LDDN3Excel020311';

%% Choose parameters for data selection

% Create the dataSelectionObject
dataSelector = dataSelectionObject;
dataSelector.setDependentVariable('Image_Count_PunctaObj');
dataSelector.setIndependentVariable('Image_Count_Nuclei');

% Create group definitions and add to the dataSelector

%grp = groupDef;
%grp.setDescription('Wild Type');
%grp.addPair('Genotype','WT');
%grp.addPair('Neuronal Phenotype Neuronal (n)','>5');
%grp.addPair('Organelles Intensity','<=175');
%grp.setPlotColor(RGBColor('Black'));
%dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type');
grp.addPair('Genotype','A');
grp.addPair('Marker','Syn');
grp.setPlotColor(RGBColor('Black'));
dataSelector.addGroupDef(grp);

%grp = groupDef;
%grp.setDescription('Wild Type + MP');
%grp.addPair('Genotype','WT');
%grp.addPair('Trt','MP');
%grp.setPlotColor(RGBColor('Light Slate Gray'));
%dataSelector.addGroupDef(grp);

%grp = groupDef;
%grp.setDescription('Knock Out');
%grp.addPair('Genotype','KO');
%grp.setPlotColor(RGBColor('Red'));
%dataSelector.addGroupDef(grp);

%grp = groupDef;
%grp.setDescription('Knock Out +MP');
%grp.addPair('Genotype','KO');
%grp.addPair('Trt','MP');
%grp.setPlotColor(RGBColor('Light Salmon'));
%dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out');
grp.addPair('Genotype','B');
grp.addPair('Marker','Syn');
grp.setPlotColor(RGBColor('Red'));
dataSelector.addGroupDef(grp);

% grp = groupDef;
% grp.setDescription('Wild Type +GluR1');
% grp.addPair('Genotype','WT');
% grp.addPair('Marker','GluR1');
% grp.setPlotColor(RGBColor('Salmon'));
% dataSelector.addGroupDef(grp);
% 
% grp = groupDef;
% grp.setDescription('Knock Out +GluR1');
% grp.addPair('Genotype','KO');
% grp.addPair('Marker','GluR1');
% grp.setPlotColor(RGBColor('Dark Violet'));
% dataSelector.addGroupDef(grp);
% 
% grp = groupDef;
% grp.setDescription('Wild Type +GluR2');
% grp.addPair('Genotype','WT');
% grp.addPair('Marker','GluR2');
% grp.setPlotColor(RGBColor('cornflower blue'));
% dataSelector.addGroupDef(grp);
% 
% grp = groupDef;
% grp.setDescription('Knock Out +GluR2');
% grp.addPair('Genotype','KO');
% grp.addPair('Marker','GluR2');
% grp.setPlotColor(RGBColor('goldenrod'));
% dataSelector.addGroupDef(grp);

% Call a function that will use the data selector to extract data from the
% selected files
dataDict = HTS_GroupDataExtract(dataSelector,selected_files);

% Open a viewer to let the user see the extracted data
dataDictViewer(dataDict);
    
%% Pass extracted data to analysis routines
statsStruct1 = HTS_distributionTest(dataDict,'InPlate');
[statsStruct2,var1] = HTS_tTest(dataDict,'InPlate');
statsStruct3 = HTS_regressionCoincidenceTest(dataDict,'InPlate');