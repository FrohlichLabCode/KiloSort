% This code loops through all recordings and calls the funciton
% 'is_computeWaveforms.m' if spikes have been sorted and manually assigned.
% % I.S. 2017
% % A.H. 2019 added other animals
% % A.H. 2020 shorten file name, add skipRec

animalNames = {'0182'};
skipRec = 1;

% This part adds paths
baseDir = (['Z:/Individual/Angel/KiloSort/']);
%baseDir = (['E:/Dropbox (Frohlich Lab)/Frohlich Lab Team Folder/Codebase/CodeAngel/Ephys/KiloSort/']);
addpath(genpath([baseDir 'KiloSort-master/'])) % path to kilosort folder
addpath(genpath([baseDir 'npy-matlab-master/'])) % path to npy-matlab scripts
pathToYourConfigFile = [baseDir '/KiloSort-master/configFiles']; % Path to my custom configuration files

for ianimal = 1%:numel(animalNames)
    animalCode = animalNames{ianimal};
    switch animalCode
        case {'0139','0151','0153'}
            sortProbes = {'A','B','C'}; % The probes we would like to sort from the INTAN recording system
        case {'0171','0179','0180','0181'}
            sortProbes = {'A','B','C','D'}; % The probes we would like to sort from the INTAN recording system
        case {'0182','0185'}
            sortProbes = {'B'}; % only PPc
    end
    pathDir = ['Z:\Ferret Data\' animalCode '\tmpSpikeSort\'];
    saveDir = ['Z:\Ferret Data\' animalCode '\afterSpikeSort\'];
    files = dir([pathDir animalCode '_arnoldTongue*']); % detect files to sort
    cl    = struct2cell(files);
    nm    = cl(1,:); clear name
    for n = 1:numel(nm); name{n} = nm{n}; end
    recNames = unique(name); % all recording names
    
    for irec = 1%:numel(files)
        recName = files(irec).name(1:end-14);
        recPath = [pathDir files(irec).name '\'];
        display(['Processing rec: ' recName])
        
        if ~exist([saveDir recName],'dir'); mkdir(saveDir,recName); end
        savePath = [saveDir recName  '\'];          
        
        for iprobe = 1:numel(sortProbes)
            % make directories for probes
            if ~exist([savePath sortProbes{iprobe}],'dir')
                mkdir(savePath, sortProbes{iprobe});
            end
            fpath    = [recPath 'spikeSort\' sortProbes{iprobe} '\'];
            if exist([savePath sortProbes{iprobe} '\spikeWaveforms.mat'],'file') && skipRec == 1;
                fprintf(['Already analyzed ' recName ' probe:' num2str(iprobe) '\n']) 
                continue;
            else % not processed
                if exist([fpath 'phy.log'],'file')
                    %if exist([fpath 'cluster_groups.csv'],'file') % Old version
                    if exist([fpath 'cluster_group.tsv'],'file') % new phy
                        is_computeWaveforms(fpath)
                        fprintf('Copying file %s port %s... \n',recName,sortProbes{iprobe})
                        copyfile([fpath 'spikeWaveforms.mat'],[savePath sortProbes{iprobe} '\']); 
                    end
                else
                    fprintf('No file detected %s port %s... \n',recName,sortProbes{iprobe})
                end % Bail
                
            end
            
        end
    end
end