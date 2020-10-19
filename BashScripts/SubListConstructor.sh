#!/bin/bash
#
# # SubListConstructor.sh
#
# # SUBJECT LIST CONSTRUCTOR
#
# ## Description 
#
# Parses subject id's from lists y11_all.txt and n0.txt until number of subjects 
# to be processed, set in SetupFile.sh for both yes and no tinnitus categories, 
# are added to the list of subject id's - a space separated string.
#
# The primary purposes of the Subject List Constructor script are:
#
# 1. Check correct files exists in subjects source directory
# 2. Check that a subject specific study folder does not already exist which means
#    this is the first time the subject has been processed
# 3. Update the y11_all.txt and n0.txt subject lists by removing subjects that do
#    not satisfy the above criteria
# 4. Add all subjects that do satisfy the above criteria to a space separated string
#    list of subject id's and to the file toBeProcessed.txt so that the user can 
#    choose to continue with the remaining processes another time
# 5. Send to standard ouput the number of subjects that: have been parsed, 
#    did not possess the correct files, had already had their data copied from 
#    source directory to study folder and how many have been added for processing.
#
# ## Prerequisites:
#
# ### Installed Software
#
# [None]
#
# ### Required Environment Variables (see SetupFile.sh)
#
# * last
#
#   Absolute path to lastRun.txt file containing subject id's that were selected
#   on previous run of SubListConstructor.sh
#
# * toBeP
#
#   Absolute path to toBeProcessed.txt file containing list of subject id's that
#   are yet to be processed
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
# * y11
#
#   Absolute path to y11_all.txt text file containing list of subject id's whose response
#   was 'yes, all or most of the time' to tinnitus question (possess a data code of
#   11) and are yet to be processed
#
# * n0
#
#   Absolute path to n0.txt text file containing list of subject id's whose response
#   was 'no, never' to tinnitus question (possess a data code of 0) and are yet to be
#   processed
#
# ### Output Directories
#
# [None]
#
# ### Output Files
#
# [None] - no new files are being created, the files toBeProcessed.txt, y11_all.txt,
# and n0.txt are simply being updated. The output of the script is the space 
# separated string list of subject id's and the messages sent to standard output
# regarding the number of subjects parsed, missing files, already copied and to be
# processed.
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
echo -e "last=$last"
echo -e "toBeP=$toBeP"
echo -e "y=$y"
echo -e "n=$n"
echo -e "SF=$SF"
echo -e "SD=$SD"
echo -e "y11=$y11"
echo -e "T1=$T1"
echo -e "T2=$T2"
echo -e "fMRI=$fMRI"
echo -e "SBREF=$SBREF"
echo -e "n0=$n0\n"

if [[ -z "${last}" ]]; then
  echo "${script_name}: ABORTING: last variable must be set"
  exit 1
fi

if [[ -z "${toBeP}" ]]; then
  echo "${script_name}: ABORTING: toBeP variable must be set"
  exit 1
fi

if [[ ! ${y} =~ ^[0-9]+$ ]]; then
  echo "${script_name}: ABORTING: y variable must be set and must be a number"
  exit 1
fi

if [[ ! ${n} =~ ^[0-9]+$ ]]; then
  echo "${script_name}: ABORTING: n variable must be set and must be a number"
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

if [[ -z "${y11}" ]]; then
  echo "${script_name}: ABORTING: y11 variable must be set"
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

if [[ -z "${n0}" ]]; then
  echo "${script_name}: ABORTING: n0 variable must be set"
  exit 1
fi

# ------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------

MakeString() {

# Loop counters
local ycount=0; local ncount=0;

# Various other counters
local yparsed_count=0
local subjects_running=0
local ymissingFiles_count=0
local yalreadyProcessed_count=0
local yNoDTS_count=0
local yNoDTS_clean_count=0

# Overwrite lastRun.txt with date
date > $last

for SUBJECT_ID in $(grep -E "^[0-9]{7}$" $y11); do
    
    sid=$SUBJECT_ID

    if grep -q "$SUBJECT_ID" $failed; then
      continue
    fi

    if grep -q $sid $PreFSjs || grep -q $sid $ICAjs; then
  
      skip=0

      echo -e "ID FOUND: $sid\n"

      PreFSjid=$(grep "$sid" "$PreFSjs" | grep -oE "^[0-9]{7}")
      FSjid=$(grep "$sid" "$FSjs" | grep -oE "^[0-9]{7}")
      PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      while IFS=$' \t\n' read -r a1 a2 a3 a4 a5 a6 a7 a8; do
 
        if [[ "$a1" == "$PreFSjid" ]] || [[ "$a1" == "$FSjid" ]] ||
           [[ "$a1" == "$PostFSjid" ]] || [[ "$a1" == "$fMRISjid" ]] || [[ "$a1" == "$fMRIVjid" ]] ||
           [[ "$a1" == "$ICAjid" ]]; then
          
           subjects_running=$[$subjects_running +1]
           echo -e "ID RUNNING: $SUBJECT_ID\n"
           skip=1
           break

        fi
      done < <(squeue -u $LOGNAME)

      if [[ "$skip" == "1" ]]; then
        continue
      fi

    fi

    SubCPT=${C2TXTpt}/L.${SUBJECT_ID}.ptseries.nii

    if [[ ! -e "$SubCPT" ]]; then
      
      continue

    fi
 
    if [[ $ycount -lt $y ]]; then

      yparsed_count=$[$yparsed_count +1]
      SubSF=${SF}/${SUBJECT_ID}           # Subject specific study folder
      SubSD=${SD}/${SUBJECT_ID}           # Subject specific source directory
      SubDTS=${SF}/${SUBJECT_ID}/${DTS}
      SubDTS_clean=${SF}/${SUBJECT_ID}/${DTS_clean}

      if [[ ! -e "$SubSD/$T1" ]] || [[ ! -e "$SubSD/$T2" ]] || [[ ! -e "$SubSD/$fMRI" ]] ||
         [[ ! -e "$SubSD/$SBREF" ]]; then
        
        ymissingFiles_count=$[$ymissingFiles_count +1]
        [[ ! -e "$SubSD/$T1" ]] && echo "$SubSD/$T1 does not exist."
        [[ ! -e "$SubSD/$T2" ]] && echo "$SubSD/$T2 does not exist."
        [[ ! -e "$SubSD/$fMRI" ]] && echo "$SubSD/$fMRI does not exist."
        [[ ! -e "$SubSD/$SBREF" ]] && echo "$SubSD/$SBREF does not exist."
       # sed "/^$SUBJECT_ID$/d" -i $y11

      else

        if [[ -e "$SubSF" ]]; then

          if [[ ! -e "$SubSF/$(basename $T1)" ]] || [[ ! -e "$SubSF/$(basename $T2)" ]] ||
             [[ ! -e "$SubSF/$(basename $fMRI)" ]] || [[ ! -e "$SubSF/$(basename $SBREF)" ]]; then
            
            local YesIdStr+="$SUBJECT_ID "
            echo "$SUBJECT_ID" >> $last
            ycount=$[$ycount +1]

          else
           
            if [[ -e "$SubDTS" ]]; then
            
              if [[ -e "$SubDTS_clean" ]]; then
             
               yalreadyProcessed_count=$[$yalreadyProcessed_count +1] 
               continue
              
              else

                yNoDTS_clean_count=$[$yNoDTS_clean_count +1]
                local YesIdStr+="$SUBJECT_ID "
                echo "$SUBJECT_ID" >> $last
                ycount=$[$ycount +1]

              fi
            
            else            

              yNoDTS_count=$[$yNoDTS_count +1]
              local YesIdStr+="$SUBJECT_ID "
              echo "$SUBJECT_ID" >> $last
              ycount=$[$ycount +1]

            fi
          fi

        else

          local YesIdStr+="$SUBJECT_ID "
          echo "$SUBJECT_ID" >> $last
          ycount=$[$ycount +1]

        fi
      fi
    fi
done   


echo -e "\nNumber of yes subjects set to be processed: $y"
echo "Number of yes subjects parsed: $yparsed_count"
echo -e "Number of yes subjects skipped due to them currently being run through either" \
        "the HCP Structural, Functional or ICAFIX pipeline: $subjects_running"
echo "Number of yes subjects excluded due to missing files: $ymissingFiles_count"
echo "Number of yes subjects excluded due to having already been processed: $yalreadyProcessed_count"
echo "Number of yes subjects already copied for which 'rfMRI_Atlas.dtseries.nii does not exist: $yNoDTS_count"
echo -e "Number of yes subjects already copied for which 'rfMRI_Atlas.dtseries.nii exists'" \
        "but 'rfMRI_Atlas_hp100_clean.dtseries.nii' does not exist: $yNoDTS_clean_count"
echo -e "Number of yes subjects added to list of subjects to be processed: $(echo "$YesIdStr" | wc -w)\n"

# No counters
local nparsed_count=0
local nmissingFiles_count=0
local nalreadyProcessed_count=0
local nNoDTS_count=0
local nNoDTS_clean_count=0

for SUBJECT_ID in $(grep -E "^[0-9]{7}$" $n0); do

    sid=$SUBJECT_ID

    if grep -q "$SUBJECT_ID" $failed; then
      continue
    fi

    if grep -q $sid $PreFSjs || grep -q $sid $ICAjs; then

      skip=0

      echo -e "ID FOUND: $sid\n"

      PreFSjid=$(grep "$sid" "$PreFSjs" | grep -oE "^[0-9]{7}")
      FSjid=$(grep "$sid" "$FSjs" | grep -oE "^[0-9]{7}")
      PostFSjid=$(grep "$sid" "$PostFSjs" | grep -oE "^[0-9]{7}")
      fMRISjid=$(grep "$sid" "$fMRISjs" | grep -oE "^[0-9]{7}")
      fMRIVjid=$(grep "$sid" "$fMRIVjs" | grep -oE "^[0-9]{7}")
      ICAjid=$(grep "$sid" "$ICAjs" | grep -oE "^[0-9]{7}")

      while IFS=$' \t\n' read -r a1 a2 a3 a4 a5 a6 a7 a8; do

        if [[ "$a1" == "$PreFSjid" ]] || [[ "$a1" == "$FSjid" ]] ||
           [[ "$a1" == "$PostFSjid" ]] || [[ "$a1" == "$fMRISjid" ]] || [[ "$a1" == "$fMRIVjid" ]] ||
           [[ "$a1" == "$ICAjid" ]]; then

           subjects_running=$[$subjects_running +1]
           echo -e "ID RUNNING: $SUBJECT_ID\n"
           skip=1
           break

        fi
      done < <(squeue -u $LOGNAME)

      if [[ "$skip" == "1" ]]; then
        continue
      fi

    fi

    SubCPT=${C2TXTpt}/L.${SUBJECT_ID}.ptseries.nii

    if [[ ! -e "$SubCPT" ]]; then

      continue

    fi

    if [[ $ncount -lt $n ]]; then

      nparsed_count=$[$nparsed_count +1]
      SubSF=${SF}/${SUBJECT_ID}           # Subject specific study folder
      SubSD=${SD}/${SUBJECT_ID}           # Subject specific source directory
      SubDTS=${SF}/${SUBJECT_ID}/${DTS}
      SubDTS_clean=${SF}/${SUBJECT_ID}/${DTS_clean}

      if [[ ! -e "$SubSD/$T1" ]] || [[ ! -e "$SubSD/$T2" ]] || [[ ! -e "$SubSD/$fMRI" ]] || [[ ! -e "$SubSD/$SBREF" ]]; then

        nmissingFiles_count=$[$nmissingFiles_count +1]
        [[ ! -e "$SubSD/$T1" ]] && echo "$SubSD/$T1 does not exist."
        [[ ! -e "$SubSD/$T2" ]] && echo "$SubSD/$T2 does not exist."
        [[ ! -e "$SubSD/$fMRI" ]] && echo "$SubSD/$fMRI does not exist."
        [[ ! -e "$SubSD/$SBREF" ]] && echo "$SubSD/$SBREF does not exist."
       # sed "/^$SUBJECT_ID$/d" -i $n0

      else

        if [[ -e "$SubSF" ]]; then

          if [[ ! -e "$SubSF/$(basename $T1)" ]] || [[ ! -e "$SubSF/$(basename $T2)" ]] ||
             [[ ! -e "$SubSF/$(basename $fMRI)" ]] || [[ ! -e "$SubSF/$(basename $SBREF)" ]]; then

            local NoIdStr+="$SUBJECT_ID "
            echo "$SUBJECT_ID" >> $last
            ncount=$[$ncount +1]

          else

            nalreadyProcessed_count=$[$nalreadyProcessed_count +1]

            if [[ -e "$SubDTS" ]]; then

              if [[ -e "$SubDTS_clean" ]]; then

                continue

              else

                nNoDTS_clean_count=$[$nNoDTS_clean_count +1]
                local NoIdStr+="$SUBJECT_ID "
                echo "$SUBJECT_ID" >> $last
                ncount=$[$ncount +1]

              fi

            else

              nNoDTS_count=$[$nNoDTS_count +1]
              local NoIdStr+="$SUBJECT_ID "
              echo "$SUBJECT_ID" >> $last
              ncount=$[$ncount +1]

            fi
          fi

        else

          local NoIdStr+="$SUBJECT_ID "
          echo "$SUBJECT_ID" >> $last
          ncount=$[$ncount +1]

        fi
      fi
    fi
done


echo -e "\nNumber of no subjects set to be processed: $n"
echo "Number of no subjects parsed: $nparsed_count"
echo -e "Number of no subjects skipped due to them currently being run through either the" \
         "HCP Structural, Functional or ICAFIX pipeline: $subjects_running"
echo "Number of no subjects excluded due to missing files: $nmissingFiles_count"
echo "Number of no subjects excluded due to having already been processed: $nalreadyProcessed_count"
echo "Number of no subjects already copied for which 'rfMRI_Atlas.dtseries.nii does not exist: $nNoDTS_count"
echo -e "Number of no subjects already copied for which 'rfMRI_Atlas.dtseries.nii exists'" \
        "but 'rfMRI_Atlas_hp100_clean.dtseries.nii' does not exist: $nNoDTS_clean_count"
echo -e "Number of no subjects added to list of subjects to be processed: $(echo "$NoIdStr" | wc -w)\n"

SubIdStr=$YesIdStr$NoIdStr
local TotalToBeProcessed=$(( $y + $n ))
local TotalParsed=$(( $yparsed_count + $nparsed_count ))
local TotalMissingFiles=$(( $ymissingFiles_count + $nmissingFiles_count ))
local TotalAlreadyProcessed=$(( $yalreadyProcessed_count + $nalreadyProcessed_count ))
local TotalNoDTS=$(( $yNoDTS_count + $nNoDTS_count ))
local TotalNoDTS_clean=$(( $yNoDTS_clean_count + $nNoDTS_clean_count ))

echo -e "\nTotal number of subjects set to be processed: $TotalToBeProcessed"
echo "Total number of subjects parsed: $TotalParsed"
echo -e "Total number of subjects skipped due to them currently being ran through\n" \
        "one of the HCP Pipelines: $subjects_running"
echo "Total number of subjects excluded due to missing files: $TotalMissingFiles"
echo -e "Total number of subjects excluded due to having already been processed: $TotalAlreadyProcessed"
echo -e "Total number of subjects already copied for which" \
        "'rfMRI_Atlas.dtseries.nii' does not exist: $TotalNoDTS"
echo -e "Total number of subjects already copied for which" \
        "'rfMRI_Atlas.dtseries.nii' exists but 'rfMRI_Atlas_hp100_clean.dtseries.nii'" \
        "does not exist: $TotalNoDTS_clean_count"
echo -e "Total number of subjects added to list of subjects to be processed: $(echo "$SubIdStr" | wc -w)\n"
echo -e "Subjects to be processed:\n\n$SubIdStr\n"
         			
}

# ------------------------------------------------------------------------------------
# EXECUTION
# ------------------------------------------------------------------------------------

MakeString
unset -f MakeString

echo -e "Ids to be processed: $SubIdStr\n"
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

