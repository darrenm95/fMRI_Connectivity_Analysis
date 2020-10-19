#!/bin/bash
#
# # SetupFile.sh
#
#
# ## Description
#
# Setup script to set data paths, output paths, numbers of subjects to process
# and which processes are to be ran.
#
# ------------------------------------------------------------------------------------
# USER DEFINED
# ------------------------------------------------------------------------------------

# Number of yes and no subjects to be processed.
export y=3; export n=0;

# User defined paths
export SF='/gpfs01/share/HearingMRI/UKB_data_processed_HCP_style'
export SD='/gpfs01/share/ukbiobank/Release_1'
export fCA='/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis'

# Label file names
L_dlabel='Q1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.32k_fs_LR.dlabel.nii'
R_dlabel='Q1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.32k_fs_LR.dlabel.nii'

# ------------------------------------------------------------------------------------
# FILE RELATIVE PATH EXTENSIONS
# ------------------------------------------------------------------------------------

# Relative paths from subject specific source directory to T1, T2, fMRI and SBREF data
export T1='T1/T1.nii.gz'
export T2='T2_FLAIR/T2_FLAIR.nii.gz'
export fMRI='fMRI/rfMRI.nii.gz'
export SBREF='fMRI/rfMRI_SBREF.nii.gz'

# Relative path from subject specific study folder to dtseries data
export DTS='MNINonLinear/Results/rfMRI/rfMRI_Atlas.dtseries.nii'
export DTS_clean='MNINonLinear/Results/rfMRI/rfMRI_Atlas_hp100_clean.dtseries.nii'

# ------------------------------------------------------------------------------------
# PROCESS ON/OFF SWITCHES
# ------------------------------------------------------------------------------------

export setHCPStyle_Pipeline=1
export setSubListConstructor=0 # Nested under setHCPStyle_Pipeline above
export setCopySubData=0        # Nested under setHCPStyle_Pipeline above
 
export setHCPPipelines=1       # Nested under setHCPStyle_Pipeline above
export setStruc_and_Func=1     # Nested under setHCPPipelines and setHCPStyle_Pipeline above 
export setICAFIX=1             # Nested under setHCPPipelines and setHCPStyle_Pipeline above

export setFNA_Pipeline=1       
export setPreFSLNetsAnalysis=1  # Nested under setFNA_Pipeline above
export setFSLNetsAnalysis=0     # Nested under setFNA_Pipeline above

# ------------------------------------------------------------------------------------
# DIRECTORY PATH VARIABLES
# ------------------------------------------------------------------------------------

export BS=$(find $fCA -type d -name 'BashScripts')
export MS=$(find $fCA -type d -name 'MatlabScripts')
       SIds=$(find $fCA -type d -name 'subjectIds')
export pt=$(find $fCA -type d -name 'ptseries')
export Tpt=$(find $fCA -type d -name 'transposed_ptseries')
export C2TXTpt=$(find $fCA -type d -name 'converted_to_text_ptseries')

# ------------------------------------------------------------------------------------
# FILE PATH VARIABLES
# ------------------------------------------------------------------------------------

export LLAB=$(find $fCA -type f -name $L_dlabel)
export RLAB=$(find $fCA -type f -name $R_dlabel)
export toBeP=$(find $fCA -type f -name 'toBeProcessed.txt')
export last=$(find $fCA -type f -name 'lastRun.txt')
export y11=$(find $fCA -type f -name 'y11_all.txt')
export n0=$(find $fCA -type f -name 'n0.txt')
export des=$(find $fCA -type f -name 'design.txt')
export desMat=$(find $fCA -type f -name 'design.mat')
export excluded=$(find $fCA -type f -name 'excluded.txt')
export count=$(find $fCA -type f -name 'count.txt')
export inputCSV=$(find $fCA -type f -name 'tin_data.csv')
export PreFSjs=$(find $fCA -type f -name 'PreFSjids_sids.txt')
export PostFSjs=$(find $fCA -type f -name 'PostFSjids_sids.txt')
export FSjs=$(find $fCA -type f -name 'FSjids_sids.txt')
export fMRIVjs=$(find $fCA -type f -name 'fMRIVjids_sids.txt')
export fMRISjs=$(find $fCA -type f -name 'fMRISjids_sids.txt')
export ICAjs=$(find $fCA -type f -name 'ICAjids_sids.txt')
export failed=$(find $fCA -type f -name 'failedSubjects.txt')

