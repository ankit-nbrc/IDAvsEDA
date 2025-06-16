%this scripts computes angular error, sort trial types, computes outliers
%using interquartile method if desires, and sort the thought probe response

% author - ankit yadav


numsub = ;
for i = 1:numsub
    %% load behavioral file
    subjectfolder = sprintf('sub%d',i);
    folderpath = fullfile('folderpath', subjectfolder);
    cd(folderpath);


    % Load the first .mat file and rename the variable
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

    %% absolute angular error
    error =  cell2mat(allblocks(:,3)) - cell2mat(allblocks(:,9));

    error(error > 180) = error(error > 180) - 360;
    error(error < -180) = error(error < -180) + 360;
    error = abs(error);
    %create new column for error in allblocks
    allblocks(:, 11) = num2cell(error);
   
    %% sort the trials between conditions 
    
    %IDA
    stringsToMatchIDA = {'internal distractor condition', 'internal distractor with thought-probe'};
    matchingRowsIDA = ismember(allblocks(:, 1), stringsToMatchIDA);
    rownumberIDA = find(matchingRowsIDA ==1);
    IDA = allblocks(matchingRowsIDA, :); 

    %EDA
    stringsToMatchEDA = {'external distractor condition', 'external distractor with thought-probe'};
    matchingRowsEDA = ismember(allblocks(:, 1), stringsToMatchEDA);
    rownumberEDA = find(matchingRowsEDA == 1);
    EDA = allblocks(matchingRowsEDA, :);

    %% remove outliers -- interquartile method -- for group level circular stats; not used in current manuscript
    % Q13_IDA = quantile(cell2mat(IDA(:,11)),[.25 0.75]); iqr_IDA = 1.5*(Q13_IDA(:,2) - Q13_IDA(:,1));
    % Q13_EDA = quantile(cell2mat(EDA(:,11)),[.25 0.75]); iqr_EDA = 1.5*(Q13_EDA(:,2) - Q13_EDA(:,1));
    % 
    % %outlier limits 
    % lowerlimitIDA = Q13_IDA(:,1) - iqr_IDA;
    % upperlimitIDA = Q13_IDA(:,2) + iqr_IDA;
    % 
    % lowerlimitEDA = Q13_EDA(:,1) - iqr_EDA;
    % upperlimitEDA = Q13_EDA(:,2) + iqr_EDA;    
    % 
    % % Filter based on outliers
    % IDAerror = cell2mat(IDA(:,11));
    % EDAerror = cell2mat(EDA(:,11));
    % 
    % % Filter based on outliers
    % IDA_WO = IDAerror(IDAerror >= lowerlimitIDA & IDAerror <= upperlimitIDA);
    % EDA_WO = EDAerror(EDAerror >= lowerlimitEDA & EDAerror <= upperlimitEDA);
    % 
    % % Find the indices of values outside the limits
    % trialsremovedIDA = find(IDAerror < lowerlimitIDA | IDAerror > upperlimitIDA);
    % trialsremovedEDA = find(EDAerror < lowerlimitEDA | EDAerror > upperlimitEDA);
    % 
    % %save error without outlier file and trial removed index
    % Accuracy = struct('IDA_WO', IDA_WO, 'EDA_WO', EDA_WO, 'trialsremovedIDA', trialsremovedIDA, 'trialsremovedEDA', trialsremovedEDA);
    % 
    % accuracyfile = ['sub', num2str(i), 'accuracy'];
    % 
    % save(accuracyfile,"Accuracy");

   

    %% extract the thought probe responses trialwise

    keepRowsIDA = true(size(IDA, 1), 1); keepRowsEDA = true(size(EDA, 1), 1);
    keepRowsIDA(trialsremovedIDA) = false; keepRowsEDA(trialsremovedEDA) = false;

    IDAallwo =  IDA(keepRowsIDA,:); EDAallwo =  EDA(keepRowsEDA,:);

    % Target string and array
    targetStringIDA =  'internal distractor with thought-probe';
    % Find the rows where the first column matches the target string
    rowwithtpIDA = strcmp(IDAallwo(:, 1), targetStringIDA);
    IDAtptrials = IDAallwo(rowwithtpIDA, :);

    targetStringEDA =  'external distractor with thought-probe';
    rowwithtpEDA = strcmp(EDAallwo(:, 1), targetStringEDA);
    EDAtptrials = EDAallwo(rowwithtpEDA, :);

    IDAthoughtprobeRAW = IDAtptrials(:,10); EDAthoughtprobeRAW = EDAtptrials(:,10);
    

    IDAthoughtprobe = NaN(size(IDAthoughtprobeRAW));

    for t = 1:size(IDAthoughtprobeRAW)
        tptrialIDA = IDAthoughtprobeRAW{t};
        if isequal(tptrialIDA, [1, 0, 0, 0, 0, 0])
        IDAthoughtprobe(t) = 1;
        elseif isequal(tptrialIDA, [0, 1, 0, 0, 0, 0])
        IDAthoughtprobe(t) = 2;
        elseif isequal(tptrialIDA, [0, 0, 1, 0, 0, 0])
        IDAthoughtprobe(t) = 3;
        elseif isequal(tptrialIDA, [0, 0, 0, 1, 0, 0])
        IDAthoughtprobe(t) = 4;
        elseif isequal(tptrialIDA, [0, 0, 0, 0, 1, 0])
        IDAthoughtprobe(t) = 5;
        elseif isequal(tptrialIDA, [0, 0, 0, 0, 0, 1])
        IDAthoughtprobe(t) = 6;
       else
        IDAthoughtprobe(t) = NaN; % Assign NaN if the vector doesn't match any pattern
        end
    end
    

    EDAthoughtprobe = NaN(size(EDAthoughtprobeRAW));
    for v = 1:size(EDAthoughtprobeRAW)
        tptrialEDA = EDAthoughtprobeRAW{v};
        if isequal(tptrialEDA, [1, 0, 0, 0, 0, 0])
        EDAthoughtprobe(v) = 1;
        elseif isequal(tptrialEDA, [0, 1, 0, 0, 0, 0])
        EDAthoughtprobe(v) = 2;
        elseif isequal(tptrialEDA, [0, 0, 1, 0, 0, 0])
        EDAthoughtprobe(v) = 3;
        elseif isequal(tptrialEDA, [0, 0, 0, 1, 0, 0])
        EDAthoughtprobe(v) = 4;
        elseif isequal(tptrialEDA, [0, 0, 0, 0, 1, 0])
        EDAthoughtprobe(v) = 5;
        elseif isequal(tptrialEDA, [0, 0, 0, 0, 0, 1])
        EDAthoughtprobe(v) = 6;
       else
        EDAthoughtprobe(v) = NaN; % Assign NaN if the vector doesn't match any pattern
        end
    end

    %save TP files
    tpfile = ['sub' , num2str(i), 'tpresponse'];

    tpresponse = struct('IDAthoughtprobe', IDAthoughtprobe, 'EDAthoughtprobe', EDAthoughtprobe);

    save(tpfile, "tpresponse");
    
end

%% extract RTs -sorted for trial types and non-sorted for trial types

%RTs sorted for trial types
sub = [];
for i = sub
    %load behavioral file
    subjectfolder = sprintf('sub%d',i);
    folderpath = fullfile('folderpath', subjectfolder);
    cd(folderpath);

    % Load the first .mat file and rename the variable
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

    %RTs 
    RT_I = allblocks(:,6);
    RT_C = allblocks(:,8);

    %%sort the trials between conditions 
    %IDA_RTI
    stringsToMatchIDA = {'internal distractor condition', 'internal distractor with thought-probe'};
    matchingRowsIDA = ismember(allblocks(:, 1), stringsToMatchIDA);
    rownumberIDAalltrials = find(matchingRowsIDA ==1);
    RT_I_IDA = RT_I(matchingRowsIDA, :);
    RT_C_IDA = RT_C(matchingRowsIDA, :);

    %EDA_RTI
    stringsToMatchEDA = {'external distractor condition', 'external distractor with thought-probe'};
    matchingRowsEDA = ismember(allblocks(:, 1), stringsToMatchEDA);
    rownumberEDAalltrials = find(matchingRowsEDA == 1);
    RT_I_EDA = RT_I(matchingRowsEDA, :);
    RT_C_EDA = RT_C(matchingRowsEDA, :);

    RT_I_IDAfilename = sprintf('sub%d_RT_I_IDA',i);
    RT_I_EDAfilename = sprintf('sub%d_RT_I_EDA',i);
    RT_C_IDAfilename = sprintf('sub%d_RT_C_IDA',i);
    RT_C_EDAfilename = sprintf('sub%d_RT_C_EDA',i);

    save (RT_I_IDAfilename, "RT_I_IDA");
    save (RT_I_EDAfilename, "RT_I_EDA");
    save (RT_C_IDAfilename, "RT_C_IDA");
    save (RT_C_EDAfilename, "RT_C_EDA");

end

%RTs not sorted for trial types
sub = [];
for i = sub
    %load behavioral file
    subjectfolder = sprintf('sub%d',i);
    folderpath = fullfile('folderpath', subjectfolder);
    cd(folderpath);

    %load behavioral file
    subjectfolder = sprintf('sub%d',i);
    folderpath = fullfile('folderpath', subjectfolder);
    cd(folderpath);

    % Load the first .mat file and rename the variable
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

    %RTs 
    RT_I = allblocks(:,6);
    RT_C = allblocks(:,8);
    
    RT_I_filename = sprintf('sub%d_RT_I',i);
    RT_C_filename = sprintf('sub%d_RT_C',i);
    save (RT_I_filename, "RT_I");
    save (RT_C_filename, "RT_C");
end
