%experiment script - dual task IDAvsEDA
%author -- ankit yadav

clearvars;

SubjectID = input('Subject ID:','s');

% set up screen
Screen('Preference', 'SkipSyncTests', 1);
display.screens = Screen('Screens');
display.screenNumber = max(display.screens);
display.gammaVals=[2 2 2];
PsychImaging('PrepareConfiguration');   %set up imaging pipeline
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma'); %gamma correction
[mywin, rect] = PsychImaging('OpenWindow', display.screenNumber, [128 128 128]);   % open experimental window with required parameters
PsychColorCorrection('SetEncodingGamma', mywin, 1./display.gammaVals); % implement gamma correction
Screen('BlendFunction', mywin, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
display.frameRate=Screen('FrameRate', mywin);   % screen timing parameters
if display.frameRate == 0
    display.frameRate = 60;
end

[display.screenXpixels, display.screenYpixels] = Screen('WindowSize', mywin);
[display.xCenter, display.yCenter] = RectCenter(rect);

% Make a base Rect of 100 by 100 pixels
display.baseRect = [0 0 100 100];
display.quesrect = [0 0 1000 200];

%trial param
param.numblocks =3; %number of blocks
param.ntrials =40; %number of trials
param.conditions = [1 2 3 4]; %four conditions; IDA, EDA, IDA with thought probe, EDA with thought probe
param.trialLine = repmat(param.conditions, 1, (param.ntrials/4));
param.condmatrix = Shuffle(param.trialLine);
param.cueduration = (0.7:0.1:1.2);
param.intertrialinterval = (0.5:0.1:1);
param.delay1 = (0.5:0.1:1);
param.stimDuration = (1.5:0.1:2);
param.delay2 = 1;

%trail counter
countselfref = 0;
countvowel = 0;
countselfrefTP = 0;
countvowelTP = 0;

%stimulus parameters and color wheel 
param.nColors=360; % resolution of color wheel
param.rgbVals=uint8((hsv(param.nColors))*255); % create color wheel
param.wheelRadius=2*[128 156]; % inner and outer radii of annulus
eegwordlist_self = importdata('eegwordlist_self.mat');
eegwordlist_vowel = importdata('eegwordlist_vowel.mat');

%wheel texture
[X, Y]=meshgrid(-param.wheelRadius(2):param.wheelRadius(2)-1);    %2D matrix of radial distances from centre
radDist=(X.^2+Y.^2).^0.5; % distance from center for annulus
angDist=round(1+(param.nColors-1)*(0.5+atan2(-Y, X)/(2*pi()))); % orientations around wheel, mapped onto colors
rPlane=zeros(param.wheelRadius(2)*2, param.wheelRadius(2)*2); % create wheel for each RGB color
gPlane=zeros(param.wheelRadius(2)*2, param.wheelRadius(2)*2);
bPlane=zeros(param.wheelRadius(2)*2, param.wheelRadius(2)*2);
colWheel=zeros(param.wheelRadius(2)*2, param.wheelRadius(2)*2, 4); % grab memory for color wheel and alpha window
for colNo=1:param.nColors % work through colors and assign to positions in wheel
    rPlane(angDist==colNo)=param.rgbVals(colNo, 1);
    gPlane(angDist==colNo)=param.rgbVals(colNo, 2);
    bPlane(angDist==colNo)=param.rgbVals(colNo, 3);
end
donutWin=255*ones(2*param.wheelRadius(2)); % make anulus window
donutWin(radDist<param.wheelRadius(1))=0; % inner part is transparent
donutWin(radDist>param.wheelRadius(2))=0; % outer part is transparent
colWheel(:,:,1)=rPlane;
colWheel(:,:,2)=gPlane;
colWheel(:,:,3)=bPlane;
colWheel(:,:,4)=donutWin;
colWheelTex=Screen('MakeTexture', mywin, colWheel);
wheelRect=CenterRect([0 0 param.wheelRadius(2)*2 param.wheelRadius(2)*2],rect);

%Image dir.
cd 'F:\practice\test.images';

% Read the images.
img.zero = imread('zero0.png');
img.one = imread('one1.png');
img.two = imread('two2.png');
img.three = imread('three3.png');
img.four = imread('four4.png');
img.five = imread('five5.png');
img.six = imread('six6.png');
img.question = imread('question.png');
img.ans1 = imread('ans1.png');
img.ans2 = imread('ans2.png');
img.ans3 = imread('ans3.png');
img.ans4 = imread('ans4.png');
img.ans5 = imread('ans5.png');
img.ans6 = imread('ans6.png');
img.black = imread('black.png');
% make texture for numbers
tex.T0 = Screen('MakeTexture', mywin, img.zero);
tex.T1 = Screen('MakeTexture', mywin, img.one);
tex.T2 = Screen('MakeTexture', mywin, img.two);
tex.T3 = Screen('MakeTexture', mywin, img.three);
tex.T4 = Screen('MakeTexture', mywin, img.four);
tex.T5 = Screen('MakeTexture', mywin, img.five);
tex.T6 = Screen('MakeTexture', mywin, img.six);
tex.question = Screen('MakeTexture', mywin, img.question);
tex.ans1 = Screen('MakeTexture', mywin, img.ans1);
tex.ans2 = Screen('MakeTexture', mywin, img.ans2);
tex.ans3 = Screen('MakeTexture', mywin, img.ans3);
tex.ans4 = Screen('MakeTexture', mywin, img.ans4);
tex.ans5 = Screen('MakeTexture', mywin, img.ans5);
tex.ans6 = Screen('MakeTexture', mywin, img.ans6);
tex.black = Screen('MakeTexture', mywin, img.black);

T = [tex.T0 tex.T1 tex.T2 tex.T3 tex.T4 tex.T5 tex.T6]; % Vector of images.
ThoughtProbe = [tex.question tex.ans1 tex.ans2 tex.ans3 tex.ans4 tex.ans5 tex.ans6];


%make rect for each image
rectnum.n0 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.125, display.screenYpixels*0.5)';
rectnum.n1 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.25, display.screenYpixels*0.5)';
rectnum.n2 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.375, display.screenYpixels*0.5)';
rectnum.n3 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.5, display.screenYpixels*0.5)';
rectnum.n4 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.625, display.screenYpixels*0.5)';
rectnum.n5 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.75, display.screenYpixels*0.5)';
rectnum.n6 = CenterRectOnPointd(display.baseRect, display.screenXpixels*0.875, display.screenYpixels*0.5)';
rectnum.question = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.125)';
rectnum.ans1 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.25)';
rectnum.ans2 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.375)';
rectnum.ans3 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.5)';
rectnum.ans4 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.625)';
rectnum.ans5 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.75)';
rectnum.ans6 = CenterRectOnPointd(display.quesrect, display.screenXpixels*0.5, display.screenYpixels*0.875)';
rects = [rectnum.n0 rectnum.n1 rectnum.n2 rectnum.n3 rectnum.n4 rectnum.n5 rectnum.n6];
rectsquestion = [rectnum.question rectnum.ans1 rectnum.ans2 rectnum.ans3 rectnum.ans4 rectnum.ans5 rectnum.ans6];

% result matrix
responseMat = cell(param.ntrials, 10);

% Keyboard setup
responseKeys = {'space'};
KbName('UnifyKeyNames');
KbCheckList = [KbName('space'),KbName('ESCAPE')];
KbCheckList = [KbName(responseKeys),KbCheckList];
RestrictKeysForKbCheck(KbCheckList);

%sample rate EEG
sampleRate = 1000;
ttrigger = 1/sampleRate/2;

%eeg markers
mrk.ITI = 1;
mrk.cueselfrefcondition = 2;
mrk.cuevowelcondition = 9;
mrk.delay1 = 3;
mrk.word = 4;
mrk.rating = 5;
mrk.delay2 = 6;
mrk.colwhe = 7;
mrk.colwheend = 8;

%EEG trigger stuff. Set up the parallel port using the io64 module.
config_io;
%parallel port address
ppAddress = hex2dec('378');

%% %%%%%%%%%%%%%%%%%% Trial start %%%%%%%%%%%%%%%%%%%%%%%%%%%%
for blockNo = 1:param.numblocks
    
    Screen('TextSize',mywin, 50);
    Screen('TextFont', mywin, 'Cambria');
    DrawFormattedText(mywin, 'Press the space bar to begin' , 'center', 'center', [0 0 0]);
    Screen('Flip', mywin);
    % Wait for subject to press spacebar
    while 1
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1
            break
        end
    end
    
    for trialNo= 1:param.ntrials
        
        %information about this trial
        thistrial = param.condmatrix(1,trialNo);
        %label trial
        if  thistrial == 1
            thistriallabel = 'internal distractor condition';
        elseif thistrial == 2
            thistriallabel = 'external distractor condition';
        elseif thistrial == 3
            thistriallabel = 'internal distractor with thought-probe';
        elseif thistrial == 4
            thistriallabel = 'external distractor with thought-probe';
        end
                      
        %condition count
        if thistrial ==1
            countselfref = countselfref + 1;
            countselfrefTP = countselfrefTP + 1;
        elseif thistrial ==2
            countvowel = countvowel + 1;
            countvowelTP = countvowelTP + 1;
        elseif thistrial ==3
            countselfref = countselfref + 1;
            countselfrefTP = countselfrefTP + 1;
        elseif thistrial ==4
            countvowel = countvowel + 1;
            countvowelTP = countvowelTP + 1;
            
        end
        countselfref;
        countvowel;
        countselfrefTP;
        countvowelTP;
        
        %intertrial interval
        
        %trigger for trial type
        if (thistrial == 1) || (thistrial == 3)
            outp( ppAddress, mrk.selfrefcondition); WaitSecs(ttrigger);
            outp( ppAddress, 0); WaitSecs(ttrigger);
        elseif (thistrial == 2) || (thistrial == 4)
            outp( ppAddress, mrk.vowelcondition); WaitSecs(ttrigger);
            outp( ppAddress, 0); WaitSecs(ttrigger);
        end

        HideCursor(mywin);

        %present fixation___has to be of variable timing.
        Screen('TextSize',mywin, 50);
        Screen('TextFont', mywin, 'Arial');
        DrawFormattedText(mywin, 'X' , 'center', 'center', [0 0 0]);
        Screen('Flip', mywin);
                outp( ppAddress, mrk.ITI); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        WaitSecs (randsample(param.intertrialinterval,1));
        
        
        %present cue
        Screen('TextSize',mywin, 50);
        Screen('TextFont', mywin, 'Cambria');
        if thistrial == 1
            DrawFormattedText(mywin, 'Self' , 'center', 'center', [0 0 0]);
        elseif thistrial ==2
            DrawFormattedText(mywin, 'Vowels' , 'center', 'center', [0 0 0]);
        elseif thistrial ==3
            DrawFormattedText(mywin, 'Self' , 'center', 'center', [0 0 0]);
        elseif thistrial ==4
            DrawFormattedText(mywin, 'Vowels' , 'center', 'center', [0 0 0]);
        end
        Screen('Flip', mywin);
                outp(ppAddress, mrk.cue); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        WaitSecs(randsample(param.cueduration,1));
        
        %Fixation during trial
        %Screen ('DrawTexture',mywin,tex.Tf);
        Screen('TextSize',mywin, 50);
        Screen('TextFont', mywin, 'Arial');
        DrawFormattedText(mywin, 'X' , 'center', 'center', [0 0 0]);
        Screen ('Flip',mywin);
                outp(ppAddress, mrk.delay1); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        WaitSecs (randsample(param.delay1,1));
        
        
        %WORD PRESENTATION
        if thistrial ==1
            Word = eegwordlist_self(countselfref,1);
        elseif thistrial==2
            Word = eegwordlist_vowel(countvowel,1);
        elseif thistrial ==3
            Word = eegwordlist_self(countselfref,1);
        elseif thistrial ==4
            Word = eegwordlist_vowel(countvowel,1);
        end
        Wordcolor = param.rgbVals(randi(size(param.rgbVals,1)),:);  %select random color
        anglepresented = {180 - (find( ismember(param.rgbVals,Wordcolor,'rows')>0))}; %angle of color presented
        Screen('TextSize',mywin, 50);
        Screen('TextFont', mywin, 'Cambria');
        DrawFormattedText(mywin, char(Word), 'center', 'center', Wordcolor);
        Screen('Flip',mywin);
                outp(ppAddress, mrk.word); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        WaitSecs (randsample(param.stimDuration,1));
                   
        %ratings for self-ref.
        Screen('DrawTextures', mywin, T, [], rects);
        Screen ('Flip', mywin);
                outp(ppAddress, mrk.rating); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        SetMouse(display.xCenter, display.yCenter, mywin);
        ShowCursor('CrossHair', mywin);
        %WaitSecs (1);
        
        tstart = GetSecs;
        % get a response
        [x,y,buttons] = GetMouse(display.screenNumber);
        while any(buttons) % if already down, wait for release
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        while ~any(buttons) % wait for press
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        while any(buttons) % wait for release
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        
        tend = GetSecs;
        reactiontimeWord = {tend - tstart};
        
        xPos = x;
        yPos = y;
        ratingPos = [(xPos) (yPos) (xPos+1) (yPos+1)];
        
        %check the self-ref response in which rects
        check.inside0 = IsInRect(xPos,yPos, rectnum.n0);
        check.inside1 = IsInRect(xPos,yPos, rectnum.n1);
        check.inside2 = IsInRect(xPos,yPos, rectnum.n2);
        check.inside3 = IsInRect(xPos,yPos, rectnum.n3);
        check.inside4 = IsInRect(xPos,yPos, rectnum.n4);
        check.inside5 = IsInRect(xPos,yPos, rectnum.n5);
        check.inside6 = IsInRect(xPos,yPos, rectnum.n6);
        inside = [check.inside0 check.inside1 check.inside2 check.inside3 check.inside4 check.inside5 check.inside6];
        % WaitSecs (2);
        HideCursor(mywin);
        
        %Fixation during trial
        Screen('TextSize',mywin, 50);
        Screen('TextFont', mywin, 'Arial');
        DrawFormattedText(mywin, 'X' , 'center', 'center', [0 0 0]);
        Screen ('Flip',mywin);
                outp(ppAddress, mrk.delay2); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        WaitSecs (param.delay2);
        
        %colour wheel
        %texture for color wheel
        %wheelOri= randi(360); %orientation for color wheel
        Screen('DrawTexture', mywin, colWheelTex,[0 0 param.wheelRadius(2)*2 param.wheelRadius(2)*2],wheelRect); %wheelOri); % show the response wheel
                outp(ppAddress, mrk.colwhe); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        Screen('Flip',mywin);
        
        % Put mouse in middle of screen
        ShowCursor('CrossHair', mywin);
        SetMouse(display.xCenter,display.yCenter,mywin);
        
        tstart = GetSecs;
        
        % get a response
        [x,y,buttons] = GetMouse(display.screenNumber);
        while any(buttons) % if already down, wait for release
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        while ~any(buttons) % wait for press
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        while any(buttons) % wait for release
            [x,y,buttons] = GetMouse(display.screenNumber);
        end
        
        tend = GetSecs;
                outp(ppAddress, mrk.colwheend); WaitSecs(ttrigger);
                outp( ppAddress, 0); WaitSecs(ttrigger);
        reactiontimeColWhe = {tend-tstart};
        
        xPos = x;
        yPos = y;
        posRect = [(xPos) (yPos) (xPos+1) (yPos+1)];
        
        responseOrientation= atan2d(yPos-display.yCenter, xPos-display.xCenter);
        
        % Get an RGB value for that location on the screen
        % imageArray=Screen('GetImage', windowPtr [,rect] [,bufferName])
        responseRGB=Screen('GetImage',mywin, posRect);
        
        %%%%%%%thought probe%%%%%
        if (thistrial == 3) || (thistrial == 4)
            Screen('DrawTextures', mywin, ThoughtProbe , [], rectsquestion);
            Screen ('Flip', mywin);
            SetMouse(display.xCenter, display.yCenter, mywin);
            ShowCursor('CrossHair', mywin);
            
            % get a response
            [x,y,buttons] = GetMouse(display.screenNumber);
            while any(buttons) % if already down, wait for release
                [x,y,buttons] = GetMouse(display.screenNumber);
            end
            while ~any(buttons) % wait for press
                [x,y,buttons] = GetMouse(display.screenNumber);
            end
            while any(buttons) % wait for release
                [x,y,buttons] = GetMouse(display.screenNumber);
            end
            
            xPos = x;
            yPos = y;
            ratingPos = [(xPos) (yPos) (xPos+1) (yPos+1)];
            
            %check the thought probe response in which rects
            
            check.insideans1 = IsInRect(xPos,yPos, rectnum.ans1);
            check.insideans2 = IsInRect(xPos,yPos, rectnum.ans2);
            check.insideans3 = IsInRect(xPos,yPos, rectnum.ans3);
            check.insideans4 = IsInRect(xPos,yPos, rectnum.ans4);
            check.insideans5 = IsInRect(xPos,yPos, rectnum.ans5);
            check.insideans6 = IsInRect(xPos,yPos, rectnum.ans6);
            insideques = [check.insideans1 check.insideans2 check.insideans3 check.insideans4 check.insideans5 check.insideans6];
        end
        
        HideCursor(mywin);
        Screen ('DrawTexture', mywin, tex.black)
        Screen ('Flip', mywin);
        WaitSecs(1)
        
        %% cell array and save results
        cell.thistriallabel = {thistriallabel};
        cell.Word = {Word};
        cell.Wordcolor = {Wordcolor};
        cell.responseRGB = {responseRGB};
        cell.responseOrientation = {responseOrientation};
        cell.AFCresp = {inside};
        
        %%save results
        responseMat(trialNo, 1) = cell.thistriallabel;
        responseMat(trialNo, 2) = cell.Word;
        responseMat(trialNo, 3) = anglepresented;
        responseMat(trialNo, 4) = cell.Wordcolor;
        responseMat(trialNo, 5) = cell.AFCresp;
        responseMat(trialNo, 6) = reactiontimeWord;
        responseMat(trialNo, 7) = cell.responseRGB;
        responseMat(trialNo, 8) = reactiontimeColWhe;
        responseMat(trialNo, 9) = cell.responseOrientation;
        if (thistrial == 3) || (thistrial == 4)
            cell.thoughtproberesponse = {insideques};
            responseMat(trialNo, 10) = cell.thoughtproberesponse;
        end
    end
    
    cd 'F:\practice\test.images\practiceresp';
    save(sprintf( '%s %i.mat',SubjectID, blockNo), 'responseMat');
    
end
Screen('Close' , mywin);