function is_computeWaveforms(fpath)
% This function loads the raw data that was used to sort spikes in
% kilosort, and then computes the mean waveform from each channel for each
% spike cluster. 
% I.S. 2017
% inputs: fpath - the path to the file in which kilosort was run
doPlot = 1;

fileToLoad = [fpath 'rawData.dat'];
d = dir(fileToLoad); % detect raw data file
numBytes = d.bytes; % get the number of bytes in the file
probeID = fpath(end-1); % detect probe ID
% determine number of channels based on probe ID
if strcmp(probeID,'C'); numChans = 16; 
elseif strcmp(probeID,'B'); numChans = 16;
else numChans = 16; end % << be careful to change based on need

szMat = [numChans (numBytes/numChans)/2]; % dimensions of the file
% load raw data matrix
fid = fopen(fileToLoad,'r');
dataMat = fread(fid,szMat,'*int16');
fclose(fid);

spkTimes = readNPY([fpath 'spike_times.npy']); % these are in samples, not seconds
spkClus = readNPY([fpath 'spike_clusters.npy']); % cluster ID's for each spike
mapFile = dir([fpath '*Map.mat']); % map file used for sorting
load([fpath mapFile.name]); % load map file
dataMat = dataMat(chanMap,:); % remap raw data into same format as kilosort

% load in sorting results
%fileID   = fopen([fpath 'cluster_groups.csv']);  % old phy
fileID   = fopen([fpath 'cluster_group.tsv']);  % new phy
formatSpec = '%f %s';
LogFile = textscan(fileID,formatSpec,'HeaderLines',1,'Delimiter', '\t');
fclose(fileID);
% Keep only 'good' clusters
goodIndex = cellfun(@any,regexp(LogFile{2},'good'));
clus = LogFile{1}(goodIndex);

fs    = 30e3; % sample rate
win = round([-0.001 0.002]*fs); % window to extract around spike time: -1 to 2 ms
wfWin = win(1):win(2); % samples around the spike times to load

clusData = struct; % initialize cluster data struct
for iclus = 1:numel(clus)
    fprintf('Computing waveform clus %d/%d \n',iclus,numel(clus))
    curClus = double(spkTimes(spkClus==clus(iclus))); % spike times for cluster 'iclus'
    % remove spikes that may cause errors at the edges
    curClus(curClus<win(2) | curClus>size(dataMat,2)-win(2)) = [];
    theseWF = zeros(numel(curClus), numChans, numel(wfWin),'int16'); % initialize spike matrix
    for ispk = 1:numel(curClus)
        theseWF(ispk,:,:) = dataMat(:,curClus(ispk)+wfWin) - repmat(dataMat(:,curClus(ispk)+wfWin(1)),1,numel(wfWin)); % grad snippets of data and subtract the pre-spike baseline
    end
    spkMean = squeeze(mean(theseWF,1)); % compute STA broadband signal across all channels
    rspk = range(spkMean,2); % compute range of average spikes
    chanID = find(rspk==unique(max(rspk))); % find the channel with the largest range
    realChan = chanMap(chanID); % map back to original channels
    
    % load data into clusData structure
    clusData(iclus).clusID = clus(iclus);
    clusData(iclus).spkMean = spkMean;
    clusData(iclus).chanID = chanID;
    clusData(iclus).realChan = realChan;
    clusData(iclus).spkTimes = curClus/fs;
end
save([fpath 'spikeWaveforms'],'clusData')

%% Plot spike waveforms
if doPlot == 1
    fig = figure();
    for iclus = 1:numel(clus)
        spkwav = clusData(iclus).spkMean(clusData(iclus).chanID,:);        
        plot((1:91)/30,spkwav/abs(min(spkwav))); hold on
    end
    lgd = legend('Location','southeast');
    if numel(clus)>10; lgd.NumColumns = 2; end
    xlim([1,91]/30);
    xlabel('Time [ms]')
    ylabel('Spike amp. normalized to trough')
    title({fpath(1:51) ; [fpath(52:end)];['n=' num2str(numel(clus)) ' SU']})
    saveas(fig,[fpath 'spikeWaveforms.png']);
    savefig(fig,[fpath 'spikeWaveforms.fig'],'compact');
end

