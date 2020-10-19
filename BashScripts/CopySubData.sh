#!/bin/bash
#
# # CopySubData.sh
#
# # COPY SUBJECT DATA
#
# ## Description
#
# Copies subjects data from subject specific source directory over to subject 
# specific study folder directory.
#
# The primary purposes of the Copy Subject Data script are:
# 1. Check if a subject specific study folder exists
# 2. If it does, perform individual checks to see if T1, T2, fMRI and SBREF 
#    data for that subject data has been copied over and if it hasn't copy the data
#    over from source directory to study folder
# 3. If a subject specific study folder doesn't exist, script makes one and copies
#    T1, T2, fMRI and SBREF data over
# 
# ## Prerequisites:
#
# ### Installed Software
#
# [None]
#
# ### Required Environment Variables (see SetupFile.sh)
#
# * SubIdStr
#
#   Space separated list of subject id's to be processed
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
# ### Output Directories
#
# Subject specific study folder directory contained within the designated Study
# Folder directory
#
# ### Output Files
#
# Files T1.nii.gz, T2_FLAIR.nii.gz, rfMRI.nii.gz and rfMRI_SBREF.nii.gz are copied
# over from subjects source directory to study folder directory.
#
# ------------------------------------------------------------------------------------
# CODE START
# ------------------------------------------------------------------------------------

set -oeE functrace

script_name=$(basename $BASH_SOURCE) 
echo -e "Starting ${script_name}\n"

# ------------------------------------------------------------------------------------
# VARIABLE CHECKS
# ------------------------------------------------------------------------------------

echo -e "Required Environment Variables: \n"
echo -e "SubIdStr=$SubIdStr"
echo -e "SF=$SF"
echo -e "SD=$SD"
echo -e "T1=$T1"
echo -e "T2=$T2"
echo -e "fMRI=$fMRI"
echo -e "SBREF=$SBREF\n"

if [[ -z "${SubIdStr}" ]]; then
  echo "${script_name}: ABORTING: SubIdStr variable must be set"
  exit 1
fi

if [[ -z "${SF}" ]]; then
  echo "${script_name}: ABORTING: SF variable must be set"
  exit 1
fi

if [[ -z "${SD}" ]]; then
  echo "${script_name}: ABORTING: SD variable must be set"
  exit 1
fi

if [[ -z "${T1}" ]]; then
  echo "${script_name}: ABORTING: T1 variable must be set"
  exit 1
fi

if [[ -z "${T2}" ]]; then
  echo "${script_name}: ABORTING: T2 variable must be set"
  exit 1
fi

if [[ -z "${fMRI}" ]]; then
  echo "${script_name}: ABORTING: fMRI variable must be set"
  exit 1
fi

if [[ -z "${SBREF}" ]]; then
  echo "${script_name}: ABORTING: SBREF variable must be set"
  exit 1
fi

# ------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------

CopySubjectData() {
for SUBJECT_ID in $SubIdStr; do

    local SubSF=${SF}/${SUBJECT_ID}   # Subject specific study folder
    local SubSD=${SD}/${SUBJECT_ID}   # Subject specific source directory

    if [[ -e "$SubSF" ]]; then

      if [[ ! -e "$SubSF/$(basename $T1)" ]]; then
        cp $SubSD/$T1 $SubSF
      fi

      if [[ ! -e "$SubSF/$(basename $T2)" ]]; then
        cp $SubSD/$T2 $SubSF
      fi

      if [[ ! -e "$SubSF/$(basename $fMRI)" ]]; then
        cp $SubSD/$fMRI $SubSF
      fi

      if [[ ! -e "$SubSF/$(basename $SBREF)" ]]; then
        cp $SubSD/$SBREF $SubSF
      fi

    else

      mkdir $SubSF
      chmod 770 $SubSF
      cp $SubSD/{$T1,$T2,$fMRI,$SBREF} $SubSF

    fi
done 
}

# ------------------------------------------------------------------------------------
# EXECUTION
# ------------------------------------------------------------------------------------

CopySubjectData
unset -f CopySubjectData

# ------------------------------------------------------------------------------------
# ERROR HANDLING
# ------------------------------------------------------------------------------------

failure() {

local lineno=$1
local msg=$2
echo "Failed at $lineno: $msg"

}

trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
