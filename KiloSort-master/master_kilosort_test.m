useGPU = 1; % do you have a GPU? Kilosorting 1000sec of 32chan simulated data takes 55 seconds on gtx 1080 + M2 SSD.

fpath    = 'J:\0147\0147_arnoldTongue_14_170427_151002\spikeSort\A\'; % where on disk do you want the simulation? ideally and SSD...
if ~exist(fpath, 'dir'); mkdir(fpath); end

% This part adds paths
addpath(genpath('C:\Users\FrohlichLab\Documents\KiloSort-master')) % path to kilosort folder
addpath(genpath('C:\Users\FrohlichLab\Documents\npy-matlab-master')) % path to npy-matlab scripts
pathToYourConfigFile = 'C:\Users\FrohlichLab\Dropbox (Frohlich Lab)\Codebase\CodeIain\KiloSort-master\iainCode'; % for this example it's ok to leave this path inside the repo, but for your own config file you *must* put it somewhere else!  

% Run the configuration file, it builds the structure of options (ops)
run(fullfile(pathToYourConfigFile, 'config_cortex_32.m'))

% This part makes the channel map for this simulation
make_cortexChannelMap(fpath); 

% This part runs the normal Kilosort processing on the simulated data
[rez, DATA, uproj] = is_preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% save python results file for Phy
rezToPhy(rez, fpath);
