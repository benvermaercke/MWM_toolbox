clear all
clc

% Define an xls name
%fileName = 'test_xlwrite.xlsx';
%fileName = 'test.xls';
%fileName = 'test.xlsx';
fileName = 'Tine_Disconnection_Acquisition (Trial     2).xls';
%fileName = 'Tine_Disconnection_Acquisition (Trial     2).xlsx';

% methodsview org.apache.poi.xssf.usermodel.XSSFWorkbook

%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
javaaddpath('poi_library/poi-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-schemas-3.8-20120326.jar');
javaaddpath('poi_library/xmlbeans-2.3.0.jar');
javaaddpath('poi_library/dom4j-1.6.1.jar');
javaaddpath('poi_library/stax-api-1.0.1.jar');

% Check if POI lib is loaded
if exist('org.apache.poi.ss.usermodel.WorkbookFactory', 'class') ~= 8 ...
        || exist('org.apache.poi.hssf.usermodel.HSSFWorkbook', 'class') ~= 8 ...
        || exist('org.apache.poi.xssf.usermodel.XSSFWorkbook', 'class') ~= 8
    
    error('xlWrite:poiLibsNotLoaded',...
        'The POI library is not loaded in Matlab.\nCheck that POI jar files are in Matlab Java path!');
end

% Import required POI Java Classes
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.xssf.usermodel.*;
import org.apache.poi.ss.usermodel.*;

import org.apache.poi.ss.util.*;

% Set java path to same path as Matlab path
java.lang.System.setProperty('user.dir', pwd);

% Open a file
xlsFile = java.io.File(fileName);

%%
if xlsFile.isFile()
    fileIn = java.io.FileInputStream(xlsFile);
    xlsWorkbook = WorkbookFactory.create(fileIn);
else
    [~,~,ext]=fileparts(fileName);
    switch ext
        case '.xls'
            xlsWorkbook = HSSFWorkbook();
        case '.xlsx'
            xlsWorkbook = XSSFWorkbook();
    end
end

tic
nSheets=xlsWorkbook.getNumberOfSheets();
raw_data=cell(0,0);
dataMatrix=struct;
if nSheets==0
    disp('No sheets found...')
else
    xlsSheet = xlsWorkbook.getSheetAt(nSheets-1);
    nRows=xlsSheet.getLastRowNum;
    data_counter=0;
    for iRow=0:nRows
        current_row=xlsSheet.getRow(iRow);
        nCols=current_row.getLastCellNum()-1;
        
        %%% check value in first column
        row_type=current_row.getCell(0).getCellType();
        if row_type==1&&nCols>2
            row_type=2;
        end
        
        switch row_type
            case 0 % num data
                data_counter=data_counter+1;
                for iCol=0:nCols
                    current_cell=current_row.getCell(iCol);
                    cell_type=current_cell.getCellType();
                    switch cell_type
                        case 0
                            cell_content=str2double(current_cell.getRawValue());
                        case 1
                            cell_content=NaN;
                        otherwise
                            die
                    end
                    dataMatrix.data(data_counter,iCol+1)=cell_content;
                end
            case 1 % parameters
                current_cell=current_row.getCell(0);
                cell_type=current_cell.getCellType();
                switch cell_type
                    case 0
                    case 1
                        parameter=char(current_cell.getStringCellValue());
                    case 3
                        % skip line, next is fieldnames and data
                end
                
                if nCols>0
                    current_cell=current_row.getCell(1);
                    cell_type=current_cell.getCellType();
                    switch cell_type
                        case 0 % num
                            value=str2double(current_cell.getRawValue());
                        case 1 % str
                            value=char(current_cell.getStringCellValue());
                        case 3 % empty
                            value=[];
                    end
                    parameter=strrep(parameter,' ','_');
                    parameter=strrep(parameter,'-','_');
                    parameter=strrep(parameter,'<','');
                    parameter=strrep(parameter,'>','');
                    info.(parameter)=value;
                    %value
                end
            case 2 % fieldnames
                for iCol=0:nCols
                    current_cell=current_row.getCell(iCol);
                    dataMatrix.fieldNames{iCol+1}=char(current_cell.getStringCellValue());
                end
            case 3 % empty
        end
    end
end
toc

