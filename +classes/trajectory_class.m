classdef trajectory_class < handle
    properties
        GUI=struct;
        config
        
        raw_folder='';
        
        root_folder=tools.up1(fileparts(mfilename('fullpath')));
        save_folder='files/datasets'
        extension='.mat';
        
        config_folder_name='files/config';
        
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
        sample_rate=[];
        target_sampling_rate=5;
        add_extra_points=100;
        
        PriorKnowledge;
        
        
        % classification
        SVMmodels
        SVM_matrix
        track_classification_vector
        track_classification_vector_probe
    end
    
    methods
        function self=trajectory_class(varargin)
            % load or init config
            if ~self.load_config()
                self.init_config()
            end
        end
        
        function res=load_config(self,varargin)
            if nargin>=2&&~isempty(varargin{1})
                fname=varargin{1};
            else
                fname='latest.mat';
            end
            load_config_name=fullfile(self.root_folder,self.config_folder_name,fname);
            
            if exist(load_config_name,'file')==2
                S=load(load_config_name,'config');
                self.config=S.config;
                res=1;
            else
                disp('File not found...')
                res=0;
            end
        end
        
        function save_config(self,varargin)
            if nargin>=2&&~isempty(varargin{1})
                fname=varargin{1};
            else
                fname='default.mat';
            end
            save_config_name=fullfile(self.root_folder,self.config_folder_name,fname);
            config=self.config;
            tools.savec(save_config_name)
            save(save_config_name,'config')
            fprintf('Saved current config to %s \n',save_config_name)
        end
        
        function init_config(self,varargin)
            data={'Probe_trial',false ; 'Reversal', false ;...
                'pool_center_x',0 ; 'pool_center_y',0 ; 'pool_radius',0 ; ...
                'platform_center_x',0 ; 'platform_center_y',0 ; 'platform_radius',0 ;...
                'old_platform_center_x',0 ; 'old_platform_center_y',0 ; 'old_platform_radius',0 };
            self.config=self.table2struct(data);
        end
        
        function draw_GUI(self,varargin)
            % draw push button
            uicontrol('Style','PushButton','String','Select folder','Units','Normalized','Position',[.1 .9 .2 .05],'callback',@self.set_folder_cb)
            self.GUI.folder_name_txt=uicontrol('Style','Edit','String',self.raw_folder,'Units','Normalized','Position',[.35 .9 .7 .05],'tag','folder_name_txt');
            
            % draw save/load config buttons
            uicontrol('Style','PushButton','String','Load config','Units','Normalized','Position',[.1 .8 .2 .05],'callback',@self.load_config_cb)
            uicontrol('Style','PushButton','String','Save config','Units','Normalized','Position',[.35 .8 .2 .05],'callback',@self.save_config_cb)
            
            % place data table
            t=uitable('Units','Normalized','Position',[.1 .25 .5 .5],'Data',self.struct2table());
            t.ColumnName={'Property','Value'};
            t.ColumnEditable = [false,true];
            t.ColumnWidth={150,50};
            %t.ColumnFormat={[] 'short'};
            t.CellEditCallback=@self.table_func;
            %self.table_handle=t;
            self.GUI.table_handle=t;
            
            % command buttons
            self.GUI.load_bt=uicontrol('Style','PushButton','String','Load data','Units','Normalized','Position',[.65 .7 .2 .05],'callback',@self.load_data_cb);
            self.GUI.process_bt=uicontrol('Style','PushButton','String','Process data','Units','Normalized','Position',[.65 .60 .2 .05],'callback',@self.process_data_cb);
            
            
            % output window
            
        end
        
        function set_folder(self,varargin)
            if nargin>=2&&~isempty(varargin{1})
                data_folder=varargin{1};
                A=strsplit(filesep,data_folder);
                B=strsplit(data_folder,filesep);
                %%% solve issue where strsplit has changed in which
                %%% argument comes first
                if length(A)>length(B)
                    name=A{end};
                else
                    name=B{end};
                end
                self.raw_folder=data_folder;
                self.database_name=self.check_str(name);
            else % select folder manually
                data_folder=uigetdir()
                if ~data_folder==0
                    self.raw_folder=data_folder;
                    self.database_name=self.check_str(data_folder);
                else
                    return
                end
            end
            
            % print output
            self.GUI.folder_name_txt.String=data_folder;
            
            saveName=fullfile(self.save_folder,[self.database_name self.extension]);
            self.database_path_rel=saveName;
            self.database_path_abs=fullfile(self.root_folder,saveName);
            if exist(saveName,'file')
                %error(['File ' saveName ' exists...'])
                %self.import_data()
            else
                tools.savec(saveName)
            end
        end
        
        function file_scanner(varargin)
            self=varargin{1};
            
            %%% Find all files in data_folder
            tic
            self.all_files=tools.rdir([self.raw_folder filesep '**' filesep '**']);
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
            [mapping,labels]=tools.getMapping(extensions);
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
        
        function set_prior(self,varargin)
            self.PriorKnowledge=varargin{1};
        end
        
        function sample_data(self,varargin)
            
            if nargin>=2&&~isempty(varargin{1})
                iFile=varargin{1};
            else
                iFile=1;
            end
            load_name=fullfile(self.file_names(iFile).name);
            switch self.file_type
                case 1
                    %disp('*.xlsx not fully implemented...')
                    self.set_cols2read(-1);
                    self.read_xlsx_data(load_name)
                case 2
                    disp('*.xls not implemented...')
                case 3
                    disp('*.csv not implemented...')
                case 4
                    self.set_cols2read(-1);
                    self.read_txt_data(load_name);
                    
                    %D=self.file_data;
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
        
        function set_cols2read(self,varargin)
            %self=varargin{1};
            if nargin==2&&~isempty(varargin{1})
                sel=varargin{1};
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
            elseif nargin==3&&~isempty(varargin{2})
                % if 2 inputs, interpret as range, only used if sample
                % exists
                start=varargin{1};
                stop=varargin{2};
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
        
        function read_data(self,varargin)
            %%% check if db_file exists
            if ~self.import_data()
                self.reset_track_data()
                
                %t0=clock;
                tmp=self.GUI.load_bt.String;
                for iFile=1:self.nFiles
                    %load_name=fullfile(self.raw_folder,self.file_names(iFile).name)
                    load_name=fullfile(self.file_names(iFile).name);
                    switch self.file_type
                        case 1
                            %disp('*.xlsx not implemented...')
                            %self.read_xlsx_data(load_name)
                            self.read_xlsx_data_basic(load_name)
                        case 2
                            disp('*.xls not implemented...')
                            self.read_xls_data(load_name)
                        case 3
                            disp('*.csv not implemented...')
                        case 4
                            self.read_txt_data(load_name)
                    end
                    
                    %%% Save to database
                    % check how many tracks were extracted, could be >1 for xls
                    % or xlsx files
                    self.append()
                    
                    self.GUI.load_bt.String=sprintf('Loading %d/%d',[iFile self.nFiles]);
                    drawnow
                    %progress(iFile,self.nFiles,t0)
                end
                self.GUI.load_bt.String=tmp;
            end
        end
        
        function res=import_data(self,varargin)
            self.database_path_abs
            if exist(self.database_path_abs,'file')==2
                S=load(self.database_path_abs);
                self.nTracks=S.dataset.nTracks;
                self.track_data=S.dataset.track_data;
                self.col_names_selection=S.dataset.col_names_selection;
                res=1;
            else
                res=0;
            end
        end
        
        function export_data(self,varargin)
            save(self.database_path_abs,'')
        end
        
        function read_xlsx_data_basic(self,varargin)
            tic
            track_name=varargin{1};
            D=xlsread(track_name,1,'A:D','basic');
            self.file_data.raw_data.Trial_time=D(:,1);
            self.file_data.raw_data.Recording_time=D(:,2);
            self.file_data.raw_data.X_center=D(:,3);
            self.file_data.raw_data.Y_center=D(:,4);
            toc
        end
        
        function read_xlsx_data(self,varargin)
            % install POI_library
            tools.initXLSreader
            
            track_name=varargin{1};
            [dataMatrix_sheets, trackInfo_sheets]=tools.readXLSdata(track_name,self.col_names_selection);
            
            self.file_data.file_name=track_name;
            self.file_data.headers=trackInfo_sheets;
            
            fieldNames=dataMatrix_sheets.fieldNames(1,:);
            nFields=length(fieldNames);
            
            for iField=1:nFields
                field_name=self.clean_var_name(fieldNames{iField});
                raw_data.(field_name)=dataMatrix_sheets.data(:,iField);
            end
            
            self.file_data.raw_data=raw_data;
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
                    try
                        cell_data=txt_data(iRD).parts{iCN};
                        raw_data(iRD).(col_names{iCN})=str2double(cell_data);
                    catch
                        txt_data.line
                        disp('no data')
                    end
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
        
        
        function fill_the_gaps(self,varargin)
            corrected_files=zeros(self.nFiles,1);
            for iFile=1:self.nFiles
                fieldNames=fieldnames(self.track_data(iFile).raw_data);
                for iFN=1:length(fieldNames)
                    A=self.track_data(iFile).raw_data.(fieldNames{iFN});
                    if any(isnan(A))
                        self.track_data(iFile).raw_data.(fieldNames{iFN})=tools.fillTheGaps2(A);
                        corrected_files(iFile)=1;
                    end
                end
            end
            fprintf('Corrected %3.2f%% files \n',mean(corrected_files))
        end
        
        function get_sample_rate(self,varargin)
            self.sample_rate=round(1/mean(diff(self.track_data(1).raw_data.Trial_time)));
        end
        
        function resample_data(self,varargin)
            self.get_sample_rate()
            if self.sample_rate>self.target_sampling_rate
                for iFile=1:self.nFiles
                    data=[self.track_data(iFile).raw_data.Trial_time self.track_data(iFile).raw_data.X_center self.track_data(iFile).raw_data.Y_center];
                    data_exp=cat(1,repmat(data(1,:),self.add_extra_points,1),data,repmat(data(end,:),self.add_extra_points,1));
                    
                    X_resampled=resample(data_exp,self.target_sampling_rate,self.sample_rate);
                    data_cut=X_resampled(self.add_extra_points*self.target_sampling_rate/self.sample_rate:end-self.add_extra_points*self.target_sampling_rate/self.sample_rate,:);
                    new_sample_rate=round(1/mean(diff(data_cut(:,1))));
                    if new_sample_rate==self.target_sampling_rate
                        self.track_data(iFile).resampled_data=data_cut;
                    end
                end
                fprintf('Resampled frame rate from %dHz to %dHz. \n',[self.sample_rate new_sample_rate])
            end
        end
        
        function get_latency_firstCrossing(self,varargin)
            %prior=self.PriorKnowledge;
            for iTrack=1:self.nFiles
                %%% find first platform crossing
                track_temp=self.track_data(iTrack);
                data=[track_temp.raw_data.Trial_time track_temp.raw_data.X_center track_temp.raw_data.Y_center];
                %platFormCoords=prior.Target;
                %platFormCoords.current=platFormCoords.center;
                platFormCoords.current=[self.config.platform_center_x self.config.platform_center_y];
                platFormCoords.radius=self.config.platform_radius;
                Latency=core.getLatencyProbe(data,platFormCoords);
                self.track_data(iTrack).LatencyFirstCrossing=Latency;
            end
        end
        
        function track_selector(self,varargin)
            for iTrack=1:self.nFiles
                %%% find first platform crossing
                track_temp=self.track_data(iTrack);
                T=track_temp.resampled_data(:,1);
                
                sel=T<track_temp.LatencyFirstCrossing;
                self.track_data(iTrack).resampled_data_probe=track_temp.resampled_data(sel,:);
            end
        end
        
        function extract_parameters(self,varargin)
            %Prior=self.PriorKnowledge;
            for iTrack=1:self.nFiles
                if self.config.Probe_trial==0
                    data=self.track_data(iTrack).resampled_data;
                else
                    data=self.track_data(iTrack).resampled_data_probe;
                end
                
                %platFormCoords_thisTrack.current=Prior.Target.center;
                %platFormCoords_thisTrack.targetZoneRadius=Prior.Target.radius*2.5;
                platFormCoords_thisTrack.current=[self.config.platform_center_x self.config.platform_center_y];
                platFormCoords_thisTrack.targetZoneRadius=self.config.platform_radius*2.5;
                
                pool_coords.center=[self.config.pool_center_x self.config.pool_center_y];
                pool_coords.radius=self.config.pool_radius;
                
                [trackProps, vector]=core.getTrackStats_used(data,pool_coords,[],platFormCoords_thisTrack);
                self.track_data(iTrack).trackProps=trackProps;
                self.SVM_matrix(iTrack,:)=vector;
            end
        end
        
        function classify_track(self,varargin)
            tic
            if isempty(self.SVMmodels)
                nIter=200;
                disp('Loading big model file...')
                modelName=['models/SVMclassifierMWMdata_nIter_' num2str(nIter) '_oldModel.mat'];
                %load(modelName,'SVMmodels','perfMatrix','classificationStrings','COMP','nComp','class_vector')
                S=load(modelName,'SVMmodels');
                self.SVMmodels=S.SVMmodels;
                toc
            end
            
            %%% do classification
            track_classification=core.getModelResponse_oldApproach(self.SVMmodels,self.SVM_matrix);
            if self.config.Probe_trial==0
                self.track_classification_vector=track_classification;
            else
                self.track_classification_vector_probe=track_classification;
            end
        end
        
        function save_data(self,varargin)
            dataset=self;
            self.database_path_abs
            save(self.database_path_abs,'dataset')
        end
        
        function create_output(self,varargin)
            if self.config.Probe_trial==0
                save_name=fullfile(self.root_folder,'files','output',sprintf('%s.txt',self.database_name))
            else
                save_name=fullfile(self.root_folder,'files','output',sprintf('%s_probe.txt',self.database_name))
            end
            savec(save_name)
            fid=fopen(save_name,'w');
            for iTrack=1:self.nFiles
                 if self.config.Probe_trial==0
                    data=self.track_data(iTrack).resampled_data;
                    track_classification=self.track_classification_vector;
                else
                    data=self.track_data(iTrack).resampled_data_probe;
                    track_classification=self.track_classification_vector_probe;
                end
                latency=range(data(:,1));
                fprintf(fid,'%s ; %3.2f ;  %d \n',self.file_names(iTrack).name,latency,track_classification(iTrack));
            end
            fclose(fid);
        end
        
        function plot_track(self,varargin)
            if nargin>=2
                track_nr=varargin{1};
            else
                track_nr=1;
            end
            
            if self.config.Probe_trial==0
                %data=cat(1,self.track_data(track_nr).resampled_data,[NaN NaN NaN]);
                track_classification=self.track_classification_vector;
                platform_line_style='-';
            else
                %data=cat(1,self.track_data(track_nr).resampled_data_probe,[NaN NaN NaN]);
                track_classification=self.track_classification_vector_probe;
                platform_line_style='-';
            end
            
            cla
            hold on
            plot(self.config.pool_center_x,self.config.pool_center_y,'ko')
            tools.circle([self.config.pool_center_x self.config.pool_center_y],self.config.pool_radius,100,'k-',3);
            tools.circle([self.config.platform_center_x self.config.platform_center_y],self.config.platform_radius,100,['r' platform_line_style],2);
            
            for iTrack=1:length(track_nr)
                idx=track_nr(iTrack);
                if self.config.Probe_trial==0
                    data=cat(1,self.track_data(idx).resampled_data);
                    plot(data(:,2),data(:,3),'b-')
                else
                    data=cat(1,self.track_data(idx).resampled_data_probe);
                    data_post=cat(1,self.track_data(idx).resampled_data);
                    plot(data_post(:,2),data_post(:,3),'r:')
                    plot(data(:,2),data(:,3),'b-')
                end
            end
            
            
            hold off
            axis equal tight
            
            if length(track_nr)==1
                nIter=200;
                modelName=['models/SVMclassifierMWMdata_nIter_' num2str(nIter) '_oldModel.mat'];
                load(modelName,'classificationStrings')
                if track_nr==1
                    classificationStrings
                end
                title(classificationStrings(track_classification(track_nr)))
                xlabel(sprintf('Latency %.1f sec',range(data(:,1))))
            end
        end
        
        
        function str=check_str(varargin)
            str=varargin{2};
            
            % make names valid
            str=strrep(str,':','-');
            str=strrep(str,filesep,'-');
            str=strrep(str,' ','_');
            str=strrep(str,'(','_');
            str=strrep(str,')','');
            str=strrep(str,'/','');
            str=strrep(str,'-','_');
            
            % clean up
            str=strrep(str,'__','');
        end
        
        function folder_name=clean_var_name(self,folder_name)
            
            folder_name=strrep(folder_name,' ','_');
            folder_name=strrep(folder_name,'(','_');
            folder_name=strrep(folder_name,')','');
            folder_name=strrep(folder_name,'/','');
            folder_name=strrep(folder_name,'-','_');
            folder_name=strrep(folder_name,'²','2');
            
            % clean up
            folder_name=strrep(folder_name,'__','');
            
        end
        
        
        %%% callbacks
        % folder
        function set_folder_cb(self,varargin)
            self.set_folder() % choose folder
        end
        
        % data table
        function table_func(self,varargin)
            if isempty(self.GUI.table_handle)
                self.GUI.table_handle=varargin{1};
            else
                self.config=self.read_table();
            end
        end
        
        function out=read_table(self,varargin)
            if ~isempty(self.GUI.table_handle)
                D=self.GUI.table_handle.Data;
                out=self.table2struct(D);
            end
        end
        
        function write_table(self,varargin)
            if ~isempty(self.GUI.table_handle)
                self.GUI.table_handle.Data=self.struct2table();
            end
        end
        
        function out=struct2table(self,varargin)
            out=[fieldnames(self.config) struct2cell(self.config)];
        end
        
        function out=table2struct(self,varargin)
            D=varargin{1};
            out=cell2struct(D(:,2),D(:,1));
        end
        
        % config
        function load_config_cb(self,varargin)
            load_config_dir=fullfile(self.root_folder,self.config_folder_name);
            fname=uigetfile(load_config_dir);
            if self.load_config(fname)
                self.write_table()
            end
        end
        
        function save_config_cb(self,varargin)
            load_config_dir=fullfile(self.root_folder,self.config_folder_name);
            fname=uiputfile(load_config_dir,'.mat');
            self.save_config(fname)
        end
        
        % commands for data processing
        function load_data_cb(self,varargin)
            self.save_config('latest.mat') % store current config
            self.file_scanner()
            self.file_parser()
            self.sample_data(1)
            self.set_cols2read(1:4)
            self.read_data()
            self.fill_the_gaps()
            self.resample_data()
            self.save_data()
        end
        
        function process_data_cb(self,varargin)
            self.save_config('latest.mat') % store current config
            
            if self.config.Probe_trial==true
                self.get_latency_firstCrossing()
                self.track_selector()
            end
            
            %% extract parameters
            self.extract_parameters()
            
            %% get track classification
            self.classify_track()
            
            %% Save data to file
            self.save_data()
            
            %% save output file
            self.create_output()
        end
        
    end
end