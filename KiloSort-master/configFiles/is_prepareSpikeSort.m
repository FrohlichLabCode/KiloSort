%% This code will take raw data from Intan recording system (1 file per channel) 
%  and turn into rawData.dat file per region (eg. A,B,C,D).
%  This is the first step for spikesorting
%  With the animals ID specified at the top of the m-file. 
% This code will read the broadband signals saved by the INTAN system 
% and save them as a matrix in a binary file 'rawData.dat'. 
% This is the format that kilosort is expecting. 
% Binary files are generated for each probe, eg: 'A', 'B', 'C', etc. 
% IS created
%  AH 20190711: added useAB flag to account for animals that have 2 regions
%  combined in C and D port, and seprate them out into ABCD again.
% AH 20200823: added doKeepChn to remove noisy channels, otherwise
% clusters are saturated with noise.

%%
clear
clc
skipRec = 1;
doKeepChn = 1; % use doKeepChn to remove noisy channels
if doKeepChn == 1; keepChnSuffix = '_validChn'; else keepChnSuffix = []; end
animalCode = '0181';

switch animalCode
    case {'0171','0173','0179','0180','0181'} % 5CSRTT commutator animals
        useAB = 0; % if has channel AB
        numChns = [0,0,32,32]; % port CD has 16+16 channels each
    case {'0172','0168','0169'}
        useAB = 1; % if 2 headstages share 1 channel
        numChns = [16,16,16,16];
    case {'0184'}
        useAB = 0;
        numChns = [16,16,16];
end

%pathDir = ['G:\' animalCode '\']; rawPath = [pathDir 'rawData\'];
pathDir = ['Z:\Ferret Data\' animalCode '\']; % Z drive doesn't allow writing dataMat
rawPath = [pathDir 'ephys\'];
if ~exist([pathDir 'tmpSpikeSort'],'dir'); mkdir([pathDir,'tmpSpikeSort']); end
tmpPath = [pathDir 'tmpSpikeSort\'];
files = dir([rawPath animalCode '_*']);
cl    = struct2cell(files);
nm    = cl(1,:);
for n = 1:numel(nm); name{n} = nm{n}; end
recNames = unique(name);

for irec = 1:numel(recNames)
    recName = recNames{irec};
    recPath = [rawPath recName '\'];
    newPath = [tmpPath recName '\'];
    
    if ~exist([newPath 'spikeSort' keepChnSuffix],'dir'); mkdir(newPath, ['spikeSort' keepChnSuffix]); end
    sortPath = [newPath  'spikeSort' keepChnSuffix '\'];
    % ,ake directories for all probes
    
    if ~exist([sortPath 'A'],'dir')
        mkdir(sortPath,'A');
        mkdir(sortPath,'B');    
        mkdir(sortPath,'C');
        mkdir(sortPath,'D');
    end  
    
    portAchans = dir([recPath 'amp-A-*']);
    portBchans = dir([recPath 'amp-B-*']);    
    portCchans = dir([recPath 'amp-C-*']);
    portDchans = dir([recPath 'amp-D-*']);
    Fs = 30000;
    
    if useAB == 1
        A = struct2cell(portAchans);
        B = struct2cell(portBchans);
        C = struct2cell(portCchans);
        D = struct2cell(portDchans);    
    elseif useAB == 0
        A = struct2cell(portCchans(1:16,:));
        B = struct2cell(portCchans(17:32,:));
        C = struct2cell(portDchans(1:16,:));
        D = struct2cell(portDchans(17:32,:));
    end
    
    chanNames = horzcat(A(1,:),B(1,:),C(1,:),D(1,:));       
    testPorts = {'A','B','C','D'};
    
    % Load keepChn info
    if ismember(animalCode,{'0171','0179','0180','0181','0168','0173'}) && doKeepChn == 1 % animals have keepChn info in keepChn.m
        [validChns, ~] = keepChn(recName);
    end
    
    % Read data from each channel
    for iport = 1:numel(testPorts)
        eval(['numChans = numel(' testPorts{iport} '(1,:));'])
       
        % skip if raw data is already there
        if exist([sortPath testPorts{iport} '\rawData.dat'],'file') && skipRec == 1
            fprintf('Skipping %s port %s... already computerd \n',recName,testPorts{iport})
        continue; end
        fprintf('Preparing spike sorting %s for port %s \n',recName,testPorts{iport})

        for ichan = 1:numChans
            % If loaded validChn, set noisy channels (not belong to validChn) to 0
            if exist('validChns') && ~ismember(ichan, validChns{iport} - 16*(iport-1))
                if ~exist('v') % load v only to get its length
                    eval(['fileName = ' testPorts{iport} '{1,ichan};']);
                    fileinfo = dir([recPath fileName]);
                    num_samples = fileinfo.bytes/2;
                    fid = fopen([recPath fileName],'r'); 
                    v = fread(fid,num_samples,'int16'); fclose(fid); end % in case 1st channel is noisy, then can't get length of v
                v = zeros(numel(v),1,'int16'); 
            else % normal loading validChn
                eval(['fileName = ' testPorts{iport} '{1,ichan};']);
                fileinfo = dir([recPath fileName]);
                num_samples = fileinfo.bytes/2; % int16 = 2 bytes
                fid = fopen([recPath fileName],'r');
                v = fread(fid,num_samples,'int16');
                fclose(fid);
                v = v*0.195;
                v = int16(v);
            end               
            
            if ichan == 1; dataMat = zeros(numChans,numel(v),'int16'); end
            dataMat(ichan,:) = v;
            clear v
        end
       
        fid = fopen([sortPath testPorts{iport} '\rawData.dat'],'w');
        fwrite(fid,dataMat,'int16');
        fclose(fid);
    end    
end

is_sortAllRecordings



