function [dataMatrix, TrackInfo]=readXLSdata(varargin)

if nargin>=1
    fileName=varargin{1};
end

if nargin>=2
    nCols_req=varargin{2};
else
    nCols_req=inf;
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

if xlsFile.isFile()
    fileIn = java.io.FileInputStream(xlsFile);
    xlsWorkbook = WorkbookFactory.create(fileIn);
else
    error('File does not exist')
end

nSheets=xlsWorkbook.getNumberOfSheets();
if nSheets==0
    disp('No sheets found...')
else
    xlsSheet = xlsWorkbook.getSheetAt(nSheets-1);
    nRows=xlsSheet.getLastRowNum;
    
    %%% Pre allocate dataMatrix
    dataMatrix=struct('data',zeros(nRows,nCols_req-1),'fieldNames','');
    data_counter=0;
    for iRow=0:nRows
        current_row=xlsSheet.getRow(iRow);
        nCols=current_row.getLastCellNum()-1;
        
        %%% check value in first column
        row_type=current_row.getCell(0).getCellType();
        if row_type==1&&nCols>2
            row_type=2;
        end
        nCols_read=min([nCols_req-1 nCols]);
        
        switch row_type
            case 0 % num data
                data_counter=data_counter+1;
                for iCol=0:nCols_read
                    current_cell=current_row.getCell(iCol);
                    cell_type=current_cell.getCellType();
                    switch cell_type
                        case 0
                            %cell_content=str2double(current_cell.getRawValue());
                            cell_content=current_cell.getNumericCellValue();
                        case 1
                            cell_content=NaN;
                        otherwise
                            error('Unknown cell type...')
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
                            value=current_cell.getNumericCellValue();
                        case 1 % str
                            value=char(current_cell.getStringCellValue());
                        case 3 % empty
                            value=[];
                        otherwise
                            error('Unknown cell type...')
                    end
                    parameter=strrep(parameter,' ','_');
                    parameter=strrep(parameter,'-','_');
                    parameter=strrep(parameter,'<','');
                    parameter=strrep(parameter,'>','');
                    TrackInfo.(parameter)=value;
                end
            case 2 % fieldnames                
                for iCol=0:nCols_read
                    current_cell=current_row.getCell(iCol);
                    dataMatrix.fieldNames{iCol+1}=char(current_cell.getStringCellValue());
                end
            case 3 % empty
        end
    end
    %%% prune data matrix
    dataMatrix.data(data_counter+1:end,:)=[];
end

