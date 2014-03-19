%% Launch app to choose files for analysis
allFiles = find_xls_files('.');
FileSelector(allFiles);
 
%clear
%selected_files = './LDDN3/LDDN3Excel020311';
%selected_files='./nfsheets/AP15NFc14Synap 4_field';

%% Choose parameters for data selection

% Create the dataSelectionObject
dataSelector = dataSelectionObject;
%dataSelector.setDependentVariable('Total Puncta 2');
%dataSelector.setIndependentVariable('Total Puncta 2');
dataSelector.setDependentVariable('Div');
dataSelector.setIndependentVariable('Neuronal Phenotype Neuron (n)');
%dataSelector.setDependentVariable('Nuclei Nuc Intensity CV');
%dataSelector.setIndependentVariable('Cell Count');
%dataSelector.setDependentVariable('Puncta Intensity Per Neuron 2');
%dataSelector.setIndependentVariable('Total Puncta Intensity 2');
%dataSelector.setDependentVariable('Cy5 Puncta Count');
%dataSelector.setIndependentVariable('Co-Localized Overlap Count');

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
grp.addPair('Genotype','WT');
%grp.addPair('DIV','14');
% grp.addPair('Marker','SynGluR2');
grp.addPair('Marker','NeuNFos');
%grp.addPair('Cell Type','h');
grp.setPlotColor(RGBColor('Black'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('Knock Out');
grp.addPair('Genotype','KO');
%grp.addPair('DIV','14');
% grp.addPair('Marker','SynGluR2');
grp.addPair('Marker','NeuNFos');
%grp.addPair('Cell Type','h');
grp.setPlotColor(RGBColor('Red'));
dataSelector.addGroupDef(grp);

%grp = groupDef;
%grp.setDescription('Wild Type High');
%grp.addPair('Genotype','WT');
%grp.addPair('Trt','MP');
%grp.addPair('Marker','SynGluR2');
%grp.addPair('Neuronal Phenotype Neuron (n)','>30');
%grp.setPlotColor(RGBColor('Light Slate Gray'));
%dataSelector.addGroupDef(grp);

% grp = groupDef;
% grp.setDescription('Knock Out High');
% grp.addPair('Genotype','KO');
% grp.addPair('Marker','SynGluR2');
% grp.addPair('Neuronal Phenotype Neuron (n)','>30'); 
% grp.setPlotColor(RGBColor('Salmon'));
% dataSelector.addGroupDef(grp);

%grp = groupDef;
%grp.setDescription('Knock Out');
%grp.addPair('Genotype','KO');
%grp.setPlotColor(RGBColor('Red'));
%dataSelector.addGroupDef(grp);

% grp = groupDef;
% grp.setDescription('Knock Out +MP');
% grp.addPair('Genotype','KO');
% grp.addPair('Trt','MP');
% grp.setPlotColor(RGBColor('Light Salmon'));
% dataSelector.addGroupDef(grp);


% grp = groupDef;
% grp.setDescription('Knock Out+CTL');
% grp.addPair('Genotype','KO');
% grp.addPair('Trt','CTL');
% grp.setPlotColor(RGBColor('Light Salmon'));
% dataSelector.addGroupDef(grp);
% 
% grp = groupDef;
% grp.setDescription('Knock Out +Bic');
% grp.addPair('Genotype','KO');
% grp.addPair('Trt','Bic');
% grp.setPlotColor(RGBColor('Light Salmon'));
% dataSelector.addGroupDef(grp);

%{
grp = groupDef;
grp.setDescription('WildType+TTX+APV');
grp.addPair('Genotype','WT');
grp.addPair('Trt','TTX+APV');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('dark slate gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('WildType+Veh');
grp.addPair('Genotype','WT');
grp.addPair('Trt','Veh');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('light slate gray'));
dataSelector.addGroupDef(grp);


grp = groupDef;
grp.setDescription('WildType+Bic');
grp.addPair('Genotype','WT');
grp.addPair('Trt','Bic');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('light gray'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('KnockOut+TTX+APV');
grp.addPair('Genotype','KO');
grp.addPair('Trt','TTX+APV');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('tomato'));
dataSelector.addGroupDef(grp);

grp = groupDef;
grp.setDescription('KnockOut+Veh');
grp.addPair('Genotype','KO');
grp.addPair('Trt','Veh');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('light coral'));
dataSelector.addGroupDef(grp);

grp = groupDef;   
grp.setDescription('KnockOut+Bic');
grp.addPair('Genotype','KO');
grp.addPair('Trt','Bic');
grp.addPair('Marker','NeuNFos');
grp.setPlotColor(RGBColor('light salmon'));
dataSelector.addGroupDef(grp);
%}
% grp = groupDef;
% grp.setDescription('Knock Out No Treatment');
% grp.addPair('Genotype','KO');
% grp.addPair('Trt','-');
% grp.addPair('Marker','NeuNFos');
% grp.setPlotColor(RGBColor('Red'));
% dataSelector.addGroupDef(grp);
% grp = groupDef;
% grp.setDescription('Knock Out +TTX+APV');
% grp.addPair('Genotype','KO');
% grp.addPair('trt','TTX+APV');
% grp.setPlotColor(RGBColor('Dark Violet'));
% dataSelector.addGroupDef(grp);
% % 
% % grp = groupDef;
% % grp.setDescription('Wild Type +GluR2');
% % grp.addPair('Genotype','WT');
% % grp.addPair('Marker','GluR2');
% % grp.setPlotColor(RGBColor('cornflower blue'));
% % dataSelector.addGroupDef(grp);
% % 
% % grp = groupDef;
% % grp.setDescription('Knock Out +GluR2');
% % grp.addPair('Genotype','KO');
% % grp.addPair('Marker','GluR2');
% % grp.setPlotColor(RGBColor('goldenrod'));
% % dataSelector.addGroupDef(grp);
% 

% Call a function that will use the data selector to extract data from the
% selected files
 dataDict = HTS_GroupDataExtract(dataSelector,selected_files);

 % Open a viewer to let the user see the extracted data
dataDictViewer(dataDict);

%% Pass extracted data to analysis routines

 statsStruct1 = HTS_distributionTest(dataDict,'InPlate');
%  [statsStruct2,var1] = HTS_tTest(dataDict,'InPlate'); % add ,true if want to save files
%  statsStruct3 = HTS_regressionCoincidenceTest(dataDict,'CrossPlate');