% figure 5 - alpha difference topo plot

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', 'studyname.study', 'filepath', 'studypath');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

% Set ERSP parameters
STUDY = pop_erspparams(STUDY, 'averagemode','ave','topotime',[200 700] ,'topofreq',[8 12] );

% Run statistics
STUDY = pop_statparams(STUDY, 'condstats','on','mode','fieldtrip','fieldtripnaccu',10000,...
    'fieldtripmethod','montecarlo','fieldtripmcorrect','cluster','fieldtripalpha',0.05);

% Compute ERSP for all channels
[STUDY ersp condtimes condfreqs pgroup pcond pinter] = std_erspplot(STUDY,ALLEEG,...
    'channels',{'Fp1','Fz','F3','F7','FT9','FC5','FC1','C3','T7','TP9','CP5','CP1','Pz',...
    'P3','P7','O1','Oz','O2','P4','P8','TP10','CP6','CP2','Cz','C4','T8','FT10','FC6',...
    'FC2','F4','F8','Fp2','AF7','AF3','AFz','F1','F5','FT7','FC3','C1','C5','TP7','CP3',...
    'P1','P5','PO7','PO3','POz','PO4','PO8','P6','P2','CPz','CP4','TP8','C6','C2','FC4',...
    'FT8','F6','AF8','AF4','F2'}, 'design', 1);


% Extract ERSP data for the two conditions
ersp_cond1 = ersp{1}; % Condition 1
ersp_cond2 = ersp{2}; % Condition 2

% Remove singleton dimension
ersp_cond1 = squeeze(ersp_cond1); % Now [63 × 28]
ersp_cond2 = squeeze(ersp_cond2); % Now [63 × 28]

% Average across subjects
ersp_cond1_avg = mean(ersp_cond1, 2); % Now [63 × 1]
ersp_cond2_avg = mean(ersp_cond2, 2); % Now [63 × 1]

% Compute condition difference
ersp_diff = ersp_cond1_avg - ersp_cond2_avg; % [63 × 1]

% Extract EEG channel locations
chanlocs = EEG(1).chanlocs;

% Identify significant electrodes
p_values = pcond{1}; % p-values 
sig_electrodes = find(p_values == 1); % Indices of significant electrodes

% Plot topoplot of Condition 1 - Condition 2
figure;
topoplot(ersp_diff, chanlocs, 'maplimits', [-0.15 0.15], 'electrodes', 'on');
colorbar;
clim([-0.16 0.15]);
title('Condition 1 - Condition 2');

% Overlay significant electrodes with stars
hold on;
for i = 1:length(sig_electrodes)
    idx = sig_electrodes(i);
    loc = chanlocs(idx); 

    % Ensure location exists before plotting
    if ~isempty(loc.X) && ~isempty(loc.Y)
        scatter(loc.X, loc.Y, 150, 'k', '*', 'LineWidth', 2);
    else
        warning(['Missing coordinates for electrode: ', loc.labels]);
    end
end
hold off;