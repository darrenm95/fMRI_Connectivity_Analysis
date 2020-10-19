clear all 
close all
clc

%% Setup

% add path to FSLNets
addpath('/gpfs01/software/imaging/FSLNets')
addpath(genpath('/gpfs01/software/imaging/fsl/6.0.2/'))

% addpath to fMRI_Connectivity_Analysis folder that cotains toolbox
% aswell as the Matlab scripts and the edited netjs package.

% toolbox contains both ciftisave and ft_read_cifti
% MatlabScripts contains the editied nets_netweb script
% netjs has been edited to display node labels

% use system to enter unix command to find the path to the folder that
% contains the required scripts, files and data on the users system.
[status,fCA_path] = system(sprintf("find /gpfs01/share/HearingMRI -type d -name 'fMRI_Connectivity_Analysis'"));
fCA_path = fCA_path(1:end-1); 
addpath(genpath(fCA_path)); % genpath adds path of files in folders 
clear status

% set script output directory
outDir = sprintf('%s/ConnecAnalysis_Out', fCA_path);

matSavesDir = sprintf('%s/matSaves', outDir);

load(sprintf('%s/tseries_526n90y.mat', matSavesDir));
load(sprintf('%s/netmats_526n90y', matSavesDir));
load(sprintf('%s/comparisons_526n90y', matSavesDir));

desFile = sprintf('%s/tinGLM_data/design.mat', fCA_path);
conFile = sprintf('%s/tinGLM_data/unpaired_ttest_1con.con', fCA_path);

[LH_uncorr_F180,LH_corr_F180]=nets_glm(LH_netmatF_180, desFile, conFile,1);
[LH_uncorr_P180,LH_corr_P180]=nets_glm(LH_netmatP_180, desFile, conFile,1);
[RH_uncorr_F180,RH_corr_F180]=nets_glm(RH_netmatF_180, desFile, conFile,1);
[RH_uncorr_P180,RH_corr_P180]=nets_glm(RH_netmatP_180, desFile, conFile,1);

[LH_uncorr_F19,LH_corr_F19]=nets_glm(LH_netmatF_19, desFile, conFile,1);
[LH_uncorr_P19,LH_corr_P19]=nets_glm(LH_netmatP_19, desFile, conFile,1);
[RH_uncorr_F19,RH_corr_F19]=nets_glm(RH_netmatF_19, desFile, conFile,1);
[RH_uncorr_P19,RH_corr_P19]=nets_glm(RH_netmatP_19, desFile, conFile,1);



cd(matSavesDir)
addpath('/gpfs01/software/matlab_r2019b/toolbox/matlab/general')

save(sprintf('comparisons_%dn%dy.mat', count_no, count_yes), ...
    'dummy', 'roiIndices', 'LH_corr_F180', 'RH_corr_F180', ...
    'LH_corr_P180', 'RH_corr_P180', 'LH_uncorr_F180', 'RH_uncorr_F180', ...
    'LH_uncorr_P180', 'RH_uncorr_P180', 'LH_corr_F19', 'RH_corr_F19', ...
    'LH_corr_P19', 'RH_corr_P19', 'LH_uncorr_F19', 'RH_uncorr_F19', ...
    'LH_uncorr_P19', 'RH_uncorr_P19')
