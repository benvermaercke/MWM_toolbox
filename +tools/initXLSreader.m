function initXLSreader

%%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
javaaddpath('+tools/poi_library/poi-3.8-20120326.jar');
javaaddpath('+tools/poi_library/poi-ooxml-3.8-20120326.jar');
javaaddpath('+tools/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
javaaddpath('+tools/poi_library/xmlbeans-2.3.0.jar');
javaaddpath('+tools/poi_library/dom4j-1.6.1.jar');
javaaddpath('+tools/poi_library/stax-api-1.0.1.jar');

% Check if POI lib is loaded
if exist('org.apache.poi.ss.usermodel.WorkbookFactory', 'class') ~= 8 ...
        || exist('org.apache.poi.hssf.usermodel.HSSFWorkbook', 'class') ~= 8 ...
        || exist('org.apache.poi.xssf.usermodel.XSSFWorkbook', 'class') ~= 8
    
    error('xlWrite:poiLibsNotLoaded',...
        'The POI library is not loaded in Matlab.\nCheck that POI jar files are in Matlab Java path!');
end


