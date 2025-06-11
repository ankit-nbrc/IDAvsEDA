% figure 4 --time-frequency plots computed and plotted using EEGLAB

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', 'studyname.study', 'filepath', 'studypath');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

% Set stat parameters
STUDY = pop_statparams(STUDY, 'condstats','on','mode','fieldtrip','fieldtripmethod',...
    'montecarlo','fieldtripmcorrect','cluster','fieldtripalpha',0.05);

STUDY = pop_erspparams(STUDY, 'subbaseline','off');
[STUDY erspdata ersptimes erspfreqs pgroup pcond pinter] = std_erspplot(STUDY, ALLEEG,'channels', {'POz'}, 'design', 1); %channel to plot

%difference map for condition differences
erspdiff = squeeze(erspdata{1,1} - erspdata{2,1});
erspdiff = mean(erspdiff,3);

% Plot results
figure;
contourf(ersptimes, erspfreqs, erspdiff, 40, 'linecolor', 'none'); % Time-freq diff map
hold on;
[c,h] = contour(ersptimes, erspfreqs, pcond{1,1}, 1, 'k', 'LineWidth', 3); % Mark clusters
hold off;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title(sprintf('IDA-EDA'));
colorbar;
% clim([-max(abs(erspdiff(:))) max(abs(erspdiff(:)))]);
clim([-1 1]);
colormap jet;