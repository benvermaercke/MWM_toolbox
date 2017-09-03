function [dataMatrix, TrackInfo]=readXLSdata(varargin)

if nargin>=1
    fileName=varargin{1};
end

if nargin>=2 && ~isempty(varargin{2})
    cols_req=varargin{2};
else
    cols_req=inf;
end

nCols_req=length(cols_req);

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
    %%% Pre allocate dataMatrix
    dataMatrix=struct('data',zeros(1,nCols_req),'fieldNames','');
    for iSheet=1:nSheets
        xlsSheet = xlsWorkbook.getSheetAt(iSheet-1);
        nRows=xlsSheet.getLastRowNum;
                
        data_counter=0;
        field_names_counter=0;
        dataMatrix(iSheet).data=zeros(nRows,nCols_req);
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
                        dataMatrix(iSheet).data(data_counter,iCol+1)=cell_content;
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
                                % double check for num
                                str=char(current_cell.getStringCellValue());
                                if ~isnan(str2double(str))
                                    value=str2double(str);
                                else
                                    value=str;
                                end
                            case 3 % empty
                                value=[];
                            otherwise
                                error('Unknown cell type...')
                        end
                        parameter=strrep(parameter,' ','_');
                        parameter=strrep(parameter,'-','_');
                        parameter=strrep(parameter,'<','');
                        parameter=strrep(parameter,'>','');
                        parameter=strrep(parameter,':','');
                        TrackInfo(iSheet).(parameter)=value;
                    end
                case 2 % fieldnames
                    field_names_counter=field_names_counter+1;
                    for iCol=0:nCols_read                        
                        current_cell=current_row.getCell(iCol);                        
                        dataMatrix(iSheet).fieldNames{field_names_counter,iCol+1}=char(current_cell.getStringCellValue());
                    end
                case 3 % empty
            end
        end
        
        %%% prune data matrix
        dataMatrix(iSheet).data(data_counter+1:end,:)=[];
    end
end

