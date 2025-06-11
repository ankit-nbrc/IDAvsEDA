%% Script for preprocessing the raw data and analysis of ERP; uses EEGLAB and ERPLAB functions
% Author - ankit yadav
%
% Script and pipeline adapted from The ERP CORE (https://doi.org/10.18115/D5JW4R) 
% Reference - Kappenman, E. S., Farrens, J. L., Zhang, W., Stewart, A. X., & Luck, S. J. (2020). ...
% ERP CORE: An open resource for human event-related potential research. NeuroImage. https://doi.org/10.1016/j.neuroimage.2020.117465

%% Step - 1. load the raw data, remove DC offset, and high-pass filter
close all; clearvars;
DIR = 'dirpath'; %path to dir
%List of subjects to process
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

%Loop through each subject listed in SUB
for i = 1:length(SUB)

    %Open EEGLAB
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

    %Define subject path
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load the raw data
    EEG = pop_loadset( 'filename', [SUB{i} '_raw.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_raw'], 'gui', 'off'); 
     
    %Remove DC offsets and apply a high-pass filter
    EEG  = pop_basicfilter( EEG,  1:63 , 'Boundary', 'boundary', 'Cutoff',  0.1, 'Design', 'butter', 'Filter', 'highpass', 'Order',  2, 'RemoveDC', 'on' );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5, 'setname', [SUB{i} '_hpfilt'], 'savenew', [Subject_Path SUB{i} '_hpfilt.set'], 'gui', 'off');

end

%% Step - 2. load the output from step 1, remove segments from break period,
%interpolate channels, remove data exceeding voltage threshold
close all; clearvars;
DIR = 'dirpath';
Current_File_Path = 'filepath';

%Load the Excel file with the list of channels to interpolate for each subject 
[ndata1, text1, alldata1] = xlsread([Current_File_Path filesep 'interpolate elec']);

SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

%Loop through each subject listed in SUB
for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load data output form step 1
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt'], 'gui', 'off'); 

    %Remove segments of EEG during the break periods in between trial blocks
    % set threshold after visual inspection
    EEG  = pop_erplabDeleteTimeSegments( EEG , 'displayEEG', true, 'timeThresholdMS',  5000 );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_ica_prep1'], 'savenew', [Subject_Path SUB{i} '_hpfilt_ica_prep1.set'], 'gui', 'off'); 

    %Interpolate channel(s) specified in Excel file 
    DimensionsOfFile1 = size(alldata1);
    for j = 1:DimensionsOfFile1(1);
        if isequal(SUB{i},num2str(alldata1{j,1}));
           badchans = (alldata1{j,2});
           if ~isequal(badchans,'none') | ~isempty(badchans)
           	  if ~isnumeric(badchans)
                 badchans = str2num(badchans);
              end
              EEG = eeg_interp(EEG, badchans,'spherical');
           end
           [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_ica_prep2'], 'savenew', [Subject_Path SUB{i} '__hpfilt_ica_prep2.set'], 'gui', 'off'); 
        end
    end

    %Delete segments of the EEG exceeding the thresholds defined above
    EEG = pop_continuousartdet( EEG, 'ampth', 500, 'winms', 250, 'stepms', 50, 'chanArray', 1:63, 'review', 'on');        
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', [SUB{i} '_hpfilt_ica_prep3'], 'savenew', [Subject_Path SUB{i} '_hpfilt_ica_prep3.set'], 'gui', 'off'); 
end


%% Step - 3, low- pass filter
close all; clearvars;
DIR = 'dirpath';

SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

%Loop through each subject listed in SUB
for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;   
    Subject_Path = [DIR filesep SUB{i} filesep];
    %load data output from step 2
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_ica_prep3.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt_ica_prep3'], 'gui', 'off');   

    % Perform low-pass filtering
    EEG = pop_eegfiltnew(EEG, [], 45, [], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_lpfilt_ica_prep4'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ica_prep4.set'], 'gui', 'off');
end

%% Step- 4, Downsample 
close all; clearvars;
DIR = 'dirpath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];
    %Load data output form step 3
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_lpfilt_ica_prep4.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt_lpfilt_ica_prep4'], 'gui', 'off');   

    %Downsample to 250hz
    EEG = pop_resample( EEG, 250);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[SUB{i} '_hpfilt_lpfilt_ds_ica_prep4'],'savenew',[Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_prep4.set'] ,'gui','off');
 end

%% Step - 5, compute ICA
close all; clearvars;
DIR = 'dirpath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load output form step 4
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_lpfilt_ds_ica_prep4.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_prep4'], 'gui', 'off');   

    %Compute ICA
    EEG = pop_runica(EEG,'extended',1,'chanind', 1:63);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_prep4_weighted'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_prep4_weighted.set'], 'gui', 'off');

end


%% Step 6 - remove ocular and muscular artifacts after visual inspection of components
close all; clearvars;
DIR = 'dirpath';
Current_File_Path = 'filepath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load output of step 5
    EEG = pop_loadset('filename',[SUB{i} '_hpfilt_lpfilt_ds_ica_prep4_weighted.set'],'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[SUB{i} '_hpfilt_lpfilt_ds_ica_prep4_weighted'], 'gui','off'); 

    %Load list of ICA components corresponding to ocular and muscle artifacts 
    [ndata, text, alldata] = xlsread([Current_File_Path filesep 'ICA conponents removed']); 
    MaxNumComponents = size(alldata, 2);
        for j = 1:length(alldata)
            if isequal(SUB{i}, num2str(alldata{j,1}));
                NumComponents = 0;
                for k = 2:MaxNumComponents
                    if ~isnan(alldata{j,k});
                        NumComponents = NumComponents+1;
                    end
                    Components = [alldata{j,(2:(NumComponents+1))}];
                end
            end
        end

    %Remove ICA components
    EEG = pop_subcomp( EEG, [Components], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[SUB{i} '_hpfilt_lpfilt_ds_ica_corr'],'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corrr.set'],'gui','off');
end
 
%% Step - 7, perfrom average rereferencing
close all; clearvars;
DIR = 'dirpath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load data from step 6
    EEG = pop_loadset('filename',[SUB{i} '_hpfilt_lpfilt_ds_ica_corrr.set'],'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[SUB{i} '_hpfilt_lpfilt_ds_ica_corr'], 'gui','off'); 

    % avergae rereference
    EEG = pop_reref(EEG, []);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref'],'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corrr_avgreref.set'],'gui','off'); 

end

%% Step - 8, Epoching and baseline correction
close all; clearvars;
DIR = 'dirpath';
Current_File_Path = 'filepath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

for i = 1:length(SUB)  
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load output from step 7
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_lpfilt_ds_ica_corrr_avgreref.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corrr_avgreref'], 'gui', 'off'); 

    %Create EEG Event List containing a record of all event codes and their timing
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' });
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist.set'], 'gui', 'off');

    %Assign events to bins with Binlister
    EEG  = pop_binlister( EEG , 'BDF', [Current_File_Path filesep 'bins.txt']); %use text file that contains bin information 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins.set'], 'gui', 'off'); 

    %Epoch the EEG into 1.7-second segments time-locked to the response (from -500 ms to 1200 ms) and perform baseline correction using the average activity from -500 ms to 0 ms 
    EEG = pop_epochbin( EEG , [-500.0  1200.0],  [-500.0  0.0]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56.set'], 'gui', 'off'); 
    close all;

end

%% Step - 9, remove commonly recorded artifactual potentials with simple voltage threshold  and moving window peak-to-peak
close all; clearvars;
DIR = 'dirpath';
Current_File_Path = 'filepath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

%Excel file with thresholds and parameters for identifying C.R.A.P. with the SVT 
[ndata2, text2, alldata2] = xlsread([Current_File_Path filesep 'AR_Parameters_for_SVT_CRAP']);

%Excel file with thresholds and parameters for identifying C.R.A.P. with moving window peak-to-peak
[ndata3, text3, alldata3] = xlsread([Current_File_Path filesep 'AR_Parameters_for_MW_CRAP']);

for i = 1:length(SUB)
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    Subject_Path = [DIR filesep SUB{i} filesep];

    %Load output from step 8
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56.set'], 'filepath', Subject_Path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56'], 'gui', 'off'); 

    %Identify segments with C.R.A.P. artifacts using the SVT algorithm with the parameters in the Excel file
    DimensionsOfFile2 = size(alldata2);
    for j = 1:DimensionsOfFile2(1)
        if isequal(SUB{i},num2str(alldata2{j,1}));
            if isequal(alldata2{j,2}, 'default')
                Channels = 1:63;
            else
                Channels = str2num(alldata2{j,2});
            end
            ThresholdMinimum = alldata2{j,3};
            ThresholdMaximum = alldata2{j,4};
            TimeWindowMinimum = alldata2{j,5};
            TimeWindowMaximum = alldata2{j,6};
        end
    end

    EEG  = pop_artextval( EEG , 'Channel',  Channels, 'Flag', [1 2], 'Threshold', [ThresholdMinimum ThresholdMaximum], 'Twindow', [TimeWindowMinimum  TimeWindowMaximum] ); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_binds_epoch56_SVT'], 'gui', 'off'); 

    %Identify segments with C.R.A.P. artifacts using the MW peak-to-peak algorithm with the parameters in the Excel file
    DimensionsOfFile3 = size(alldata3);
    for j = 1:DimensionsOfFile3(1)
        if isequal(SUB{i},num2str(alldata3{j,1}));
            if isequal(alldata3{j,2}, 'default')
                Channels = 1:63;
            else
                Channels = str2num(alldata3{j,2});
            end
            Threshold = alldata3{j,3};
            TimeWindowMinimum = alldata3{j,4};
            TimeWindowMaximum = alldata3{j,5};
            WindowSize = alldata3{j,6};
            WindowStep = alldata3{j,7};
        end
    end

    EEG  = pop_artmwppth( EEG , 'Channel',  Channels, 'Flag', [1 3], 'Threshold', Threshold, 'Twindow', [TimeWindowMinimum  TimeWindowMaximum], 'Windowsize', WindowSize, 'Windowstep', WindowStep ); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56_SVT_MW'], 'savenew', [Subject_Path SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56_SVT_MW.set'], 'gui', 'off');

   
end

%% Step - 10, create averaged waveform and calculate the percentage of trials rejected
close all; clearvars;
DIR = 'dirpath';
Current_File_Path = 'filepath';
SUB = {'sub1', 'sub2', 'sub3', 'sub4', 'sub5', 'sub6', 'sub7', 'sub8', 'sub9',...
    'sub10', 'sub11', 'sub12', 'sub13', 'sub14', 'sub15', 'sub16', 'sub17',...
    'sub18', 'sub19', 'sub20', 'sub22', 'sub23', 'sub24', 'sub25', 'sub26',...
    'sub28', 'sub29', 'sub30'};

%Create averaged ERP waveforms
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

for i = 1:length(SUB)

    Subject_Path = [DIR filesep SUB{i} filesep];
    EEG = pop_loadset( 'filename', [SUB{i} '_hpfilt_lpfilt_ds_ica_corr_avgreref_elist_bins_epoch56_SVT_MW.set'], 'filepath', Subject_Path);

    %Create an averaged ERP waveform
    ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on');
    ERP = pop_savemyerp( ERP, 'erpname', [SUB{i} 'S56_erp'], 'filename', [Subject_Path SUB{i} 'S56erp.erp']);

    %Apply a low-pass filter (non-causal Butterworth impulse response function, 20 Hz half-amplitude cut-off, 48 dB/oct roll-off) to the ERP waveforms
    ERP = pop_filterp( ERP,  1:63 , 'Cutoff',  20, 'Design', 'butter', 'Filter', 'lowpass', 'Order',  8 );
    ERP = pop_savemyerp( ERP, 'erpname', [SUB{i} 'S56_erp_lpfilt'], 'filename', [Subject_Path SUB{i} 'S56_erp_lpfilt.erp']);

    %Calculate the percentage of trials that were rejected in each bin 
    accepted = ERP.ntrials.accepted;
    rejected= ERP.ntrials.rejected;
    percent_rejected= rejected./(accepted + rejected)*100;

    %Calculate the total percentage of trials rejected across all trial types 
    total_accepted = accepted(1) + accepted(2) ;
    total_rejected= rejected(1)+ rejected(2) ;
    total_percent_rejected= total_rejected./(total_accepted + total_rejected)*100; 

    %Save the percentage of trials rejected (in total and per bin) to a .csv file 
    fid = fopen([DIR filesep SUB{i} filesep SUB{i} '_AR_Percentages_56.csv'], 'w');
    fprintf(fid, 'SubID,Bin,Accepted,Rejected,Total Percent Rejected\n');
    fprintf(fid, '%s,%s,%d,%d,%.2f\n', SUB{i}, 'Total', total_accepted, total_rejected, total_percent_rejected);
    bins = strrep(ERP.bindescr,', ',' - ');
    for b = 1:length(bins)
        fprintf(fid, ',%s,%d,%d,%.2f\n', bins{b}, accepted(b), rejected(b), percent_rejected(b));
    end
    fclose(fid);
end