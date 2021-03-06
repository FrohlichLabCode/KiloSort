function make_cortex_4x8_Map(fpath)
% create a channel Map file for simulated data (eMouse)

% here I know a priori what order my channels are in.  So I just manually 
% make a list of channel indices (and give
% an index to dead channels too). chanMap(1) is the row in the raw binary
% file for the first channel. chanMap(1:2) = [33 34] in my case, which happen to
% be dead channels. 

chanMap = [16 17 18 19 20 21 22 23 8 9 10 11 12 13 14 15 31 30 29 28 27 26 25 24 7 6 5 4 3 2 1 0 ] + 1;

% the first thing Kilosort does is reorder the data with data = data(chanMap, :).
% Now we declare which channels are "connected" in this normal ordering, 
% meaning not dead or used for non-ephys data

connected = true(32, 1); % connected(1:2) = 0;

% now we define the horizontal (x) and vertical (y) coordinates of these
% 34 channels. For dead or nonephys channels the values won't matter. Again
% I will take this information from the specifications of the probe. These
% are in um here, but the absolute scaling doesn't really matter in the
% algorithm. 

xcoords = [0 200 400 600 800 1000 1200 1400 0 200 400 600 800 1000 1200 1400 0 200 400 600 800 1000 1200 1400 0 200 400 600 800 1000 1200 1400 ];
ycoords = [0 0 0 0 0 0 0 0 200 200 200 200 200 200 200 200 400 400 400 400 400 400 400 400 600 600 600 600 600 600 600 600 ];

% Often, multi-shank probes or tetrodes will be organized into groups of
% channels that cannot possibly share spikes with the rest of the probe. This helps
% the algorithm discard noisy templates shared across groups. In
% this case, we set kcoords to indicate which group the channel belongs to.
% In our case all channels are on the same shank in a single group so we
% assign them all to group 1. 

kcoords = 1:32;

% at this point in Kilosort we do data = data(connected, :), ycoords =
% ycoords(connected), xcoords = xcoords(connected) and kcoords =
% kcoords(connected) and no more channel map information is needed (in particular
% no "adjacency graphs" like in KlustaKwik). 
% Now we can save our channel map for the eMouse. 

% would be good to also save the sampling frequency here
fs = 30e3; 

save(fullfile(fpath, 'cortex_4x8_Map.mat'), 'chanMap', 'connected', 'xcoords', 'ycoords', 'kcoords', 'fs')