#!/bin/bash 
#
# # HCPPipelines_to_FSLNetsAnalysis.sh
#
# # HCP PIPELINES TO FSLNets ANALYSIS PIPELINE
#
# ## Description
#
# Processes subjects imaging data HCP style using the HCP Structural, Functional
# and ICAFIX pipelines. Subjects parcellated time series is then extracted and
# manipulated to the right format for FSLNets to be used to estimate connectivity
# between different brain regions of interest.
#
# Primary functions of the HCP Pipelines to FSLNets Analysis Pipeline are:
# 1. Construct a list of subjects for processing that have required data files
# 2. Copy required data files from subject specific source directory to study
#    folder directory for each of these subjects
# 3. Process subjects HCP style using Structural, Functional and ICAFIX pipelines
# 4. Extract parcellated time series for each subject before transposing and
#    converting to text ready to be used by FSLNets
# 5. Estimate parcel to parcel connectivity for regions of interest using FSLNets
#
# ## Prerequisites:
#
# ### Installed Software
#
# * [FSL][FSL] - FMRIB's Software Library (versions 5.0.11, 6.0.1)
#
# * [FREESURFER] - (version 5.3.0)
#
# * [WORKBENCH] - Human Connectome Projects wb_command (version 1.3.2)
#
# * [MATLAB] - (version r2018b, r2019b)
#
# * [FSLNETS] - MATLAB scripts for carrying out network modelling
#
# * [Washington-University/cifti-matlab - GitHub Repository] - MATLAB code for
#   reading and writing CIFTI connectivity files (includes ft_read_cifti)
#
#
# * [Washington-University/HCPpipelines/global/matlab/ - GitHub Repository] -
#   MATLAB code for reading and writing CIFTI and GIFTI connectivity files
#   (includes ciftiopen and ciftisave)
#
# * [netjs] - netjs is used by the FSLNets nets_netweb function to generate an
#             interactive web page for browsing the results of a FSLNets analysis
#             (using modified version under HearingMRI/fMRI_Connectivity_Analysis)
#
# * [nets_netweb] - script for generating interactive web page for browsing the
#                   results of a FSLNets analysis (using modified version under
#                   HearingMRI/fMRI_Connectivity_Analysis/MatlabScripts
#
# ### Required Environment Variables (see SetupFile.sh)
#
# * y
#
#   Number of subjects in yes tinnitus category that are to be processed
#
# * n
#
#   Number of subjects in no tinnitus category that are to be processed
#
# * SF
#
#   Absolute path to the Study Folder directory which contains subject data
#
# * SD
#
#   Absolute path to the Source Directory which contains subject data
#
# * T1
#
#   Relative path from subject specific Source Directory to T1 data
#
# * T2
#
#   Relative path from subject specific Source Directory to T2 data
#
# * fMRI
#
#   Relative path from subject specific Source Directory to rfMRI data
#
# * SBREF
#
#   Relative path from subject specific Source Directory to SBREF data
#
# * DTS
#
#   Relative path from Study Folder directory to subject specific dense time series
#
# * DTS_clean
#
#   Relative path from Study Folder directory to subject specific dense time series
#   has had ICAFIX applied
#
# * pt
#
#   Absolute path to directory containing subjects extracted parcellated time series
#
# * Tpt
#
#   Absolute path to directory containing subjects transposed extracted parcellated time series
#
# * C2TXTpt
#
#   Absolute path to directory containing subjects transposed extracted parcellated
#   time series after being converted to a txt file.
#
# * LLAB
#
#   Aboslute path to left hemisphere dense label file (Glasser 2016)
#
# * RLAB
#
#   Absolute path to right hemisphere dense label file (Glasser 2016)
#
# * des
#
#   Absolute path to design matrix txt file
#
# * desMat
#
#   Absolute path to design matrix matlab .mat file (Created using FSL's Text2Vest)
#
# * count
#
#   Absolute path to count.txt text file containing counts of the subjects in the
#   various categories
#
# * excluded
#
#   Absolute path to excluded.txt text file containing subject id and alphanumeric
#   index of subject to be excluded from the analysis
#
# * inputCSV
#
#   Absolute path to copy of BioBank tinnitus csv data file
#
# * y11
#
#   Absolute path to y11_all.txt text file containing list of subject id's whose response
#   was 'yes, all or most of the time' and possess a data code of 11 that are still
#   to be processed
#
# * n0
#
#   Absolute path to n0.txt text file containing list of subject id's whose response
#   was 'no, never' and possess a data code of 0 that are still to be processed
#
# * HCPPIPEDIR
#
#   The "home" directory for the version of the HCP Pipeline Tools product
#   being used. E.g. /nrgpackages/tools.release/hcp-pipeline-tools-V3.0
#
# * HCPPIPEDIR_Global
#
#   Location of shared sub-scripts that are used to carry out some of the
#   steps of the PreFreeSurfer pipeline and are also used to carry out
#   some steps of other pipelines.
#
# * FSLDIR
#
#   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
#   University
#
# #### TO DO #### Add reference to module files instead of HCP pipeline 
#                 environment variable
#
# ### Image Files
#
# T1.nii.gz, T2_FLAIR.nii.gz, rfMRI.nii.gz and rfMRI_SBREF.nii.gz
#
# ### Output Directories
#
# * UKB_data_processed_HCP_style             # Study Folder
#
# * Pre_FSLNetsAnalysis_Out                  # Pre_FSLNetsAnalysis_Pipeline.sh
#       * ptseries                             output
#       * transposed_ptseries
#       * converted_to_text_ptseries
#
# * FSLNetsAnalysis_Out                      # MATLAB FSLNetsAnalysis.m result
#       * FP_Correlation                       files and folders
#       * figures
#       * matSaves
#       * netwebs
#
# * comparisonFiles                          # Output for files needed to run
#                                              cross-subject comparisons in
#                                              FSLNetsAnalysis.m
#
# ### Output Files
#
# #### Pre_FSLNetsAnalysis_Pipeline Output Files:
#
# * L.*******.ptseries.nii                   # Left hemisphere extracted
#                                              parcellated time series
#
# * R.*******.ptseries.nii                   # Right hemisphere extracted
#                                              parcellated time series
#
# * L.*******.T_ptseries.nii                 # Left hemisphere transposed
#                                              extracted parcellated time series
#
# * R.*******.T_ptseries.nii                 # Right hemisphere transposed
#                                              extracted parcellated time series
#
# * L.*******.ptseries.txt                   # Left hemisphere converted to text
#                                              transposed parcellated time series
#
# * R.*******.ptseries.txt                   # Right hemisphere converted to text
#                                              transposed parcellated time series
#
# * design.txt                               # design matrix text file for cross
#                                              subject comparisons
#
# * count.txt                                # File containing information
#                                              regarding the number of subjects
#                                              in the categores yes, no and
#                                              excluded
#
# * excluded.txt                             # Subjects to be excluded from the
#                                              analysis and their alphanumeric
#                                              index
#
# * design.mat                               # design matrix matlab file
#                                              (created using FSLNets Text2Vest
#                                               tool)
#
# #### FSLNetsAnalysis.m Output Files:
#
# * LH_Full_Correlation_Tin%d.pconn.nii      # Tinnitus group left hemisphere
#                                              full correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              tinnitus group at time of
#                                              processing)
#
# * LH_Partial_Correlation_Tin%d.pconn.nii   # Tinnitus group left hemisphere
#                                              partial correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              tinnitus group at time of
#                                              processing)
#
# * RH_Full_Correlation_Tin%d.pconn.nii      # Tinnitus group right hemisphere
#                                              full correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              tinnitus group at time of
#                                              processing)
#
# * RH_Partial_Correlation_Tin%d.pconn.nii   # Tinnitus group right hemisphere
#                                              partial correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              tinnitus group at time of
#                                              processing)
#
# * LH_Full_Correlation_noTin%d.pconn.nii    # Non-tinnitus group left hemisphere
#                                              full correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              non-tinnitus group at time of
#                                              processing)
#
# * LH_Partial_Correlation_noTin%d.pconn.nii # Non-tinnitus group left hemisphere
#                                              partial correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              non-tinnitus group at time of
#                                              processing)
#
# * RH_Full_Correlation_noTin%d.pconn.nii    # Non-tinnitus group right hemisphere
#                                              full correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              non-tinnitus group at time of
#                                              processing)
#
# * RH_Partial_Correlation_noTin%d.pconn.nii # Non-tinnitus group right hemisphere
#                                              partial correlation parcellated
#                                              connectivity CIFTI file
#                                              (%d = number of subjects in
#                                              non-tinnitus group at time of
#                                              processing)
#
# * netweb_LH_Tin%d                          # Directory containing files to generate
#                                              an interactive web page for viewing
#                                              tinnitus group left hemisphere
#                                              FSLNets analysis results
#
# * netweb_RH_Tin%d                          # Directory containing files to generate
#                                              an interactive web page for viewing
#                                              tinnitus group right hemisphere
#                                              FSLNets analysis results
#
# * netweb_LH_noTin%d                        # Directory containing files to generate
#                                              an interactive web page for viewing
#                                              non-tinnitus group left hemisphere
#                                              FSLNets analysis results
#
# * netweb_RH_noTin%d                        # Directory containing files to generate
#                                              an interactive web page for viewing
#                                              non-tinnitus group right hemisphere
#                                              FSLNets analysis results
#
# * tseries_%dn%dy.mat                       # Workspace variables saved during
#                                              FSLNetsAnalysis.m needed to reproduce
#                                              all time series variables (%dn, %d = number of
#                                              non-tinnitus subjects, %dy, %d = number of
#                                              tinnitus subjects)
#
# * netmats_%dn%dy.mat                       # Workspace variables saved during
#                                              FSLNetsAnalysis.m needed to reproduce
#                                              all netmats variables (%dn, %d = number of
#                                              non-tinnitus subjects, %dy, %d = number of
#                                              tinnitus subjects)
#
# * comparisons_%dn%dy.mat                   # Workspace variables saved during
#                                              FSLNetsAnalysis.m needed to reproduce
#                                              all cross-subject comparisons (%dn,
#                                              %d = number of non-tinnitus subjects,
#                                              %dy, %d = number of tinnitus subjects)
#
# #### TODO #### Update output files for FSLNetsAnalysis_out
#
# ------------------------------------------------------------------------------------
# CODE START
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------
# SBATCH SETTINGS
# ------------------------------------------------------------------------------------

#SBATCH --mail-type=END 			# Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=ian.wiggins@nottingham.ac.uk
#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=5g
#SBATCH --time=60:00:00

# ------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------

failedJobCheck() {

tmpStr=$SubIdStr

count_failed_PreFS=0
count_failed_FS=0
count_failed_PostFS=0
count_failed_fMRI=0
count_failed_ICA=0


while IFS=$' \t\n' read -r jobID partition jobName user jobState time numNodes reason; do

    if [[ "$jobState" != "R" ]] && ! { [[ "$jobState" == "PD" ]] &&
     { [[ "$reason" == "(Priority)" ]] || [[ "$reason" == "(Resources)" ]] ||
       [[ "$reason" == "(Dependency)" ]] || [[ "$reason" == "(DependencyNeverSatisfied)" ]]; }; }; then

      if [[ "$jobName" == "PreFreeS" ]] && grep -q $jobID $PreFSjs; then

          count_failed_PreFS=$[$count_failed_PreFS +1]
          jid=${jobID}
          sid=$(grep "$jid" "$PreFSjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          PreFS_rerunStr+="$sid "

      fi

      if [[ "$jobName" == "FreeSurf" ]] && grep -q $jobID $FSjs; then

          count_failed_FS=$[$count_failed_FS +1]
          jid=${jobID}
          sid=$(grep "$jid" "$FSjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          FS_rerunStr+="$sid "

      fi

      if [[ "$jobName" == "PostFree" ]] && grep -q $jobID $PostFSjs; then

          count_failed_PostFS=$[$count_failed_PostFS +1]
          jid=${jobID}
          sid=$(grep "$jid" "$PostFSjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          PostFS_rerunStr+="$sid "

      fi

      if [[ "$jobName" == "Genericf" ]] &&  grep -q $jobID $fMRIVjs; then

          count_failed_fMRIV=$[$count_failed_fMRIV +1]
          jid=${jobID}
          sid=$(grep "$jid" "$fMRIVjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          fMRIV_rerunStr+="$sid "

      fi

      if [[ "$jobName" == "Genericf" ]] &&  grep -q $jobID $fMRISjs; then

          count_failed_fMRIS=$[$count_failed_fMRIS +1]
          jid=${jobID}
          sid=$(grep "$jid" "$fMRISjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          fMRIS_rerunStr+="$sid "

      fi

      if [[ "$jobName" == "hcp_fix" ]] && grep -q $jobID $ICAjs; then

          count_failed_ICA=$[$count_failed_ICA +1]
          jid=${jobID}
          sid=$(grep "$jid" "$ICAjs" | grep -oE "1[0-9]{6}")
          echo "$jid : $sid : $jobName"
          ICA_rerunStr+="$sid "

      fi
    fi

done < <(squeue -u $LOGNAME)


if [[ ! -z "$PreFS_rerunStr" ]]; then

  for sid in ${PreFS_rerunStr}; do

      PreFSjid=$(grep "$sid" "$PreFSjs" | grep -oE "^[0-9]{7}")
      FSjid=$(grep "$sid" "$FSjs" | grep -oE "^[0-9]{7}")
      PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $PreFSjid $FSjid $PostFSjid $fMRIVjid $fMRISjid $ICAjid

      sed "/^$PreFSjid/d" -i $PreFSjs
      sed "/^$FSjid/d" -i $FSjs
      sed "/^$PostFSjid/d" -i $PostFSjs
      sed "/^$fMRIVjid/d" -i $fMRIVjs
      sed "/^$fMRISjid/d" -i $fMRISjs
      sed "/^$ICAjid/d" -i $ICAjs

  done

  ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh
  jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
  export jobidfMRISurfaceStr

  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_PreFS : PreFreeSurfer jobs failed to run and were resubmitted"
  unset PreFS_rerunStr

fi

if [[ ! -z "$FS_rerunStr" ]]; then

  for sid in ${FS_rerunStr}; do

      FSjid=$(grep "$sid" "$FSjs" | grep -oE "^[0-9]{7}")
      PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $FSjid $PostFSjid $fMRIVjid $fMRISjid $ICAjid

      sed "/^$FSjid/d" -i $FSjs
      sed "/^$PostFSjid/d" -i $PostFSjs
      sed "/^$fMRIVjid/d" -i $fMRIVjs
      sed "/^$fMRISjid/d" -i $fMRISjs
      sed "/^$ICAjid/d" -i $ICAjs

  done

  SubIdStr=${FS_rerunStr}
  ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh --startat=freesurfer
  jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
  export jobidfMRISurfaceStr

  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_FS : FreeSurfer jobs failed to run and were resubmitted"
  unset FS_rerunStr

fi

if [[ ! -z "$PostFS_rerunStr" ]]; then

  for sid in ${PostFS_rerunStr}; do

      PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $PostFSjid $fMRIVjid $fMRISjid $ICAjid

      sed "/^$PostFSjid/d" -i $PostFSjs
      sed "/^$fMRIVjid/d" -i $fMRIVjs
      sed "/^$fMRISjid/d" -i $fMRISjs
      sed "/^$ICAjid/d" -i $ICAjs

  done

  SubIdStr=${PostFS_rerunStr}
  ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh --startat=postfreesurfer
  jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
  export jobidfMRISurfaceStr

  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_PostFS : PostFreeSurfer jobs failed to run and were resubmitted"
  unset PostFS_rerunStr

fi

if [[ ! -z "$fMRIV_rerunStr" ]]; then

  for sid in ${fMRIV_rerunStr}; do

      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $fMRIVjid $fMRISjid $ICAjid

      sed "/^$fMRIVjid/d" -i $fMRIVjs
      sed "/^$fMRISjid/d" -i $fMRISjs
      sed "/^$ICAjid/d" -i $ICAjs

  done

  ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh --startat=fMRIVolume
  jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
  export jobidfMRISurfaceStr

  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_fMRIV : fMRIVolume jobs failed to run and were resubmitted"
  unset fMRIV_rerunStr

fi

if [[ ! -z "$fMRIS_rerunStr" ]]; then

  for sid in ${fMRIS_rerunStr}; do

      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $fMRISjid $ICAjid

      sed "/^$fMRISjid/d" -i $fMRISjs
      sed "/^$ICAjid/d" -i $ICAjs

  done

  ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh --startat=fMRISurface
  jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
  export jobidfMRISurfaceStr

  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_fMRIS : fMRIVolume jobs failed to run and were resubmitted"
  unset fMRIS_rerunStr

fi

if [[ ! -z "$ICA_rerunStr" ]]; then

  for sid in ${ICA_rerunStr}; do

      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      scancel $ICAjid

      sed "/^$ICAjid/d" -i $ICAjs

  done


  ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
  jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)

  echo -e "$count_failed_ICA : ICAFIX jobs failed to run and were resubmitted"
  unset fMRI_rerunStr

fi

while IFS=$' \t\n' read -r jobID partition jobName user jobState time numNodes reason; do

    if [[ "$reason" == "(DependencyNeverSatisfied)" ]]; then

      if [[ "$jobName" == "FreeSurf" ]] && grep -q $jobID $FSjs; then

          jid=${jobID}
          sid=$(grep "$jid" "$FSjs" | grep -oE "1[0-9]{6}")

          PreFSjid=$(grep "$sid" "$PreFSjs" | grep -oE "^[0-9]{7}")
          FSjid=${jid}
          PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
          fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
          fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
          ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")
          
          echo "$PreFSjid : $sid : PreFreeSurfer" >> $failed
          scancel $FSjid $PostFSjid $fMRIVjid $fMRISjid $ICAjid

      fi

      if [[ "$jobName" == "PostFree" ]] && grep -q $jobID $PostFSjs; then

          jid=${jobID}
          sid=$(grep "$jid" "$PostFSjs" | grep -oE "1[0-9]{6}")

          FSjid=$(grep "$sid" "$FSjs" | grep -oE "^[0-9]{7}")
          PostFSjid=${jid}
          fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
          fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
          ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

          echo "$FSjid : $sid : FreeSurfer" >> $failed
          scancel $PostFSjid $fMRIVjid $fMRISjid $ICAjid

      fi

      if [[ "$jobName" == "Genericf" ]] &&  grep -q $jobID $fMRIVjs; then

          jid=${jobID}
          sid=$(grep "$jid" "$fMRIVjs" | grep -oE "1[0-9]{6}")

          PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
          fMRIVjid=${jid}
          fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
          ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

          echo "$PostFSjid : $sid : PostFreeSurfer" >> $failed
          scancel $fMRIVjid $fMRISjid $ICAjid

      fi

      if [[ "$jobName" == "Genericf" ]] && grep -q $jobID $fMRISjs; then

          jid=${jobID}
          sid=$(grep "$jid" "$fMRISjs" | grep -oE "1[0-9]{6}")

          fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
          fMRISjid=${jid}
          ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

          echo "$fMRIVjid : $sid : GenericfMRIVolume" >> $failed
          scancel  $fMRISjid $ICAjid

      fi

      if [[ "$jobName" == "hcp_fix" ]] && grep -q $jobID $ICAjs; then

          jid=${jobID}
          sid=$(grep "$jid" "$ICAjs" | grep -oE "1[0-9]{6}")
          
          fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
          ICAjid=${jid}

          echo "$fMRISjid : $sid : GenericfMRISurface" >> $failed
          scancel   $ICAjid

      fi
    fi
done < <(squeue -u $LOGNAME)


SubIdStr=$tmpStr

while IFS=$' \t\n' read -r jobID partition jobName user jobState time numNodes reason; do

    if { [[ "$jobName" == "PreFreeS" ]] ||
         [[ "$jobName" == "FreeSurf" ]] || [[ "$jobName" == "PostFree" ]] ||
         [[ "$jobName" == "Genericf" ]] || [[ "$jobName" == "hcp_fix" ]]; } &&
     { { [[ "$jobState" == "PD" ]] && [[ "$reason" == "(Dependency)" ]]; } || 
         [[ "$jobState" == "R" ]]; }; then

      sleep 1h
      failedJobCheck
    else
     
      return

    fi

done < <(squeue -u $LOGNAME)

}

# ------------------------------------------------------------------------------------
# SETUP
# ------------------------------------------------------------------------------------

# Set MODULEPATH environment variable to path to modulefiles on HPC
export MODULEPATH=/gpfs01/software/imaging/modulefiles:$MODULEPATH
BS=/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/BashScripts
source ${BS}/SetupFile.sh

parentScript_name=$(basename "${0}")

# Redirect script input and output to files
exec > "${fCA}/log_files/${parentScript_name}.o$(date +%d-%m-%Y_%R)"
exec 2>"${fCA}/log_files/${parentScript_name}.e$(date +%d-%m-%Y_%R)"

echo -e "Starting ${parentScript_name}\n"
echo $LOGNAME

# ------------------------------------------------------------------------------------
# HCP STYLE PIPELINE
#
# Processes:
# Subject List Constuctor, Copy Subject Data, Structural Pipeline,
# Functional Pipeline, ICAFIX Pipeline
#
# Scripts:
# SubListConstructor.sh, CopySubData.sh,  Struc_and_fMRI_Pipeline.sh,
# ICAFixProcessingBatch.sh
#
# ------------------------------------------------------------------------------------

if [[ $setHCPStyle_Pipeline == 1 ]]; then

  echo -e "HCPStyle Pipeline switch on, beginning steps to process subjects" \
          "HCP Style\n"

# ------------------------------------------------------------------------------------
# SUBJECT LIST CONSTRUCTOR SubListConstructor.sh
# ------------------------------------------------------------------------------------

  if [[ $setSubListConstructor == 1 ]]; then

    echo -e "Subject List Constructor switch on, making space separated string" \
            "of subject id's to be processed\n"
    source ${BS}/SubListConstructor.sh

  elif [[ $setSubListConstructor == 0 ]]; then

    echo -e "Subject List Constructor switch off, building space separated" \
            "string from list of id\'s previously saved to toBeProcessed.txt\n"

    for SUBJECT_ID in $(grep -E "^[0-9]{7}$" $toBeP); do

      SubIdStr+="$SUBJECT_ID "

    done

    echo -e "Subject Ids to be processed: $SubIdStr\n"

  else

    echo -e "Incorrect value passed to STRING MAKER switch, set to either 1 or 0\n"

  fi

  storeIdStr=${SubIdStr}
# ------------------------------------------------------------------------------------
# COPY SUBJECT DATA CopySubData.sh
# ------------------------------------------------------------------------------------

  if [[ $setCopySubData == 1 ]]; then

    echo -e "Copy Subject Data switch on, beginning process\n"
    echo -e "Copying subject T1, T2, fMRI and SBREF data from source directory" \
            "to subject specific study folder\n"
    source ${BS}/CopySubData.sh

  fi

# ------------------------------------------------------------------------------------
# HCP PIPELINES
#
# Processes:
# Structural Pipeline, Functional Pipeline, ICAFIX Pipeline
#
# Scripts:
# Struc_and_fMRI_Pipeline.sh, ICAFixProcessingBatch.sh
#
# ------------------------------------------------------------------------------------

  if [[ $setHCPPipelines == 1 ]]; then

    echo -e "Changing current directory to STUDY FOLDER directory\n"
    cd $SF
    export SubIdStr
    echo -e "Adding HCP Pipelines and associated software to environment variables\n"
    module load hcp-pipelines-img/1.0
    date >> $failed

    if [[ $setStruc_and_Func == 1 ]]; then

      date > $PreFSjs
      date > $FSjs
      date > $PostFSjs
      date > $fMRIVjs
      date > $fMRISjs

      echo -e "Structural and Functional pipeline switch on\n"
      echo -e "Beginning structural and functional HCP pipeline processing of" \
              "subjects:\n $SubIdStr"
      ${BS}/Struc_and_fMRI_Pipeline.sh --parameterFile=$SF/InputParameterFile.sh
      jobidfMRISurfaceStr=$(cat  ${BS}/jobidfMRISurfaceStrPipe)
      export jobidfMRISurfaceStr

    fi

    if [[ $setICAFIX == 1 ]]; then

      date > $ICAjs

      echo -e "\nICA+FIX processing switch on\n"
      echo -e "Adding ICA+FIX and associated software to environment variables\n"
      module load fix-img/1.0
      echo -e "Beginning ICA+FIX processing pipeline\n"
      ${BS}/IcaFixProcessingBatch.sh --StudyFolder=$SF
      jobidICAFIX=$(cat ${BS}/jobidICAFIXpipe)
      sleep 1800
      failedJobCheck

    fi
  fi
fi

# ------------------------------------------------------------------------------------
# FSLNETS Analysis Pipeline
#
# Processes:
# FSLNets Analysis PreProcessing Pipeline, FSLNets Analysis
#
# Scripts:
# Pre_FSLNetsAnalysis_Pipeline.sh, FSLNetsAnalysis.sh
#
# ------------------------------------------------------------------------------------

if [[ $setFNA_Pipeline == 1 ]]; then

  echo -e "\nFSLNets Analysis switch on, beginning process\n"

  if [[ $setPreFSLNetsAnalysis == 1 ]]; then

    echo -e "FSLNets Analysis Preprocessing Pipeline switch on," \
            "beginning process\n"
    echo -e "Adding FSL and human connectome (wb_command) to" \
           "environment variables\n"
    module load fsl-img/6.0.1 connectome-uon/workbench-1.3.2

    if [[ $setHCPStyle_Pipeline == 0 ]]; then

      unset SubIdStr
      echo -e "Building list of subjects that have not already been processed" \
              "through the FSLNets Analysis Preprocessing Pipeline\n"

      for SUBJECT_ID in $(ls $SF | grep -E "^[0-9]{7}$"); do

        if [[ -e "${SF}/${SUBJECT_ID}/${DTS_clean}" ]]; then
          
          SubPT=${pt}/L.${SUBJECT_ID}.ptseries.nii
          
          if [[ ! -e "$SubPT" ]]; then
          
            SubIdStr+="$SUBJECT_ID "

          fi
        fi
      done

    fi

    echo -e "Ids to be processed: $SubIdStr\n"
    export SubIdStr

# Submit to slurm with job dependency if ICAFIX being ran in same session
    if [[ ! -z $jobidICAFIX ]]; then

      cmd=$(echo "${FSLDIR}/bin/fsl_sub -q long.q -l ${fCA}/log_files" \
                 "-j $jobidICAFIX" \
                 "${BS}/Pre_FSLNetsAnalysis_Pipeline.sh")
      echo -e "Job being submitted to SLURM:\n $cmd"
      jobidfNAPreProcess=$($cmd)
      echo -e "\njobidfNAPreProcess: $jobidfNAPreProcess\n"

    else

      cmd=$(echo "${FSLDIR}/bin/fsl_sub -q long.q -l ${fCA}/log_files" \
         "${BS}/Pre_FSLNetsAnalysis_Pipeline.sh")
      echo -e "Job being submitted to SLURM:\n\n $cmd\n"
      jobidfNAPreProcess=$($cmd)
      echo -e "\njobidfNAPreProcess: $jobidfNAPreProcess\n"

    fi
  fi

# ------------------------------------------------------------------------------------
# FSLNETS ANALYSIS FSLNetsAnalysis.sh
# ------------------------------------------------------------------------------------

  if [[ $setFSLNetsAnalysis == 1 ]]; then

    echo -e "FSLNets Analysis switch on, beginning process\n"
    echo -e "Adding matlab to environment variables\n"
    module load matlab-img/r2019b

# Submit to slurm with job dependency if fCAPreProcessing being ran in same session
    if [[ ! -z $jobidfNAPreProcess ]]; then

      cmd=$(echo "${FSLDIR}/bin/fsl_sub -q long.q -l ${fCA}/log_files" \
                 "-j $jobidfNAPreProcess" \
                 "${BS}/FSLNetsAnalysis.sh")
      echo -e "Job being submitted to SLURM:\n $cmd"
      jobidFSLNetsAnalysis=$($cmd)
      echo -e "\njobidFSLNetsAnalysis: $jobidFSLNetsAnalysis\n"

    else

      cmd=$(echo "${FSLDIR}/bin/fsl_sub -q long.q -l ${fCA}/log_files" \
         "${BS}/FSLNetsAnalysis.sh")
      echo -e "Job being submitted to SLURM:\n $cmd"
      jobidFSLNetsAnalysis=$($cmd)
      echo -e "\njobidFSLNetsAnalysis: $jobidFSLNetsAnalysis"

    fi
  fi
fi

# ------------------------------------------------------------------------------------
# FILE ADMIN
# ------------------------------------------------------------------------------------

echo -e "STARTING: FILE ADMIN\n"

if [[ $setHCPStyle_Pipeline == 1 ]] && [[ ! -z "$SubIdStr" ]]; then

echo -e "STARTING: removing all files but those needed for ICAFIX pipeline\n"

  for sid in $storeIdStr; do

    rm -r $sid/rfMRI $sid/T2w
    find $sid/MNINonLinear/ -maxdepth 1 -mindepth 1 ! -name 'wmparc.nii.gz' ! -name 'T1w_restore_brain.nii.gz' ! -name 'Results' -exec rm -rf {} \;     
    find $sid/T2w/ -maxdepth 1 -mindepth 1 ! -name 'T2w_acpc.nii.gz' -exec rm -rf {} \;    
    find $sid/T1w/ -maxdepth 1 -mindepth 1 ! -name 'wmparc.nii.gz' -exec rm -rf {} \;

  done

echo -e "FINISHED: removing all files but those needed for ICAFIX pipeline\n"

fi

echo -e "STARTING: changing file permissions\n"

find $SF -user $LOGNAME -type f \! -perm 664 -exec chmod 664 {} \;
find ${SF} -user $LOGNAME -type d -exec chmod 2775 {} \;
find ${fCA}/{log_files, Pre_FSLNetsAnalysis_Out}/ -user $LOGNAME -type f \! -perm 664 -exec chmod 664 {} \;

echo -e "FINISHED: changing file permissions\n"

echo -e "FINISHED: FILE ADMIN\n"

# Uncomment the two lines below to have the script recursively call itself to run more subjects under a new slurm job
# ${BS}/copyIdstoBeProcessed.sh
# sbatch ${BS}/HCPPipelines_to_FSLNetsAnalysis.sh

echo -e "${parentScript_name} finished\n"

# ------------------------------------------------------------------------------------
# ERROR HANDLING
# ------------------------------------------------------------------------------------

failure() {

local lineno=$1
local msg=$2
echo "Failed at $lineno: $msg"

}

trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

