%% Full and Partial Correlation Connectivity Analysis

% The Matlab script uses FSLnets to perform the connectivity analysis for the
% regions of interest defined within it. Both full and partial correlation is
% analysed for both left and right hemispheres, thus, the hemispheres are
% treated individually within the script.
%
% To read and write the data into and out of Matlab, two functions:
% ft_cifti_read and ciftisave are used.
%
% For these functions to work, two repositories from Washington University
% must be saved to your local system so that the scripts for that enable
% these functions to work can be accessed.
%
% ft_read_cifti requires the repository available at:
% https://github.com/Washington-University/cifti-matlab
%
% cifti_save requires the repository available at:
% https://github.com/Washington-University/HCPpipelines/tree/master/global/matlab
%
% The script has been written in a way that assumes both of these folders
% have been saved in one and the same directory.


clear all
close all
clc

%% Setup

% add path to FSLNets
addpath('/gpfs01/software/imaging/FSLNets')
addpath(genpath('/gpfs01/software/imaging/fsl/6.0.1/'))

% addpath to fMRI_Connectivity_Analysis folder that cotains toolbox
% aswell as the Matlab scripts and the edited netjs package.

% toolbox contains both ciftisave and ft_read_cifti
% MatlabScripts contains the editied nets_netweb script
% netjs has been edited to display node labels

% use system to enter unix command to find the path to the folder that
% contains the required scripts, files and data on the users system.
fCA_path='/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis';
addpath(genpath(fCA_path)); % genpath adds path of files in folders
clear status

% assign workbench_command to variable wbc for use in cifti save (see cifti
% save for details)
wbc = '/software/connectome/workbench-v1.3.2/bin_rh_linux64/wb_command'; addpath(wbc);

% set path to txt file containing alpha-numeric idx references to the
% participant data that is to be excluded from the analysis
excludedPath = sprintf('%s/comparisonFiles/excluded.txt', fCA_path);

% set path to txt file containg count of participants that fall into the
% categories of yes, no and to be excluded from the analysis
countPath = sprintf('%s/comparisonFiles/count.txt', fCA_path);

% set path to design matrix txt file for use in producing Tin and NonTin
% netwebs
designTxt = sprintf('%s/comparisonFiles/design.txt', fCA_path);

% set paths to data
parentDirName = 'Pre_FSLNetsAnalysis_Out';
dataPath = sprintf('%s/%s', fCA_path, parentDirName);
ts_dir = 'converted_to_text_ptseries';
L_ts_folder = 'L_ptseries';
R_ts_folder = 'R_ptseries';

% set script output directory
outDir = sprintf('%s/FSLNetsAnalysis_Out', fCA_path);

% path to tseries files
LH_ts_dir = sprintf('%s/%s/%s', dataPath, ts_dir, L_ts_folder);
RH_ts_dir = sprintf('%s/%s/%s', dataPath, ts_dir, R_ts_folder);

% set method for nets_netmats
NetmatMethod = 1;  % method 1 applies Fisher's r-to-z transformation

%% Import excluded, count and design txt file data

% import design matrix txt file data into arrays
txt = importdata(designTxt);
yesIdxs = find(txt(:,1))';
noIdxs = find(txt(:,2))';

s = dir(excludedPath);
if s.bytes == 0
    exclSubjIds = 0;
    excludedIdxs = 0;
else
    txt = importdata(excludedPath);
    exclSubjIds = txt(:,1);
    excludedIdxs = txt(:,2);
    excludedIdxs = excludedIdxs.';
end



% import count data - number of participants split between yes, no and
% excluded from the analysis
[count_yes, count_no, count_excluded] = importCount(countPath);

% Read in text file as string to be displayed
fid = fopen(countPath);

% Read all lines & collect in cell array
txt = textscan(fid,'%s','delimiter','\n');
for i = 1 : length(txt{1})
    disp(txt{1}{i})
end

dummy = ft_read_cifti(sprintf('%s/L.dummy.pconn.nii',dataPath));

relevantROIs = {'RI','A1','LBelt','PBelt','MBelt','A4','TA2','A5','STGa','STSda','STSdp','STSva','STSvp','H','PreS','EC','PHA1','PHA2','PHA3'};
Early_Auditory = {'A1','LBelt', 'MBelt', 'PBelt', 'RI'};
Auditory_Association = {'A4', 'A5', 'STSdp', 'STSda', 'STSva', 'STGa', 'TA2'};
Parahippocampus = {'PHA1', 'PHA2', 'PHA3'};
Planum_Temporale = {'PSL', 'STV', 'TPOJ1'};
Coarse_Clusters = {'EAC', 'AAC', 'PH', 'PT'};

roiIndices = [];
EAIndices = [];
AAIndices = [];
PHIndices = [];
PTIndices = [];

for i = 1:length(relevantROIs)
   roiIndices(end+1) = find(strcmp(dummy.label, ['L_',relevantROIs{i},'_ROI']));
end

for i = 1:length(Early_Auditory)
   EAIndices(end+1) = find(strcmp(dummy.label, ['L_',Early_Auditory{i},'_ROI']));
end

for i = 1:length(Auditory_Association)
   AAIndices(end+1) = find(strcmp(dummy.label, ['L_',Auditory_Association{i},'_ROI']));
end

for i = 1:length(Parahippocampus)
   PHIndices(end+1) = find(strcmp(dummy.label, ['L_',Parahippocampus{i},'_ROI']));
end

for i = 1:length(Planum_Temporale)
   PTIndices(end+1) = find(strcmp(dummy.label, ['L_',Planum_Temporale{i},'_ROI']));
end

%% Remove timeseries data for participants to be excluded from analysis

% load tseries data
LH_ts = nets_load(LH_ts_dir, 0.735, 1);
RH_ts = nets_load(RH_ts_dir, 0.735, 1);
LH_ts_orig = LH_ts;
RH_ts_orig = RH_ts;
NtPerSub = LH_ts.NtimepointsPerSubject;

if s.bytes ~= 0

    % remove data for participants excluded from the analysis

    rempar_ind = repelem((excludedIdxs-1)*NtPerSub, NtPerSub)...
        +repmat(1:NtPerSub, 1, length(excludedIdxs));

    a = LH_ts.ts;
    a(rempar_ind,:) = [];
    LH_ts.ts = a;
    clear a

    a = RH_ts.ts;
    a(rempar_ind,:) = [];
    RH_ts.ts = a;
    clear a

    % Change properties of ts to reflect changes to data that have been made
    LH_ts.Nsubjects = LH_ts.Nsubjects - count_excluded;
    NtimepointsExcluded = NtPerSub* length(excludedIdxs);
    LH_ts.Ntimepoints = LH_ts.Ntimepoints - NtimepointsExcluded;

    RH_ts.Nsubjects = RH_ts.Nsubjects - count_excluded;
    NtimepointsExcluded = NtPerSub * length(excludedIdxs);
    RH_ts.Ntimepoints = RH_ts.Ntimepoints - NtimepointsExcluded;
end

%% create ts for coarser parcels

LH_ts_coarse = LH_ts_orig;
LH_ts_coarse.ts = horzcat( mean(LH_ts_orig.ts(:, EAIndices), 2), ...
    mean(LH_ts_orig.ts(:, AAIndices), 2), ... 
    mean(LH_ts_orig.ts(:, PHIndices), 2), ...
    mean(LH_ts_orig.ts(:, PTIndices),2));

LH_ts_coarse.Nnodes = size(LH_ts_coarse.ts, 2);
LH_ts_coarse.DD = 1:size(LH_ts_coarse.ts, 2);

RH_ts_coarse = RH_ts_orig;
RH_ts_coarse.ts = horzcat( mean(RH_ts_orig.ts(:, EAIndices), 2), ...
    mean(RH_ts_orig.ts(:, AAIndices), 2), ...
    mean(RH_ts_orig.ts(:, PHIndices), 2), ...
    mean(RH_ts_orig.ts(:, PTIndices),2));

RH_ts_coarse.Nnodes = size(RH_ts_coarse.ts, 2);
RH_ts_coarse.DD = 1:size(RH_ts_coarse.ts, 2);

%% Separate Tin, noTin timerseries data to produce Tin v noTin netwebs

rempar_ind = repelem((noIdxs-1)*NtPerSub,NtPerSub)+repmat(1:NtPerSub,1,length(noIdxs));

a = LH_ts.ts;
LH_Tin_ts = LH_ts;
a(rempar_ind,:) = [];
LH_Tin_ts.ts = a;
clear a

LH_Tin_ts.Nsubjects = count_yes;
LH_Tin_ts.Ntimepoints = NtPerSub * count_yes;

a = RH_ts.ts;
RH_Tin_ts = RH_ts;
a(rempar_ind,:) = [];
RH_Tin_ts.ts = a;
clear a

RH_Tin_ts.Nsubjects = count_yes;
RH_Tin_ts.Ntimepoints = NtPerSub * count_yes;

rempar_ind = repelem((yesIdxs-1)*NtPerSub,NtPerSub)+repmat(1:NtPerSub,1,length(yesIdxs));

a = LH_ts.ts;
LH_noTin_ts = LH_ts;
a(rempar_ind,:) = [];
LH_noTin_ts.ts = a;
clear a

LH_noTin_ts.Nsubjects = count_no;
LH_noTin_ts.Ntimepoints = NtPerSub * count_no;

a = RH_ts.ts;
RH_noTin_ts = RH_ts;
a(rempar_ind,:) = [];
RH_noTin_ts.ts = a;
clear a

RH_noTin_ts.Nsubjects = count_no;
RH_noTin_ts.Ntimepoints = NtPerSub * count_no;

%% Tin and noTin ts coarse

LH_Tin_ts_coarse = LH_Tin_ts;
LH_Tin_ts_coarse.ts = horzcat( mean(LH_Tin_ts.ts(:, EAIndices), 2), ...
    mean(LH_Tin_ts.ts(:, AAIndices), 2), ... 
    mean(LH_Tin_ts.ts(:, PHIndices), 2), ...
    mean(LH_Tin_ts.ts(:, PTIndices),2));

LH_Tin_ts_coarse.Nnodes = size(LH_Tin_ts_coarse.ts, 2);
LH_Tin_ts_coarse.DD = 1:size(LH_Tin_ts_coarse.ts, 2);

LH_noTin_ts_coarse = LH_noTin_ts;
LH_noTin_ts_coarse.ts = horzcat( mean(LH_noTin_ts.ts(:, EAIndices), 2), ...
    mean(LH_noTin_ts.ts(:, AAIndices), 2), ... 
    mean(LH_noTin_ts.ts(:, PHIndices), 2), ...
    mean(LH_noTin_ts.ts(:, PTIndices),2));

LH_noTin_ts_coarse.Nnodes = size(LH_noTin_ts_coarse.ts, 2);
LH_noTin_ts_coarse.DD = 1:size(LH_noTin_ts_coarse.ts, 2);

RH_Tin_ts_coarse = RH_Tin_ts;
RH_Tin_ts_coarse.ts = horzcat( mean(RH_Tin_ts.ts(:, EAIndices), 2), ...
    mean(RH_Tin_ts.ts(:, AAIndices), 2), ... 
    mean(RH_Tin_ts.ts(:, PHIndices), 2), ...
    mean(RH_Tin_ts.ts(:, PTIndices),2));

RH_Tin_ts_coarse.Nnodes = size(RH_Tin_ts_coarse.ts, 2);
RH_Tin_ts_coarse.DD = 1:size(RH_Tin_ts_coarse.ts, 2);

RH_noTin_ts_coarse = RH_noTin_ts;
RH_noTin_ts_coarse.ts = horzcat( mean(RH_noTin_ts.ts(:, EAIndices), 2), ...
    mean(RH_noTin_ts.ts(:, AAIndices), 2), ... 
    mean(RH_noTin_ts.ts(:, PHIndices), 2), ...
    mean(RH_noTin_ts.ts(:, PTIndices),2));

RH_noTin_ts_coarse.Nnodes = size(RH_noTin_ts_coarse.ts, 2);
RH_noTin_ts_coarse.DD = 1:size(RH_noTin_ts_coarse.ts, 2);

%% Join Tin & No-Tin ts data, for use in producing netmats for use in nets_lda

LH_ts_lda_ny_180 = LH_ts_orig;
LH_ts_lda_ny_180.ts = vertcat(LH_noTin_ts.ts, LH_Tin_ts.ts);

RH_ts_lda_ny_180 = RH_ts_orig;
RH_ts_lda_ny_180.ts = vertcat(RH_noTin_ts.ts, RH_Tin_ts.ts);

LH_ts_lda_ny_19 = LH_ts_lda_ny_180;
RH_ts_lda_ny_19 = RH_ts_lda_ny_180;

LH_ts_lda_ny_19.ts = LH_ts_lda_ny_19.ts(:, roiIndices);
LH_ts_lda_ny_19.Nnodes = length(roiIndices);
LH_ts_lda_ny_19.DD = roiIndices;

RH_ts_lda_ny_19.ts = RH_ts_lda_ny_19.ts(:, roiIndices);
RH_ts_lda_ny_19.Nnodes = length(roiIndices);
RH_ts_lda_ny_19.DD = roiIndices;

%% Read in dummy pconn template file and extract ROI indices

% read in dummy pconn template file using ft_read_cifti

dummyL = ft_read_cifti(sprintf('%s/L.dummy.pconn.nii',dataPath));
dummyR = ft_read_cifti(sprintf('%s/R.dummy.pconn.nii',dataPath));

%% Extract ts data for relevant ROIs

LH_ts_180 = LH_ts;
RH_ts_180 = RH_ts;
LH_ts_19 = LH_ts;
RH_ts_19 = RH_ts;

LH_ts_19.ts = [];
RH_ts_19.ts = [];

LH_ts_19.ts = LH_ts.ts(:, roiIndices);
LH_ts_19.Nnodes = length(roiIndices);
LH_ts_19.DD = roiIndices;

RH_ts_19.ts = RH_ts.ts(:, roiIndices);
RH_ts_19.Nnodes = length(roiIndices);
RH_ts_19.DD = roiIndices;

%% Estimate Full and Partial Connectivity at subject and group level for ts_180

% estimate Full and Partial Connectivity at subject level
LH_netmatF_180 = nets_netmats(LH_ts_180, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_180 = nets_netmats(LH_ts_180, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_180 = nets_netmats(RH_ts_180, NetmatMethod, 'corr');
RH_netmatP_180 = nets_netmats(RH_ts_180, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_180,LH_MnetF_180]=nets_groupmean(LH_netmatF_180,0,1);
[LH_ZnetP_180,LH_MnetP_180]=nets_groupmean(LH_netmatP_180,0,1);

[RH_ZnetF_180,RH_MnetF_180]=nets_groupmean(RH_netmatF_180,0,1);
[RH_ZnetP_180,RH_MnetP_180]=nets_groupmean(RH_netmatP_180,0,1);

%% Estimate Full and Partial Connectivity at subject and group level for ts_19

% estimate Full and Partial Connectivity at subject level
LH_netmatF_19 = nets_netmats(LH_ts_19, NetmatMethod, 'corr');             % netmat = network matrix
LH_netmatP_19 = nets_netmats(LH_ts_19, NetmatMethod, 'ridgep', 0.01);     % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_19 = nets_netmats(RH_ts_19, NetmatMethod, 'corr');
RH_netmatP_19 = nets_netmats(RH_ts_19, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_19,LH_MnetF_19]=nets_groupmean(LH_netmatF_19,0,1);
[LH_ZnetP_19,LH_MnetP_19]=nets_groupmean(LH_netmatP_19,0,1);

[RH_ZnetF_19,RH_MnetF_19]=nets_groupmean(RH_netmatF_19,0,1);
[RH_ZnetP_19,RH_MnetP_19]=nets_groupmean(RH_netmatP_19,0,1);

%% Estimate Full and Partial Connectivity at subject and group level for ts_Tin and ts_noTin

% estimate Full and Partial Connectivity at subject level
LH_netmatF_Tin = nets_netmats(LH_Tin_ts, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_Tin = nets_netmats(LH_Tin_ts, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_Tin = nets_netmats(RH_Tin_ts, NetmatMethod, 'corr');
RH_netmatP_Tin = nets_netmats(RH_Tin_ts, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_Tin,LH_MnetF_Tin]=nets_groupmean(LH_netmatF_Tin,0,1);
[LH_ZnetP_Tin,LH_MnetP_Tin]=nets_groupmean(LH_netmatP_Tin,0,1);

[RH_ZnetF_Tin,RH_MnetF_Tin]=nets_groupmean(RH_netmatF_Tin,0,1);
[RH_ZnetP_Tin,RH_MnetP_Tin]=nets_groupmean(RH_netmatP_Tin,0,1);


LH_netmatF_noTin = nets_netmats(LH_noTin_ts, NetmatMethod, 'corr');             % netmat = network matrix
LH_netmatP_noTin = nets_netmats(LH_noTin_ts, NetmatMethod, 'ridgep', 0.01);     % small amount of L2 regularisation for the partial netmats
                                                                                % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                                % use any regularization (based on their supplementary methods)
RH_netmatF_noTin = nets_netmats(RH_noTin_ts, NetmatMethod, 'corr');
RH_netmatP_noTin = nets_netmats(RH_noTin_ts, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_noTin,LH_MnetF_noTin]=nets_groupmean(LH_netmatF_noTin,0,1);
[LH_ZnetP_noTin,LH_MnetP_noTin]=nets_groupmean(LH_netmatP_noTin,0,1);

[RH_ZnetF_noTin,RH_MnetF_noTin]=nets_groupmean(RH_netmatF_noTin,0,1);
[RH_ZnetP_noTin,RH_MnetP_noTin]=nets_groupmean(RH_netmatP_noTin,0,1);

%% coarse netmats

% estimate Full and Partial Connectivity at subject level
LH_netmatF_coarse = nets_netmats(LH_ts_coarse, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_coarse = nets_netmats(LH_ts_coarse, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_coarse = nets_netmats(RH_ts_coarse, NetmatMethod, 'corr');
RH_netmatP_coarse = nets_netmats(RH_ts_coarse, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_coarse,LH_MnetF_coarse]=nets_groupmean(LH_netmatF_coarse,0,1);
[LH_ZnetP_coarse,LH_MnetP_coarse]=nets_groupmean(LH_netmatP_coarse,0,1);

[RH_ZnetF_coarse,RH_MnetF_coarse]=nets_groupmean(RH_netmatF_coarse,0,1);
[RH_ZnetP_coarse,RH_MnetP_coarse]=nets_groupmean(RH_netmatP_coarse,0,1);

%% Tin noTin coarse clusters netmats

LH_netmatF_Tin_coarse = nets_netmats(LH_Tin_ts_coarse, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_Tin_coarse = nets_netmats(LH_Tin_ts_coarse, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_Tin_coarse = nets_netmats(RH_Tin_ts_coarse, NetmatMethod, 'corr');
RH_netmatP_Tin_coarse = nets_netmats(RH_Tin_ts_coarse, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_Tin_coarse,LH_MnetF_Tin_coarse]=nets_groupmean(LH_netmatF_Tin_coarse,0,1);
[LH_ZnetP_Tin_coarse,LH_MnetP_Tin_coarse]=nets_groupmean(LH_netmatP_Tin_coarse,0,1);

[RH_ZnetF_Tin_coarse,RH_MnetF_Tin_coarse]=nets_groupmean(RH_netmatF_Tin_coarse,0,1);
[RH_ZnetP_Tin_coarse,RH_MnetP_Tin_coarse]=nets_groupmean(RH_netmatP_Tin_coarse,0,1);

LH_netmatF_noTin_coarse = nets_netmats(LH_noTin_ts_coarse, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_noTin_coarse = nets_netmats(LH_noTin_ts_coarse, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_noTin_coarse = nets_netmats(RH_noTin_ts_coarse, NetmatMethod, 'corr');
RH_netmatP_noTin_coarse = nets_netmats(RH_noTin_ts_coarse, NetmatMethod, 'ridgep', 0.01);


% estimate Full and Partial Connectivity at group level
[LH_ZnetF_noTin_coarse,LH_MnetF_noTin_coarse]=nets_groupmean(LH_netmatF_noTin_coarse,0,1);
[LH_ZnetP_noTin_coarse,LH_MnetP_noTin_coarse]=nets_groupmean(LH_netmatP_noTin_coarse,0,1);

[RH_ZnetF_noTin_coarse,RH_MnetF_noTin_coarse]=nets_groupmean(RH_netmatF_noTin_coarse,0,1);
[RH_ZnetP_noTin_coarse,RH_MnetP_noTin_coarse]=nets_groupmean(RH_netmatP_noTin_coarse,0,1);

%% lda netmats 180 parcels

% estimate Full and Partial Connectivity at subject level
LH_netmatF_lda_ny_180 = nets_netmats(LH_ts_lda_ny_180, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_lda_ny_180 = nets_netmats(LH_ts_lda_ny_180, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_lda_ny_180 = nets_netmats(RH_ts_lda_ny_180, NetmatMethod, 'corr');
RH_netmatP_lda_ny_180 = nets_netmats(RH_ts_lda_ny_180, NetmatMethod, 'ridgep', 0.01);

%% Estimate Full and Partial Connectivity at subject and group level for ts_19

% estimate Full and Partial Connectivity at subject level
LH_netmatF_lda_ny_19 = nets_netmats(LH_ts_lda_ny_19, NetmatMethod, 'corr');           % netmat = network matrix
LH_netmatP_lda_ny_19 = nets_netmats(LH_ts_lda_ny_19, NetmatMethod, 'ridgep', 0.01);   % small amount of L2 regularisation for the partial netmats
                                                                          % HCP used 0.01 in the 1,200 subjects data release - possible that Glasser et al (2016) didn't
                                                                          % use any regularization (based on their supplementary methods)
RH_netmatF_lda_ny_19 = nets_netmats(RH_ts_lda_ny_19, NetmatMethod, 'corr');
RH_netmatP_lda_ny_19 = nets_netmats(RH_ts_lda_ny_19, NetmatMethod, 'ridgep', 0.01);

%% Cross-subject comparison with netmats for netmat_180 and netmat_19

desFile = sprintf('%s/comparisonFiles/design.mat', fCA_path);
conFile = sprintf('%s/comparisonFiles/unpaired_ttest_1con.con', fCA_path);

[LH_uncorr_F180,LH_corr_F180]=nets_glm(LH_netmatF_180, desFile, conFile,1);
[LH_uncorr_P180,LH_corr_P180]=nets_glm(LH_netmatP_180, desFile, conFile,1);
[RH_uncorr_F180,RH_corr_F180]=nets_glm(RH_netmatF_180, desFile, conFile,1);
[RH_uncorr_P180,RH_corr_P180]=nets_glm(RH_netmatP_180, desFile, conFile,1);

[LH_uncorr_F19,LH_corr_F19]=nets_glm(LH_netmatF_19, desFile, conFile,1);
[LH_uncorr_P19,LH_corr_P19]=nets_glm(LH_netmatP_19, desFile, conFile,1);
[RH_uncorr_F19,RH_corr_F19]=nets_glm(RH_netmatF_19, desFile, conFile,1);
[RH_uncorr_P19,RH_corr_P19]=nets_glm(RH_netmatP_19, desFile, conFile,1);

%% Cross-subject comparisons for coarser parcellations

[LH_uncorr_F_coarse,LH_corr_F_coarse]=nets_glm(LH_netmatF_coarse, desFile, conFile,1);
[LH_uncorr_P_coarse,LH_corr_P_coarse]=nets_glm(LH_netmatP_coarse, desFile, conFile,1);
[RH_uncorr_F_coarse,RH_corr_F_coarse]=nets_glm(RH_netmatF_coarse, desFile, conFile,1);
[RH_uncorr_P_coarse,RH_corr_P_coarse]=nets_glm(RH_netmatP_coarse, desFile, conFile,1);

%% Save pconn files for Tin and noTin

pconnDir = sprintf('%s/FP_Correlation', outDir);
% read in dummy pconn template file for both hemispheres using ciftiopen
% for saving pconn files
% later (so that cifti is converted to gifti format)
cii_L = ciftiopen(sprintf('%s/L.dummy.pconn.nii', dataPath),wbc);
cii_R = ciftiopen(sprintf('%s/R.dummy.pconn.nii', dataPath),wbc);

% write over dummy and cii files to create pconn files for LR FP Correlation for use
% in extracting data for relevant ROIs and saving in workbench format


dummy.pconn = LH_ZnetF_Tin; LH_Full_Correlation_Tin = dummy;
cii_L.cdata = LH_MnetF_Tin; cii_LH_Full_Correlation_Tin = cii_L;
if ~isfile(sprintf('%s/LH_Full_Correlation_Tin%d.pconn.nii', pconnDir, count_yes))
    ciftisave(cii_LH_Full_Correlation_Tin, sprintf('%s/LH_Full_Correlation_Tin%d.pconn.nii', pconnDir, count_yes), wbc);
end


dummy.pconn = LH_ZnetP_Tin; LH_Partial_Correlation_Tin = dummy;
cii_L.cdata = LH_MnetP_Tin; cii_LH_Partial_Correlation_Tin = cii_L;
if ~isfile(sprintf('%s/LH_Partial_Correlation_Tin%d.pconn.nii', pconnDir, count_yes))
    ciftisave(cii_LH_Partial_Correlation_Tin, sprintf('%s/LH_Partial_Correlation_Tin%d.pconn.nii', pconnDir, count_yes), wbc);
end


dummy.pconn = RH_ZnetF_Tin; RH_Full_Correlation_Tin = dummy;
cii_R.cdata = RH_MnetF_Tin; cii_RH_Full_Correlation_Tin = cii_R;
if ~isfile(sprintf('%s/RH_Full_Correlation_Tin%d.pconn.nii', pconnDir, count_yes))
    ciftisave(cii_RH_Full_Correlation_Tin, sprintf('%s/RH_Full_Correlation_Tin%d.pconn.nii', pconnDir, count_yes), wbc);
end


dummy.pconn = RH_ZnetP_Tin; RH_Partial_Correlation_Tin = dummy;
cii_R.cdata = RH_MnetP_Tin; cii_RH_Partial_Correlation_Tin = cii_R;
if ~isfile(sprintf('%s/RH_Partial_Correlation_Tin%d.pconn.nii', pconnDir, count_yes))
    ciftisave(cii_RH_Partial_Correlation_Tin, sprintf('%s/RH_Partial_Correlation_Tin%d.pconn.nii', pconnDir, count_yes), wbc);
end

dummy.pconn = LH_ZnetF_noTin; LH_Full_Correlation_noTin = dummy;
cii_L.cdata = LH_ZnetF_noTin; cii_LH_Full_Correlation_noTin = cii_L;
if ~isfile(sprintf('%s/LH_Full_Correlation_noTin%d.pconn.nii', pconnDir, count_no))
    ciftisave(cii_LH_Full_Correlation_noTin, sprintf('%s/LH_Full_Correlation_noTin%d.pconn.nii', pconnDir, count_no), wbc);
end


dummy.pconn = LH_ZnetP_noTin; LH_Partial_Correlation_noTin = dummy;
cii_L.cdata = LH_MnetP_noTin; cii_LH_Partial_Correlation_noTin = cii_L;
if ~isfile(sprintf('%s/LH_Partial_Correlation_noTin%d.pconn.nii', pconnDir, count_no))
    ciftisave(cii_LH_Partial_Correlation_noTin, sprintf('%s/LH_Partial_Correlation_noTin%d.pconn.nii', pconnDir, count_no), wbc);
end


dummy.pconn = RH_ZnetF_noTin; RH_Full_Correlation_noTin = dummy;
cii_R.cdata = RH_MnetF_noTin; cii_RH_Full_Correlation_noTin = cii_R;
if ~isfile(sprintf('%s/RH_Full_Correlation_noTin%d.pconn.nii', pconnDir, count_no))
    ciftisave(cii_RH_Full_Correlation_noTin, sprintf('%s/RH_Full_Correlation_noTin%d.pconn.nii', pconnDir, count_no), wbc);
end


dummy.pconn = RH_ZnetP_noTin; RH_Partial_Correlation_noTin = dummy;
cii_R.cdata = RH_MnetP_noTin; cii_RH_Partial_Correlation_noTin = cii_R;
if ~isfile(sprintf('%s/RH_Partial_Correlation_noTin%d.pconn.nii', pconnDir, count_no))
    ciftisave(cii_RH_Partial_Correlation_noTin, sprintf('%s/RH_Partial_Correlation_noTin%d.pconn.nii', pconnDir, count_no), wbc);
end

%% Extract pconn data for ROIs for Tin vs noTin for use in netwebs
LH_Full_Correlation_Tin.pconn = LH_Full_Correlation_Tin.pconn(roiIndices, roiIndices);

LH_Partial_Correlation_Tin.pconn = LH_Partial_Correlation_Tin.pconn(roiIndices, roiIndices);

RH_Full_Correlation_Tin.pconn = RH_Full_Correlation_Tin.pconn(roiIndices, roiIndices);

RH_Partial_Correlation_Tin.pconn = RH_Partial_Correlation_Tin.pconn(roiIndices, roiIndices);

LH_Full_Correlation_noTin.pconn = LH_Full_Correlation_noTin.pconn(roiIndices, roiIndices);

LH_Partial_Correlation_noTin.pconn = LH_Partial_Correlation_noTin.pconn(roiIndices, roiIndices);

RH_Full_Correlation_noTin.pconn = RH_Full_Correlation_noTin.pconn(roiIndices, roiIndices);

RH_Partial_Correlation_noTin.pconn = RH_Partial_Correlation_noTin.pconn(roiIndices, roiIndices);
%% Reshape corr and uncorr (1 - p) values and extract values for ROIs

N=sqrt(size(LH_corr_F180, 2));
LH_corrMat_F180 = reshape(LH_corr_F180, N, N);
LH_corrMat_P180 = reshape(LH_corr_P180, N, N);
RH_corrMat_F180 = reshape(RH_corr_F180, N, N);
RH_corrMat_P180 = reshape(RH_corr_P180, N, N);

LH_corrMat_F180_ROIs_only = double(LH_corrMat_F180(roiIndices, roiIndices));
LH_corrMat_P180_ROIs_only = double(LH_corrMat_P180(roiIndices, roiIndices));
RH_corrMat_F180_ROIs_only = double(RH_corrMat_F180(roiIndices, roiIndices));
RH_corrMat_P180_ROIs_only = double(RH_corrMat_P180(roiIndices, roiIndices));

N=sqrt(size(LH_corr_F19, 2));
LH_corrMat_F19 = double(reshape(LH_corr_F19, N, N));
LH_corrMat_P19 = double(reshape(LH_corr_P19, N, N));
RH_corrMat_F19 = double(reshape(RH_corr_F19, N, N));
RH_corrMat_P19 = double(reshape(RH_corr_P19, N, N));

N=sqrt(size(LH_uncorr_F180, 2));
LH_uncorrMat_F180 = reshape(LH_uncorr_F180, N, N);
LH_uncorrMat_P180 = reshape(LH_uncorr_P180, N, N);
RH_uncorrMat_F180 = reshape(RH_uncorr_F180, N, N);
RH_uncorrMat_P180 = reshape(RH_uncorr_P180, N, N);

LH_uncorrMat_F180_ROIs_only = double(LH_uncorrMat_F180(roiIndices, roiIndices));
LH_uncorrMat_P180_ROIs_only = double(LH_uncorrMat_P180(roiIndices, roiIndices));
RH_uncorrMat_F180_ROIs_only = double(RH_uncorrMat_F180(roiIndices, roiIndices));
RH_uncorrMat_P180_ROIs_only = double(RH_uncorrMat_P180(roiIndices, roiIndices));

N=sqrt(size(LH_uncorr_F19, 2));
LH_uncorrMat_F19 = double(reshape(LH_uncorr_F19, N, N));
LH_uncorrMat_P19 = double(reshape(LH_uncorr_P19, N, N));
RH_uncorrMat_F19 = double(reshape(RH_uncorr_F19, N, N));
RH_uncorrMat_P19 = double(reshape(RH_uncorr_P19, N, N));

%% Reshape corr and uncorr (1 - p) values for coarser parcellations

N=sqrt(size(LH_corr_F_coarse, 2));
LH_corrMat_F_coarse = double(reshape(LH_corr_F_coarse, N, N));
LH_corrMat_P_coarse = double(reshape(LH_corr_P_coarse, N, N));
RH_corrMat_F_coarse = double(reshape(RH_corr_F_coarse, N, N));
RH_corrMat_P_coarse = double(reshape(RH_corr_P_coarse, N, N));

N=sqrt(size(LH_uncorr_F_coarse, 2));
LH_uncorrMat_F_coarse = double(reshape(LH_uncorr_F_coarse, N, N));
LH_uncorrMat_P_coarse = double(reshape(LH_uncorr_P_coarse, N, N));
RH_uncorrMat_F_coarse = double(reshape(RH_uncorr_F_coarse, N, N));
RH_uncorrMat_P_coarse = double(reshape(RH_uncorr_P_coarse, N, N));



%% Save pconn files and use FSLNets nets_netweb tool to visualise

netwebOutDir = sprintf('%s/netwebs', outDir);
cd(netwebOutDir)

addpath('/gpfs01/software/matlab_r2019b/toolbox/matlab/general/')

if ~isfolder(sprintf('netweb_LH_Tin%d', count_yes))
    nets_netweb(LH_Full_Correlation_Tin.pconn, ... % full correlation matrix
        LH_Partial_Correlation_Tin.pconn, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_Tin%d', count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_Tin%d', count_yes))
    nets_netweb(RH_Full_Correlation_Tin.pconn, ... % full correlation matrix
        RH_Partial_Correlation_Tin.pconn, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_Tin%d', count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_noTin%d', count_no))
    nets_netweb(LH_Full_Correlation_noTin.pconn, ... % full correlation matrix
        LH_Partial_Correlation_noTin.pconn, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_noTin%d', count_no), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_noTin%d', count_no))
    nets_netweb(RH_Full_Correlation_noTin.pconn, ... % full correlation matrix
        RH_Partial_Correlation_noTin.pconn, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_noTin%d', count_no), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_corrMat_180_ROIs_only_%dn%dy', count_no, count_yes))
    nets_netweb(LH_corrMat_F180_ROIs_only, ... % full correlation matrix
        LH_corrMat_P180_ROIs_only, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_corrMat_180_ROIs_only_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_corrMat_180_ROIs_only_%dn%dy', count_no, count_yes))
    nets_netweb(RH_corrMat_F180_ROIs_only, ... % full correlation matrix
        RH_corrMat_P180_ROIs_only, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_corrMat_180_ROIs_only_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_corrMat_19_%dn%dy', count_no, count_yes))
    nets_netweb(LH_corrMat_F19, ... % full correlation matrix
        LH_corrMat_P19, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_corrMat_19_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_corrMat_19_%dn%dy', count_no, count_yes))
    nets_netweb(RH_corrMat_F19, ... % full correlation matrix
        RH_corrMat_P19, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_corrMat_19_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_uncorrMat_180_ROIs_only_%dn%dy', count_no, count_yes))
    nets_netweb(LH_uncorrMat_F180_ROIs_only, ... % full correlation matrix
        LH_uncorrMat_P180_ROIs_only, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_uncorrMat_180_ROIs_only_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_uncorrMat_180_ROIs_only_%dn%dy', count_no, count_yes))
    nets_netweb(RH_uncorrMat_F180_ROIs_only, ... % full correlation matrix
        RH_uncorrMat_P180_ROIs_only, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_uncorrMat_180_ROIs_only_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_uncorrMat_19_%dn%dy', count_no, count_yes))
    nets_netweb(LH_uncorrMat_F19, ... % full correlation matrix
        LH_uncorrMat_P19, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_uncorrMat_19_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_RH_uncorrMat_19_%dn%dy', count_no, count_yes))
    nets_netweb(RH_uncorrMat_F19, ... % full correlation matrix
        RH_uncorrMat_P19, ... % partial correlation matrix
        roiIndices, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_uncorrMat_19_%dn%dy', count_no, count_yes), relevantROIs);
end

if ~isfolder(sprintf('netweb_LH_corrMat_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(LH_corrMat_F_coarse, ... % full correlation matrix
        LH_corrMat_P_coarse, ... % partial correlation matrix
        LH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_corrMat_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_RH_corrMat_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(RH_corrMat_F_coarse, ... % full correlation matrix
        RH_corrMat_P_coarse, ... % partial correlation matrix
        RH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_corrMat_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_LH_uncorrMat_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(LH_uncorrMat_F_coarse, ... % full correlation matrix
        LH_uncorrMat_P_coarse, ... % partial correlation matrix
        LH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_uncorrMat_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_RH_uncorrMat_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(RH_uncorrMat_F_coarse, ... % full correlation matrix
        RH_uncorrMat_P_coarse, ... % partial correlation matrix
        RH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_uncorrMat_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_LH_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(LH_ZnetF_coarse, ... % full correlation matrix
        LH_ZnetP_coarse, ... % partial correlation matrix
        LH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_RH_coarse_%dn%dy', count_no, count_yes))
    nets_netweb(RH_ZnetF_coarse, ... % full correlation matrix
        RH_ZnetP_coarse, ... % partial correlation matrix
        RH_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_coarse_%dn%dy', count_no, count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_LH_Tin_coarse_%dy', count_yes))
    nets_netweb(LH_ZnetF_Tin_coarse, ... % full correlation matrix
        LH_ZnetP_Tin_coarse, ... % partial correlation matrix
        LH_Tin_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_Tin_coarse_%dy', count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_LH_noTin_coarse_%dn', count_no))
    nets_netweb(LH_ZnetF_noTin_coarse, ... % full correlation matrix
        LH_ZnetP_noTin_coarse, ... % partial correlation matrix
        LH_noTin_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_LH_noTin_coarse_%dn', count_no), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_RH_Tin_coarse_%dy', count_yes))
    nets_netweb(RH_ZnetF_Tin_coarse, ... % full correlation matrix
        RH_ZnetP_Tin_coarse, ... % partial correlation matrix
        RH_Tin_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_Tin_coarse_%dy', count_yes), Coarse_Clusters);
end

if ~isfolder(sprintf('netweb_RH_noTin_coarse_%dn', count_no))
    nets_netweb(RH_ZnetF_noTin_coarse, ... % full correlation matrix
        RH_ZnetP_noTin_coarse, ... % partial correlation matrix
        RH_noTin_ts_coarse.DD, ... % ts.DD
        [], ... % group_maps
        sprintf('netweb_RH_noTin_coarse_%dn', count_no), Coarse_Clusters);
end



%% Save workspace variables

addpath('/gpfs01/software/matlab_r2019b/toolbox/matlab/general/')

matSavesDir = sprintf('%s/matSaves', outDir);
cd(matSavesDir)

save(sprintf('tseries_%dn%dy.mat', count_no, count_yes), 'LH_ts_orig', ...
    'LH_ts_180',  'LH_ts_19', 'LH_Tin_ts', 'LH_noTin_ts', 'LH_ts_coarse', ...
    'LH_Tin_ts_coarse', 'LH_noTin_ts_coarse', 'LH_ts_lda_ny_180', ...
    'LH_ts_lda_ny_19', ...
    'RH_ts_180',  'RH_ts_19', 'RH_Tin_ts', 'RH_noTin_ts', 'RH_ts_coarse', ...
    'RH_Tin_ts_coarse', 'RH_noTin_ts_coarse', 'RH_ts_lda_ny_180', ...
    'RH_ts_lda_ny_19', ...
    'count_yes', 'count_no', 'count_excluded', 'exclSubjIds', 'excludedIdxs');

save(sprintf('netmats_%dn%dy.mat', count_no, count_yes), ...
    'LH_netmatF_180', 'LH_netmatP_180', 'LH_netmatF_19', 'LH_netmatP_19', ...
    'LH_netmatF_Tin', 'LH_netmatF_noTin', 'LH_netmatP_Tin', ...
    'LH_netmatP_noTin', 'LH_netmatF_coarse', 'LH_netmatF_Tin_coarse', ...
    'LH_netmatF_noTin_coarse', 'LH_netmatP_coarse', 'LH_netmatP_Tin_coarse', ...
    'LH_netmatP_noTin_coarse', 'LH_netmatF_lda_ny_180', ...
    'LH_netmatF_lda_ny_19', 'LH_netmatP_lda_ny_180', ...
    'LH_netmatP_lda_ny_19', ...
    'RH_netmatF_180', 'RH_netmatP_180', 'RH_netmatF_19', 'RH_netmatP_19', ...
    'RH_netmatF_Tin', 'RH_netmatF_noTin', 'RH_netmatP_Tin', ...
    'RH_netmatP_noTin', 'RH_netmatF_coarse', 'RH_netmatF_Tin_coarse', ...
    'RH_netmatF_noTin_coarse', 'RH_netmatP_coarse', 'RH_netmatP_Tin_coarse', ...
    'RH_netmatP_noTin_coarse', 'RH_netmatF_lda_ny_180', ...
    'RH_netmatF_lda_ny_19', 'RH_netmatP_lda_ny_180', ...
    'RH_netmatP_lda_ny_19')

save(sprintf('comparisons_%dn%dy.mat', count_no, count_yes), ...
    'dummyL', 'dummyR','roiIndices', 'LH_corr_F180', 'LH_corr_P180', ...
    'LH_uncorr_F180', 'LH_uncorr_P180', 'LH_corr_F19', 'LH_corr_P19', ...
    'LH_uncorr_F19', 'LH_uncorr_P19', 'LH_corr_F_coarse', ... 
    'LH_uncorr_F_coarse', 'LH_uncorr_P_coarse', 'LH_corr_P_coarse', ...
    'RH_corr_F180', 'RH_corr_P180', 'RH_uncorr_F180', 'RH_uncorr_P180', ...
    'RH_corr_F19', 'RH_corr_P19', 'RH_uncorr_F19', 'RH_uncorr_P19', ...
    'RH_corr_F_coarse', 'RH_uncorr_F_coarse', 'RH_uncorr_P_coarse', ...
    'RH_corr_P_coarse')

save(sprintf('significantDifferences_%dn%dy.mat', count_no, count_yes), ...
    'LH_corrMat_F180', 'LH_corrMat_F180_ROIs_only', 'LH_corrMat_F19', ...
    'LH_corrMat_P180', 'LH_corrMat_P180_ROIs_only', 'LH_corrMat_P19', ...
    'RH_corrMat_F180', 'RH_corrMat_F180_ROIs_only', 'RH_corrMat_F19', ...
    'RH_corrMat_P180', 'RH_corrMat_P180_ROIs_only', 'RH_corrMat_P19', ...
    'LH_uncorrMat_F180', 'LH_uncorrMat_F180_ROIs_only', 'LH_uncorrMat_F19', ...
    'LH_uncorrMat_P180', 'LH_uncorrMat_P180_ROIs_only', 'LH_uncorrMat_P19', ...
    'RH_uncorrMat_F180', 'RH_uncorrMat_F180_ROIs_only', 'RH_uncorrMat_F19', ...
    'RH_uncorrMat_P180', 'RH_uncorrMat_P180_ROIs_only', 'RH_uncorrMat_P19', ...
    'LH_corrMat_F_coarse', 'LH_corrMat_P_coarse', ...
    'RH_corrMat_F_coarse', 'RH_corrMat_P_coarse', ...
    'LH_uncorrMat_F_coarse', 'LH_uncorrMat_P_coarse', ...
    'RH_uncorrMat_F_coarse', 'RH_uncorrMat_P_coarse')

%% nets_lda, see if there is statistical difference in connectivity across whole Tin, noTin brain

addpath('/gpfs01/software/imaging/FSLNets')
addpath(genpath('/gpfs01/software/imaging/fsl/6.0.1/'))

[LH_F_lda_ny_180_2] = nets_lda(LH_netmatF_lda_ny_180, count_no, 2);
[LH_P_lda_ny_180_2] = nets_lda(LH_netmatP_lda_ny_180, count_no, 2);
[RH_F_lda_ny_180_2] = nets_lda(RH_netmatF_lda_ny_180, count_no, 2);
[RH_P_lda_ny_180_2] = nets_lda(RH_netmatP_lda_ny_180, count_no, 2);

[LH_F_lda_ny_19_2] = nets_lda(LH_netmatF_lda_ny_19, count_no, 2);
[LH_P_lda_ny_19_2] = nets_lda(LH_netmatP_lda_ny_19, count_no, 2);
[RH_F_lda_ny_19_2] = nets_lda(RH_netmatF_lda_ny_19, count_no, 2);
[RH_P_lda_ny_19_2] = nets_lda(RH_netmatP_lda_ny_19, count_no, 2);

addpath(sprintf('%s/toolbox/libsvm-3.24/matlab', fCA_path))

[LH_F_lda_ny_180_8] = nets_lda(LH_netmatF_lda_ny_180, count_no, 8);
[LH_P_lda_ny_180_8] = nets_lda(LH_netmatP_lda_ny_180, count_no, 8);
[RH_F_lda_ny_180_8] = nets_lda(RH_netmatF_lda_ny_180, count_no, 8);
[RH_P_lda_ny_180_8] = nets_lda(RH_netmatP_lda_ny_180, count_no, 8);

[LH_F_lda_ny_19_8] = nets_lda(LH_netmatF_lda_ny_19, count_no, 8);
[LH_P_lda_ny_19_8] = nets_lda(LH_netmatP_lda_ny_19, count_no, 8);
[RH_F_lda_ny_19_8] = nets_lda(RH_netmatF_lda_ny_19, count_no, 8);
[RH_P_lda_ny_19_8] = nets_lda(RH_netmatP_lda_ny_19, count_no, 8);

addpath('/gpfs01/software/matlab_r2019b/toolbox/matlab/general/')

matSavesDir = sprintf('%s/matSaves', outDir);
cd(matSavesDir)

save(sprintf('ldaFiles_%dn%dy.mat', count_no, count_yes), ...
    'LH_F_lda_ny_180_2', 'LH_P_lda_ny_180_2', 'RH_F_lda_ny_180_2', ...
    'RH_P_lda_ny_180_2', 'LH_F_lda_ny_19_2', 'LH_P_lda_ny_19_2', ...
    'RH_F_lda_ny_19_2', 'RH_P_lda_ny_19_2', 'LH_F_lda_ny_180_8', ...
    'LH_P_lda_ny_180_8', 'RH_F_lda_ny_180_8', 'RH_P_lda_ny_180_8', ...
    'LH_F_lda_ny_19_8', 'LH_P_lda_ny_19_8', 'RH_F_lda_ny_19_8', ...
    'RH_P_lda_ny_19_8')

save(sprintf('FSLNetsAnalysis_%dn%dy.mat', count_no, count_yes))