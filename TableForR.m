%%
% This script concatenate error, reaction times, ERP, and ERSP in table form
% to be used in R for further analysis
% Author - ankit yadav

%%
% Define the base folder path
clearvars;
base_folder = 'folderpath'; % Replace with the actual path

% Loop through each subject (excluding 21 and 27)
excluded_subjects = [21, 27];
final_table = []; % Initialize the final table

for sub = 1:30
    % Skip excluded subjects
    if ismember(sub, excluded_subjects)
        disp(['Skipping subject ', num2str(sub)]);
        continue;
    end

    % Define subject folder
    sub_folder = fullfile(base_folder, ['sub', num2str(sub)]);

    % Define file paths
    combined_abserror_file = fullfile(sub_folder, ['sub', num2str(sub), '_combined_abserror_alltrials.mat']);
    trial_indices_file_EDA = fullfile(sub_folder, ['sub', num2str(sub), '_alltrialindexEDA.mat']);
    trial_indices_file_IDA = fullfile(sub_folder, ['sub', num2str(sub), '_alltrialindexIDA.mat']);
    erp_file = fullfile(sub_folder, sprintf('%d.daterp', sub)); % Dynamic ERP file name
    trial_indices_file = fullfile(sub_folder, ['sub', num2str(sub), '_combined_trial_indices_alltrials.mat']);
    time_frequency_file = fullfile(sub_folder, 'time_frequency_data.mat');
    rt_i_file = fullfile(sub_folder, ['sub' num2str(sub) '_RT_I.mat']); %reaction time in intermediate task
    rt_c_file = fullfile(sub_folder, ['sub' num2str(sub) '_RT_C.mat']); %recation time in color-recall task
    delaytf_file = fullfile(sub_folder, sprintf('%d_delaytf',sub)); %time-frequency in delay epoch

    % Check if all files exist
    if ~exist(combined_abserror_file, 'file') || ~exist(erp_file, 'file') || ...
       ~exist(trial_indices_file, 'file') || ~exist(time_frequency_file, 'file') || ...
       ~exist(trial_indices_file_EDA, 'file') || ~exist(trial_indices_file_IDA, 'file')
        warning(['Files missing for subject ', num2str(sub), '. Skipping.']);
        continue;
    end

    % Load required data
    load(combined_abserror_file, 'combined_abserror_alltrials'); % Absolute error data
    load('-mat', erp_file); % ERP data
    load(trial_indices_file, 'combined_index_alltrials'); % Trial indices to use
    load(trial_indices_file_EDA, 'rownumberEDAalltrials'); % EDA indices
    load(trial_indices_file_IDA, 'rownumberIDAalltrials'); % IDA indices
    load(time_frequency_file, 'tf_data', 'times', 'frequencies'); % Time-frequency data
    load(rt_i_file, 'RT_I');
    load(rt_c_file, 'RT_C');
    load(delaytf_file, 'tf_data_delay', 'times_delay', 'frequencies_delay');


    % Map ConditionID using trial indices
    condition_id_col = zeros(length(combined_index_alltrials), 1); % Initialize
    condition_id_col(ismember(combined_index_alltrials, rownumberIDAalltrials)) = 1; % IDA = 1
    condition_id_col(ismember(combined_index_alltrials, rownumberEDAalltrials)) = 2; % EDA = 2

    num_trials = length(combined_index_alltrials);
    abs_error_col = cell2mat(combined_abserror_alltrials); % Absolute Error (numeric)
    erp_col = NaN(num_trials, 1);

    beta_encoding_col = NaN(num_trials, 1);
    alphaF1_encoding_col = NaN(num_trials, 1);
    alphaPOz_encoding_col = NaN(num_trials, 1);

    subject_id_col = repmat(sub, num_trials, 1); % Subject ID (numeric)

    rt_i_col = cell2mat(RT_I(combined_index_alltrials,:));
    rt_c_col = cell2mat(RT_C(combined_index_alltrials,:));

    theta_delay_col = NaN(num_trials, 1);
    alpha_delay_col = NaN(num_trials, 1);
    beta_delay_col = NaN(num_trials, 1);

     % Process ERP data
    selected_channels =  chan36; %channel to use
    erp_trials_available = combined_index_alltrials(combined_index_alltrials <= size(selected_channels, 2)); % Valid trial indices
    erp_trials = selected_channels( :, erp_trials_available);
    time_indices = 226:425; 
    erp_avg_time = mean(erp_trials(time_indices, :), 1);
    erp_col(ismember(combined_index_alltrials, erp_trials_available)) = erp_avg_time; % ERP Data

    % Process Beta activity during encoding
    chan36_beta = squeeze(tf_data.chan36(:, :, :)); % Extract channel 36 data
    beta_freq_indices = find(frequencies >= 15 & frequencies <= 26);
    beta_time_indices = find(times >= 300 & times <= 800);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(tf_data.chan36, 3) % Check if trial exists
            beta_data = chan36_beta(beta_freq_indices, beta_time_indices, trial_num);
            beta_encoding_col(trial_idx) = mean(beta_data(:)); % Average over freq and time
        end
    end

    % Process Alpha activity during encoding at F1
    alpha_freq_indices = find(frequencies >= 8 & frequencies <= 10);
    alpha_time_indices = find(times >= 600 & times <= 800);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(tf_data.chan36, 3) % Check if trial exists
            alpha_data = chan36_beta(alpha_freq_indices, alpha_time_indices, trial_num);
            alphaF1_encoding_col(trial_idx) = mean(alpha_data(:)); % Average over freq and time
        end
    end

    % alpha at POz
    chan48_alpha = squeeze(tf_data.chan48(:, :, :)); % Extract channel 36 data
    alpha_freq_indices = find(frequencies >= 8 & frequencies <= 12);
    alpha_time_indices = find(times >= 252 & times <= 800);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(tf_data.chan48, 3) % Check if trial exists
            alpha_data = chan48_alpha(alpha_freq_indices, alpha_time_indices, trial_num);
            alphaPOz_encoding_col(trial_idx) = mean(alpha_data(:)); % Average over freq and time
        end
    end

    % process theta in delay
    chan36_theta_delay = squeeze(tf_data_delay.chan36(:, :, :));
    thetadelay_freq_indices = find(frequencies_delay >= 4 & frequencies_delay <= 7);
    thetadelay_time_indices = find(times_delay >= 50 & times_delay <= 200);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(tf_data_delay.chan36, 3) % Check if trial exists
            theta_delay_data = chan36_theta_delay(thetadelay_freq_indices, thetadelay_time_indices, trial_num);
            theta_delay_col(trial_idx) = mean(theta_delay_data(:)); % Average over freq and time
        end
    end
    
    % process beta in delay
    chan36_beta_delay = squeeze(tf_data_delay.chan36(:, :, :));
    betadelay_freq_indices = find(frequencies_delay >= 21 & frequencies_delay <= 35);
    betadelay_time_indices = find(times_delay >= 100 & times_delay <= 200);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(tf_data_delay.chan36, 3) % Check if trial exists
            beta_delay_data = chan36_beta_delay(betadelay_freq_indices, betadelay_time_indices, trial_num);
            beta_delay_col(trial_idx) = mean(beta_delay_data(:)); % Average over freq and time
        end
    end
    
    % process alpha in delay
    chan45_alpha_delay = squeeze(tf_data_delay.chan45(:, :, :));
    chan46_alpha_delay = squeeze(tf_data_delay.chan46(:, :, :));
    chan47_alpha_delay = squeeze(tf_data_delay.chan47(:, :, :));
    chan16_alpha_delay = squeeze(tf_data_delay.chan16(:, :, :));
    chan17_alpha_delay = squeeze(tf_data_delay.chan17(:, :, :));
    
    % Combine all the channels into a 4D array (38 x 300 x 120 x 5)
    alpha_delay_channels = cat(4, chan45_alpha_delay, chan46_alpha_delay, chan47_alpha_delay, chan16_alpha_delay, chan17_alpha_delay);

    chanPO_alpha_delay = mean(alpha_delay_channels, 4);

    alphadelay_freq_indices = find(frequencies_delay >= 8 & frequencies_delay <= 12);
    alphadelay_time_indices = find(times_delay >= 300 & times_delay <= 400);
    for trial_idx = 1:num_trials
        trial_num = combined_index_alltrials(trial_idx);
        if trial_num <= size(chanPO_alpha_delay, 3) % Check if trial exists
            alpha_delay_data = chanPO_alpha_delay(alphadelay_freq_indices, alphadelay_time_indices, trial_num);
            alpha_delay_col(trial_idx) = mean(alpha_delay_data(:)); % Average over freq and time
        end
    end


    % Combine columns for this subject
    subject_table = [abs_error_col, erp_col, beta_encoding_col, alphaF1_encoding_col, alphaPOz_encoding_col, rt_i_col, rt_c_col, theta_delay_col, beta_delay_col, ...
        alpha_delay_col, condition_id_col, subject_id_col];

    % Append to the final table
    final_table = [final_table; subject_table];

    disp(['Processed subject ', num2str(sub), '.']);
end

% Remove rows containing NaN values
final_table = final_table(~any(isnan(final_table), 2), :);

% Convert the final table to a MATLAB table for easy saving and export
R_table_percue = array2table(final_table, 'VariableNames', ...
    {'AbsoluteError', 'ERP', 'Beta_encoding', 'AlphaF1_encoding', 'AlphaPOz_encoding', 'RT_I', 'RT_C','Theta_delay', 'Beta_delay', 'Alpha_delay',...
    'ConditionID', 'SubjectID'});

% Save the table to a .csv file for R
writetable(R_table_percue, 'data_table_alphaF1POz.csv');


