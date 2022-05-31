function make_thalamus_2x8_Map(fpath)
% Make a channel map for the Microprobes 2x8 array that we use to record
% activity from LP/Pulvinar. The layout of the electrode can be found in
% the documentation sent from Microprobes. This has to be matched to the
% channel assignment based on connector pin maps from the INTAN 16 channel
% headstage. 
% I.S. 2017

% here I know a priori what order my channels are in.  So I just manually 
% make a list of channel indices (and give
% an index to dead channels too). chanMap(1) is the row in the raw binary
% file for the first channel. chanMap(1:2) = [33 34] in my case, which happen to
% be dead channels. 

chanMap = [11 10 9 8 23 22 21 20 12 13 14 15 16 17 18 19] - 7;

% the first thing Kilosort does is reorder the data with data = data(chanMap, :).
% Now we declare which channels are "connected" in this normal ordering, 
% meaning not dead or used for non-ephys data

connected = true(16, 1); % connected(1:2) = 0;

% now we define the horizontal (x) and vertical (y) coordinates of these
% 34 channels. For dead or nonephys channels the values won't matter. Again
% I will take this information from the specifications of the probe. These
% are in um here, but the absolute scaling doesn't really matter in the
% algorithm. 

xcoords = [0 250 500 750 1000 1250 1500 1750 0 250 500 750 1000 1250 1500 1750 ];
ycoords = [0 0 0 0 0 0 0 0 250 250 250 250 250 250 250 250  ];

% Often, multi-shank probes or tetrodes will be organized into groups of
% channels that cannot possibly share spikes with the rest of the probe. This helps
% the algorithm discard noisy templates shared across groups. In
% this case, we set kcoords to indicate which group the channel belongs to.
% In our case all channels are on the same shank in a single group so we
% assign them all to group 1. 

kcoords = 1:16;

% at this point in Kilosort we do data = data(connected, :), ycoords =
% ycoords(connected), xcoords = xcoords(connected) and kcoords =
% kcoords(connected) and no more channel map information is needed (in particular
% no "adjacency graphs" like in KlustaKwik). 
% Now we can save our channel map for the eMouse. 

% would be good to also save the sampling frequency here
fs = 30e3; 

save(fullfile(fpath, 'thalamusMap.mat'), 'chanMap', 'connected', 'xcoords', 'ycoords', 'kcoords', 'fs')