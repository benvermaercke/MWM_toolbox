classdef trajectory_class < handle
    properties
        raw_folder='';
        
        root_folder=up1(fileparts(mfilename('fullpath')));
        save_folder='datasets'
        extension='.mat';
        
        database_name='';
        database_path_rel='';
        database_path_abs='';
        
        % after file scanner/parser
        all_files=struct;
        file_names={};
        nFiles=[];
        file_extension='';
        file_type=[];
        
        % after sample read
        file_data=struct('file_name','','headers',struct,'raw_data',[]); % temp file data
        
        % define filters
        col_names_selection=[];
        nData_cols=[];
        
        % after append
        nTracks=0;
        track_data=struct('file_name','','headers',struct,'raw_data',[]); % actual data struct
    end
    
    methods
        function self=trajectory_class(varargin)
            if nargin>=1&&~isempty(varargin{1})
                data_folder=varargin{1};
                A=strsplit(filesep,data_folder);
                B=strsplit(data_folder,filesep);
                if length(A)>length(B)
                    name=A{end};
                else
                    name=B{end};
                end
                self.raw_folder=data_folder;
                self.database_name=self.check_str(name);
            else % default name
                self.raw_folder='';
                self.database_name='test_dataset';
            end
            
            saveName=fullfile(self.save_folder,[self.database_name self.extension]);
            if exist(saveName,'file')
                error(['File ' saveName ' exists...'])
            else
                savec(saveName)
                self.database_path_rel=saveName;
                self.database_path_abs=fullfile(self.root_folder,saveName);
            end
        end
        
        function file_scanner(varargin)
            self=varargin{1};
            
            %%% Find all files in data_folder
            tic
            self.all_files=rdir([self.raw_folder filesep '**' filesep '**']);
            toc
            self.nFiles=length(self.all_files);
        end
        
        function file_parser(varargin)
            self=varargin{1};
            
            % Extract the extension of each file
            extensions{self.nFiles}='';
            tic
            for iFile=1:self.nFiles
                [~,~,extensions{iFile}]=fileparts(self.all_files(iFile).name);
            end
            toc
            
            % Determine most common file type
            [mapping,labels]=getMapping(extensions);
            type_vector={'.xlsx','.xls','.csv','.txt'};
            if mean(mapping)==1
                [~,self.file_type]=ismember(labels,type_vector);
                self.file_names=self.all_files(mapping==1);
                self.nFiles=sum(mapping);
                self.file_extension=type_vector{self.file_type};
            else % Found various file types...
                %%% Choose the most frequent file type
                sel_type=mode(mapping);
                self.file_type=ismember(labels{sel_type},type_vector);
                self.file_names=self.all_files(mapping==sel_type);
                self.nFiles=sum(mapping==sel_type);
                self.file_extension=type_vector{self.file_type};
                
                %%% and show what we did to solve the problem
                disp(labels)
                tabulate(mapping)
                fprintf('Ignoring %d files... \n',sum(mapping~=sel_type))
            end
        end
        
        function str=check_str(varargin)
            str=varargin{2};
            
            % make names valid
            str=strrep(str,' ','_');
            str=strrep(str,'(','_');
            str=strrep(str,')','');
            str=strrep(str,'/','');
            str=strrep(str,'-','_');
            
            % clean up
            str=strrep(str,'__','');
        end
        
        function sample_data(varargin)
            self=varargin{1};
            if nargin>=2&&~isempty(varargin{2})
                iFile=varargin{2};
            else
                iFile=1;
            end
            load_name=fullfile(self.file_names(iFile).name);
            switch self.file_type
                case 1
                case 2
                case 3
                case 4
                    self.set_cols2read(-1);
                    self.read_txt_data(load_name);
                    
                    D=self.file_data;
                    %D.headers
                    %col_names=fieldnames(D.raw_data)
                    %self.nData_cols=length(col_names)
                    
                    %% optional: user input to select columns to read...
                    % default is first 3 or 4, need time and X-Y
                    %                     self.col_names_selection=ones(self.nData_cols,1);
                    %                     self.col_names_selection(5:end)=0;
                    %                     self.col_names_selection
                    %col_names(selected_cols)
                    
            end
        end
        
        function set_cols2read(varargin)
            self=varargin{1};
            if nargin==2&&~isempty(varargin{2})
                sel=varargin{2};
                if sel==-1 % reset selection
                    sel=[];
                else % could be different then actual number of columns
                    if isempty(self.file_data.raw_data) % if no sample, reset
                        sel=[];
                    else
                        nColNames=length(fieldnames(self.file_data.raw_data));
                        sel_full=zeros(nColNames,1);
                        sel_full(1:length(sel))=sel;
                        sel=sel_full;
                    end
                end
            elseif nargin==3&&~isempty(varargin{3})
                % if 2 inputs, interpret as range, only used if sample
                % exists
                start=varargin{2};
                stop=varargin{3};
                if isempty(self.file_data.raw_data)
                    sel=[];
                else
                    nColNames=length(fieldnames(self.file_data.raw_data));
                    sel=zeros(nColNames,1);
                    sel(start:stop)=1;
                end
            else % no input, reset
                sel=[];
            end
            if isempty(sel)
                disp('Column selection was reset...')
            end
            self.col_names_selection=find(sel);
        end
        
        function read_data(varargin)
            self=varargin{1};
            self.reset_track_data()  
            
            t0=clock;
            for iFile=1:self.nFiles
                %load_name=fullfile(self.raw_folder,self.file_names(iFile).name)
                load_name=fullfile(self.file_names(iFile).name);
                switch self.file_type
                    case 1
                        
                    case 2
                    case 3
                    case 4
                        self.read_txt_data(load_name)
                end
                
                %%% Save to database
                % check how many tracks were extracted, could be >1 for xls
                % or xlsx files
                self.append()
                
                progress(iFile,self.nFiles,t0)
            end
        end
        
        function read_txt_data(varargin)
            self=varargin{1};
            load_name=varargin{2};
            
            % read raw data from file
            txt_data=struct('line','','parts',{},'numeric',[]);
            nLines=0;
            fid=fopen(load_name);
            tline = fgetl(fid);
            while ischar(tline)
                % process line
                line=strrep(tline,'"','');line=strrep(line,':','');
                parts=strsplit(';',line);
                
                nLines=nLines+1;
                txt_data(nLines).line=tline;
                txt_data(nLines).parts=parts;
                txt_data(nLines).numeric=~isnan(str2double(parts{1}));
                tline = fgetl(fid);
            end
            fclose(fid);
            
            %parse data into subtypes
            %% check for n header lines in first line
            if strcmpi(txt_data(1).parts{1},'Header lines')
                nHeaderLines=str2double(txt_data(1).parts{2});
            else
                nHeaderLines=find(cat(1,txt_data.numeric)==1,1,'first')-1;
            end
            if ~between(nHeaderLines,[1 nLines])
                error('invalid number of headerlines')
            end
            
            %% read header lines into struct
            for iHL=1:nHeaderLines
                n_fields=length(txt_data(iHL).parts)-1;
                switch n_fields
                    case 1
                        % empty line, do nothing
                    case 2
                        parameter=txt_data(iHL).parts{1};
                        % parse parameter
                        parameter=strrep(parameter,' ','_');
                        value_raw=txt_data(iHL).parts{2};
                        % parse value
                        if ~isempty(value_raw)
                            if ~isnan(str2double(value_raw))
                                eval(['headers.' parameter '=str2double(value_raw);'])
                                %value=str2double(value_raw);
                            else
                                eval(['headers.' parameter '=value_raw;'])
                                %value=value_raw;
                            end
                        end
                        
                    otherwise
                        col_names=txt_data(iHL).parts(1:end-1);
                        nColNames=length(col_names);
                        for iCN=1:nColNames
                            % make names valid
                            col_names{iCN}=strrep(col_names{iCN},' ','_');
                            col_names{iCN}=strrep(col_names{iCN},'(','_');
                            col_names{iCN}=strrep(col_names{iCN},')','');
                            col_names{iCN}=strrep(col_names{iCN},'/','');
                            col_names{iCN}=strrep(col_names{iCN},'-','_');
                            
                            % clean up
                            col_names{iCN}=strrep(col_names{iCN},'__','');
                        end
                end
            end
            
            % In case we did not run sample_data first, or when we are
            % running sample_data, read all available columns
            if isempty(self.col_names_selection)
                selected_cols=find(ones(nColNames,1));
                self.col_names_selection=selected_cols;
                self.nData_cols=length(self.col_names_selection);
                disp('Autofind number of columns...')
            else
                selected_cols=self.col_names_selection;
            end
            
            
            %% read raw data into matrix
            raw_data=struct;
            for iRD=nHeaderLines+1:nLines
                for iCN=selected_cols(:)'
                    cell_data=txt_data(iRD).parts{iCN};
                    raw_data(iRD).(col_names{iCN})=str2double(cell_data);
                end
            end
            
            if 0
                %% eval
                X=cat(1,raw_data.X_center);
                Y=cat(1,raw_data.Y_center);
                plot(X,Y,'.')
                axis equal
            end
            
            self.file_data.file_name=load_name;
            self.file_data.headers=headers;
            self.file_data.raw_data=raw_data;
        end
        
        function append(varargin)
            self=varargin{1};
            N=length(self.file_data);
            for iTrack=1:N
                self.nTracks=self.nTracks+1;
                self.track_data(self.nTracks).file_name=self.file_data(iTrack).file_name;
                self.track_data(self.nTracks).headers=self.file_data(iTrack).headers;
                self.track_data(self.nTracks).raw_data=self.file_data(iTrack).raw_data;
            end            
        end
        
        function reset_track_data(varargin)
            self=varargin{1};
                        
            self.nTracks=0;
            self.track_data=struct('file_name','','headers',struct,'raw_data',[]);
        end
        
        function save_data(varargin)
            self=varargin{1};
            dataset=self;
            self.database_path_abs
            save(self.database_path_abs,'dataset')
        end
    end
end