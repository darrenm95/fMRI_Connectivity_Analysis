addpath('/gpfs01/software/imaging/FSLNets')
addpath(genpath('/gpfs01/software/imaging/fsl/6.0.1/'))
load('/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/FSLNetsAnalysis_Out/svmNetmats.mat')
addpath('/gpfs01/home/msadm19/libsvm-3.24/matlab')
[LH_F_lda_ny_180_8] = nets_lda(LH_netmatF_lda_ny_180, count_no, 8)
[LH_P_lda_ny_180_8] = nets_lda(LH_netmatP_lda_ny_180, count_no, 8)
[RH_F_lda_ny_180_8] = nets_lda(RH_netmatF_lda_ny_180, count_no, 8)
[RH_P_lda_ny_180_8] = nets_lda(RH_netmatP_lda_ny_180, count_no, 8)

[LH_F_lda_ny_19_8] = nets_lda(LH_netmatF_lda_ny_19, count_no, 8)
[LH_P_lda_ny_19_8] = nets_lda(LH_netmatP_lda_ny_19, count_no, 8)
[RH_F_lda_ny_19_8] = nets_lda(RH_netmatF_lda_ny_19, count_no, 8)
[RH_P_lda_ny_19_8] = nets_lda(RH_netmatP_lda_ny_19, count_no, 8)

addpath('/gpfs01/software/matlab_r2019b/toolbox/matlab/general/')
save('/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/FSLNetsAnalysis_Out/ldalibsvm.mat')