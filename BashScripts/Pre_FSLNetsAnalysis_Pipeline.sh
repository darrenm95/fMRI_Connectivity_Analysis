#!/bin/bash
#
# # Pre_FSLNetsAnalysis_Pipeline.sh
#
# # FSLNETS ANALYSIS PREPROCESSING PIPELINE 
#
# ## Description
#
# Takes dense time series of subject and extracts parcellated time series 
# (average time series per parcel) for subject before performing a transpose
# and a conversion to text to prepare the data to be read into FSL nets 
# nets_load function.
#
# File names in format L.SUBJECT_ID.fileExtension or R.SUBJECT_ID.fileExtension
#
#
#  This script is setup assuming that it exists within the folder
#  fMRI_Connectivity_Analysis which contains the files and folder outlined in 
#  the README.
#   
# The primary purposes of the FSLNets Analysis PreProcessing Pipeline are:
# 
# 1. Extract and convert the subjects ptseries in to the input format FSLNets 
#    nets_load function expects.
# 2. Create a design matrix to compare subjects in tinnitus and non-tinnitus categories 
#    as outlined in the README file using FSLNets in Matlab.
# 3. Update subject lists, removing those subjects that have recently been processed
#    to prevent repeat processing or errors.
#
# ## Prerequisites:
#
# ### Installed Software
#
# * fsl-6.0.1, workbench-1.3.2 (human connectome)
# 
# ### Required Environment Variables (see SetupFile.sh)
#
# * SF
#
#   Absolute path to the Study Folder directory which contains subject data
#
# * SubIdStr
#
#   Space separated list of subject id's to be processed
#
# * DTS_clean
#
#   Relative path from Study Folder directory to subject specific dense time series
#   that has had ICAFIX applied 
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
# ### Output Directories
#
# The output directories for this script are the directories assigned to the variables
# pt, Tpt and C2TXTpt which contain the subjects extracted parcellated time series,
# transposed versions of the extracted parcellated time series and converted to text
# file version of the extracted and transposed parcellated time series, respectively.
#
# ### Output Files
#
# Ouput files for this script include the extracted, transposed and converted to text
# parcellated time series files as described above. The rest of the output files belong
# to the designCreator function. A design matrix text file is created, a text file
# containing the number of the subjects in each category and a list of subject id's
# with their alphanumeric index that are to be excluded from the analysis. These 
# files are called design.txt, count.txt and excluded.txt. A fourth file design.mat
# is created using FSL's Text2Vest tool.
#
# ------------------------------------------------------------------------------------
# CODE START
# ------------------------------------------------------------------------------------

set -oE functrace

script_name=$(basename "${0}")
echo -e "Starting ${script_name}\n"

# ------------------------------------------------------------------------------------
# VARIABLE CHECKS
# ------------------------------------------------------------------------------------

echo -e "Required Environment Variables: \n"
echo "SF: $SF"
echo "SubIdStr: $SubIdStr"
echo "pt: $pt"
echo "Tpt: $Tpt"
echo "C2TXTpt: $C2TXTpt"
echo "LLAB: $LLAB"
echo "RLAB: $RLAB"
echo "des: $des"
echo "desMat: $desMat"
echo "count: $count"
echo "excluded: $excluded"
echo "inputCSV: $inputCSV"
echo "y11: $y11"
echo -e "n0: $n0\n"

if [[ -z "${SF}" ]]; then
  echo "${script_name}: ABORTING: SF variable must be set"
  exit 1
fi

if [[ -z "${SubIdStr}" ]]; then
  echo "${script_name}: ABORTING: SubIdStr variable must be set"
  exit 1
fi

if [[ -z "${pt}" ]]; then
  echo "${script_name}: ABORTING: pt variable must be set"
  exit 1
fi

if [[ -z "${Tpt}" ]]; then
  echo "${script_name}: ABORTING: Tpt variable must be set"
  exit 1
fi

if [[ -z "${C2TXTpt}" ]]; then
  echo "${script_name}: ABORTING: C2TXTpt variable must be set"
  exit 1
fi

if [[ -z "${LLAB}" ]]; then
  echo "${script_name}: ABORTING: LLAB variable must be set"
  exit 1
fi

if [[ -z "${RLAB}" ]]; then
  echo "${script_name}: ABORTING: RLAB variable must be set"
  exit 1
fi

if [[ -z "${des}" ]]; then
  echo "${script_name}: ABORTING: des variable must be set"
  exit 1
fi

if [[ -z "${desMat}" ]]; then
  echo "${script_name}: ABORTING: desMat variable must be set"
  exit 1
fi

if [[ -z "${count}" ]]; then
  echo "${script_name}: ABORTING: count variable must be set"
  exit 1
fi

if [[ -z "${excluded}" ]]; then
  echo "${script_name}: ABORTING: excluded variable must be set"
  exit 1
fi

if [[ -z "${inputCSV}" ]]; then
  echo "${script_name}: ABORTING: inputCSV variable must be set"
  exit 1
fi

if [[ -z "${y11}" ]]; then
  echo "${script_name}: ABORTING: y11 variable must be set"
  exit 1
fi

if [[ -z "${n0}" ]]; then
  echo "${script_name}: ABORTING: n0 variable must be set"
  exit 1
fi

# ------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------

# Sets subject specific file paths 
setSubjPaths() {

Subj_dense_tseries=$(printf '%s/%s/%s' $SF $SUBJECT_ID $DTS_clean)

L_extracted_ptseries=${pt}/L.$SUBJECT_ID.ptseries.nii
R_extracted_ptseries=$(printf '%s/R.%s.ptseries.nii' $pt $SUBJECT_ID)

L_transposed_ptseries=$(printf '%s/L.%s.T_ptseries.nii' $Tpt $SUBJECT_ID)
R_transposed_ptseries=$(printf '%s/R.%s.T_ptseries.nii' $Tpt $SUBJECT_ID)

L_converted_to_text_ptseries=$(printf '%s/L_ptseries/L.%s.ptseries.txt' $C2TXTpt $SUBJECT_ID)
R_converted_to_text_ptseries=$(printf '%s/R_ptseries/R.%s.ptseries.txt' $C2TXTpt $SUBJECT_ID)  
}

# Extracts subjects parcellated time series
extract_ptseries() {

wb_command -cifti-parcellate $Subj_dense_tseries $LLAB COLUMN $L_extracted_ptseries
wb_command -cifti-parcellate $Subj_dense_tseries $RLAB COLUMN $R_extracted_ptseries
}

# Transpose subjects extracted parcellated time series
transpose_ptseries() {

wb_command -cifti-transpose $L_extracted_ptseries $L_transposed_ptseries
wb_command -cifti-transpose $R_extracted_ptseries $R_transposed_ptseries
}

# Convert to text subjects transposed and extracted parcellated time series
convert_ptseries_to_text() {

wb_command -cifti-convert -to-text $L_transposed_ptseries $L_converted_to_text_ptseries
wb_command -cifti-convert -to-text $R_transposed_ptseries $R_converted_to_text_ptseries
}

# Create design matrix .txt and .mat, count.txt and excluded.txt 
designCreator() {

local count_yes=0
local count_no=0
local count_excluded=0
local index=0

>$des
>$desMat
>$count
>$excluded

for SUBJECT_ID in $(ls ${C2TXTpt}/L_ptseries/ | grep -oE '[0-9]{7}'); do
  
  index=$[$index +1]
  while IFS=, read -r col1 col2 col3 col4; do
  
    if [[ "$col2" == "11" ]]; then

      count_yes=$[$count_yes +1]
      echo  "1 0" >> $des

    fi

    if [[ "$col2" == "0" ]]; then
     
      count_no=$[$count_no +1]
      echo  "0 1" >> $des

    fi

    if [[ "$col2" != "11" && "$col2" != "0" ]]; then

      count_excluded=$[$count_excluded +1]
      echo  "$SUBJECT_ID $index" >> $excluded

    fi
  done < <(grep "$SUBJECT_ID" "$inputCSV")
done

echo "Number of participants who answered 'Yes, now most or all of the time' : $count_yes" >> $count
echo "Number of participants who answered 'No, never' : $count_no" >> $count
echo "Number of participants who were excluded from the analysis : $count_excluded" >> $count


cd ${des/design.txt/}
Text2Vest design.txt design.mat
cd $SF
}

# Remove subject id's from lists of subjects id's still to be processed
idRemover() {

for SUBJECT_ID in $(ls ${C2TXTpt}/L_ptseries/ | grep -oE "[0-9]{7}"); do

  if grep -q "$SUBJECT_ID" $y11; then

    yremoved+="$SUBJECT_ID "
    sed "/^$SUBJECT_ID$/d" -i $y11

  fi
  if grep -q "$SUBJECT_ID" $n0; then

    nremoved+="$SUBJECT_ID "
    sed "/^$SUBJECT_ID$/d" -i $n0

  fi
done

echo -e "Subject id's that have been processed and removed from 'yes, all or most" \
        "of the time' list, of subjects still to be processed: $yremoved\n"
echo -e "Subject id's that have been processed and removed from 'no, never'" \
        "list, of subjects still to be processed: $nremoved\n"
}

# ------------------------------------------------------------------------------------
# EXECUTION
# ------------------------------------------------------------------------------------

echo -e "Extracting, tranposing and converting to text subjects parcellated" \
        "time series\n"

for SUBJECT_ID in $SubIdStr; do

  setSubjPaths
  if [[ ! -e "$L_extracted_ptseries" ]] && [[ ! -e "$R_extracted_ptseries" ]]; then
   
    if [[ ! -e "$Subj_dense_tseries" ]]; then
     
      continue
 
    else

      extract_ptseries
      transpose_ptseries
      convert_ptseries_to_text

    fi

  else

    echo -e "Left or right, or both left and right, parcellated time series" \
            "already exists for subject: $SUBJECT_ID"
    continue

  fi
done

echo -e "Creating design matrix files, count.txt and excluded.txt\n"
designCreator

echo -e "Removing id's of newly processed subjects from lists of subject id's" \
        "still to be processed\n"
idRemover

echo -e "${script_name} finished.\n"

# ------------------------------------------------------------------------------------
# ERROR HANDLING
# ------------------------------------------------------------------------------------

failure() {

  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

