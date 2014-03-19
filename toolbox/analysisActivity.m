%% Launch app to choose files for analysis
allFiles = find_xls_files('.');
FileSelector(allFiles);

% %% 
%clear
%selected_files = './LDDN3/LDDN3Excel020311';

%% Choose parameters for data selection

% Create the dataSelectionObject
dataSelector = dataSelectionObject;
dataSelector.setDependentVariable('Total Puncta 2');
dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');
%dataSelector.setDependentVariable('Puncta 2 per Neuron');
%dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');
%dataSelector.setDependentVariable('Total Puncta Intensity 2');
%dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');
%dataSelector.setDependentVariable('Puncta Intensity Per Neuron 2');
%dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');

% Create group definitions and add to the dataSelector

grp = groupDef;
grp.setDescription('Wild Type + -');
grp.addPair('Genotype','WT');
grp.addPair('Trt','-');
%grp.addPair('Marker','SynGluR2');
grp.setPlotColor(RGBColor('Black'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type + CTL');
grp.addPair('Genotype','WT');
grp.addPair('Trt','CTL');
grp.setPlotColor(RGBColor('Light Slate Gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type + NMDA');
grp.addPair('Genotype','WT');
grp.addPair('Trt','NMDA');
grp.setPlotColor(RGBColor('Light Slate Gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type + Veh');
grp.addPair('Genotype','WT');
grp.addPair('Trt','Veh');
grp.setPlotColor(RGBColor('Dim Gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type + TTXAPV');
grp.addPair('Genotype','WT');
grp.addPair('Trt','TTX+APV');
grp.setPlotColor(RGBColor('Dim Gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Wild Type + Bic');
grp.addPair('Genotype','WT');
grp.addPair('Trt','Bic');
grp.setPlotColor(RGBColor('Dim Gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + -');
grp.addPair('Genotype','KO');
grp.addPair('Trt','-');
grp.setPlotColor(RGBColor('Red'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + CTL');
grp.addPair('Genotype','KO');
grp.addPair('Trt','CTL');
grp.setPlotColor(RGBColor('Salmon'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + NMDA');
grp.addPair('Genotype','KO');
grp.addPair('Trt','NMDA');
grp.setPlotColor(RGBColor('Salmon'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + Veh');
grp.addPair('Genotype','KO');
grp.addPair('Trt','Veh');
grp.setPlotColor(RGBColor('Firebrick'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + TTXAPV');
grp.addPair('Genotype','KO');
grp.addPair('Trt','TTX+APV');
grp.setPlotColor(RGBColor('Firebrick'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out + Bic');
grp.addPair('Genotype','KO');
grp.addPair('Trt','Bic');
grp.setPlotColor(RGBColor('Firebrick'));
dataSelector.addGroupDef(grp);

% grp.setPlotColor(RGBColor('Dark Violet'));
% grp.setPlotColor(RGBColor('goldenrod'));

% Call a function that will use the data selector to extract data from the
% selected files
dataDict = HTS_GroupDataExtract(dataSelector,selected_files);

% Open a viewer to let the user see the extracted data
dataDictViewer(dataDict);
    
%% Pass extracted data to analysis routines
%statsStruct1 = HTS_distributionTest(dataDict,'CrossPlate');
[statsStruct2,var1] = HTS_tTest(dataDict,'InPlate');
%statsStruct3 = HTS_regressionCoincidenceTest(dataDict,'CrossPlate');