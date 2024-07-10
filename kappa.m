%% subject wise self ref cond wise kappa

kappa_withinself = zeros(19,3);

for i = 1:19


%% Load the first .mat file and rename the variable
load(sprintf('sub%d_block1.mat', i)); 
block1 = responseMat;

% Load the second .mat file and rename the variable
load(sprintf('sub%d_block2.mat', i)); 
block2 = responseMat; 

% Load the third .mat file and rename the variable
load(sprintf('sub%d_block3.mat', i)); 
block3 = responseMat; 

% Concatenate the three cell arrays into a single cell array
allblocks = [block1; block2; block3];

angShown = [allblocks{:,3}]';
angReported = [allblocks{:,9}]';

% Perform element-wise subtraction of column 9 from column 3
result = angShown - angReported;

% Adjust results based on conditions
result(result > 180) = result(result > 180) - 360;
result(result < -180) = result(result < -180) + 360;

% Create a new column (column 11) for the adjusted results
allblocks(:, 11) = num2cell(result);

%% filter by self vs vowel
stringsToMatch = {'internal distractor condition', 'internal distractor with thought-probe'};

matchingRows = ismember(allblocks(:, 1), stringsToMatch);

selftrials = allblocks(matchingRows, :);

%% filter by rating
% Define the conditions -- LOW SELF CONDITION

condition1 = [0, 1, 0, 0, 0, 0, 0];
condition2 = [1, 0, 0, 0, 0, 0, 0];

doubleArray = cell2mat(selftrials(:, 5));

isDesiredRowlowself = ismember(doubleArray, [condition1; condition2], 'rows');

lowselfref = selftrials(isDesiredRowlowself, :);

anglelowself = cell2mat(lowselfref(:,11));
radianslowself = circ_ang2rad(anglelowself);
kappalowself = circ_kappa(radianslowself);

kappa_withinself(i,1) = kappalowself;

% Define the conditions -- MID SELF CONDITION

condition3 = [0, 0, 1, 0, 0, 0, 0];
condition4 = [0, 0, 0, 1, 0, 0, 0];
condition5 = [0, 0, 0, 0, 1, 0, 0];

%doubleArray = cell2mat(selftrials(:, 5));

isDesiredRowmidself = ismember(doubleArray, [condition3; condition4; condition5], 'rows');

midselfref = selftrials(isDesiredRowmidself, :);

anglemidself = cell2mat(midselfref(:,11));
radiansmidself = circ_ang2rad(anglemidself);
kappamidself = circ_kappa(radiansmidself);

kappa_withinself(i,2) = kappamidself;

% Define the conditions -- HIGH SELF CONDITION

condition6 = [0, 0, 0, 0, 0, 1, 0];
condition7 = [0, 0, 0, 0, 0, 0, 1];

%doubleArray = cell2mat(selftrials(:, 5));

isDesiredRowhighself = ismember(doubleArray, [condition6; condition7], 'rows');

highselfref = selftrials(isDesiredRowhighself, :);

anglehighself = cell2mat(highselfref(:,11));
radianshighself = circ_ang2rad(anglehighself);
kappahighself = circ_kappa(radianshighself);

kappa_withinself(i,3) = kappahighself;


%% save data
sub_behavior = struct('kappa_lowselfref', kappalowself, 'kappa_midselfref', kappamidself, 'kappa_highselfref', kappahighself);
sub_behavior.alltrials = allblocks;
sub_behavior.low_self_trials = lowselfref;
sub_behavior.mid_self_trials = midselfref;
sub_behavior.high_self_trials = highselfref;

subfilename = sprintf('sub%d_behavior', i );

save(subfilename, 'sub_behavior');

end