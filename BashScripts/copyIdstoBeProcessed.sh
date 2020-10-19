#!/bin/bash

source /gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/BashScripts/SetupFile.sh

copyIds() {

# Loop counters
local ycount=0; local ncount=0;

date > $toBeP
date > MISSING_FILES

# Various other counters
local yparsed_count=0
local ysubjects_running=0
local ymissingFiles_count=0
local yalreadyProcessed_count=0
local yNoDTS_count=0
local yNoDTS_clean_count=0


#if [[ "$LOGNAME" == "msadm19" ]]; then

#  otherUser="msziw"

#else

#  otherUser="msadm19"

#fi

#echo $otherUser

for SUBJECT_ID in $(grep -E "^[0-9]{7}$" $last); do

  if grep -q "$SUBJECT_ID" $failed; then
    continue
  fi
    
  SubCPT=${C2TXTpt}/L.${SUBJECT_ID}.ptseries.nii

  if [[ ! -e "$SubCPT" ]]; then

    continue

  fi
  
  if grep -q "$SUBJECT_ID" "$y11"; then

    sid=$SUBJECT_ID

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

           ysubjects_running=$[$ysubjects_running +1]
           echo -e "ID RUNNING: $SUBJECT_ID\n"
           skip=1
           break

        fi
      done < <(squeue -u $LOGNAME)

      if [[ "$skip" == "1" ]]; then
        continue
      fi


#      while IFS=$' \t\n' read -r a1 a2 a3 a4 a5 a6 a7 a8; do

#        if [[ "$a1" == "$PreFSjid" ]] || [[ "$a1" == "$FSjid" ]] ||
#           [[ "$a1" == "$PostFSjid" ]] || [[ "$a1" == "$fMRISjid" ]] || [[ "$a1" == "$fMRIVjid" ]] ||
#           [[ "$a1" == "$ICAjid" ]]; then

#           ysubjects_running=$[$ysubjects_running +1]
#           echo -e "ID RUNNING: $SUBJECT_ID\n"
#           skip=1
#           break

#        fi
#      done < <(squeue -u $otherUser)

#      if [[ "$skip" == "1" ]]; then
#        continue
#      fi

    fi

    if [[ $ycount -lt $y ]]; then

      yparsed_count=$[$yparsed_count +1]
      SubSF=${SF}/${SUBJECT_ID}           # Subject specific study folder
      SubDTS=${SF}/${SUBJECT_ID}/${DTS}
      SubDTS_clean=${SF}/${SUBJECT_ID}/${DTS_clean}

        if [[ -e "$SubSF" ]]; then

          if [[ ! -e "$SubSF/$(basename $T1)" ]] || [[ ! -e "$SubSF/$(basename $T2)" ]] ||
             [[ ! -e "$SubSF/$(basename $fMRI)" ]] || [[ ! -e "$SubSF/$(basename $SBREF)" ]]; then

            echo "$SUBJECT_ID missing files"
            $SUBJECT_ID >> MISSING_FILES
            ymissingFiles_count=$[$ymissingFiles_count +1]

          else

            if [[ -e "$SubDTS" ]]; then

              if [[ -e "$SubDTS_clean" ]]; then

               yalreadyProcessed_count=$[$yalreadyProcessed_count +1]
               continue

              else

                yNoDTS_clean_count=$[$yNoDTS_clean_count +1]
                local YesIdStr+="$SUBJECT_ID "
                echo "$SUBJECT_ID" >> $toBeP
                ycount=$[$ycount +1]

              fi

            else

              yNoDTS_count=$[$yNoDTS_count +1]
              local YesIdStr+="$SUBJECT_ID "
              echo "$SUBJECT_ID" >> $toBeP
              ycount=$[$ycount +1]

            fi
          fi

        else

          local YesIdStr+="$SUBJECT_ID "
          echo "$SUBJECT_ID" >> $toBeP
          ycount=$[$ycount +1]

        fi

    fi
  fi
done


echo -e "\nNumber of yes subjects set to be processed: $y"
echo "Number of yes subjects parsed: $yparsed_count"
echo -e "Number of yes subjects skipped due to them currently being run through either" \
        "the HCP Structural, Functional or ICAFIX pipeline: $ysubjects_running"
echo "Number of yes subjects excluded due to missing files: $ymissingFiles_count"
echo "Number of yes subjects excluded due to having already been processed: $yalreadyProcessed_count"
echo "Number of yes subjects already copied for which 'rfMRI_Atlas.dtseries.nii does not exist: $yNoDTS_count"
echo -e "Number of yes subjects already copied for which 'rfMRI_Atlas.dtseries.nii exists'" \
        "but 'rfMRI_Atlas_hp100_clean.dtseries.nii' does not exist: $yNoDTS_clean_count"
echo -e "Number of yes subjects added to list of subjects to be processed: $(echo "$YesIdStr" | wc -w)\n"

sleep 10

local nparsed_count=0
local nsubjects_running=0
local nmissingFiles_count=0
local nalreadyProcessed_count=0
local nNoDTS_count=0
local nNoDTS_clean_count=0

for SUBJECT_ID in $(grep -E "^[0-9]{7}$" $last); do

  if grep -q "$SUBJECT_ID" $failed; then
    continue
  fi

  SubCPT=${C2TXTpt}/L.${SUBJECT_ID}.ptseries.nii

  if [[ ! -e "$SubCPT" ]]; then

    continue

  fi
  
  if grep -q "$SUBJECT_ID" "$n0"; then

    sid=$SUBJECT_ID

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

           nsubjects_running=$[$nsubjects_running +1]
           echo -e "ID RUNNING: $SUBJECT_ID\n"
           skip=1
           break

        fi
      done < <(squeue -u $LOGNAME)

      if [[ "$skip" == "1" ]]; then
        continue
      fi

#      while IFS=$' \t\n' read -r a1 a2 a3 a4 a5 a6 a7 a8; do

#        if [[ "$a1" == "$PreFSjid" ]] || [[ "$a1" == "$FSjid" ]] ||
#           [[ "$a1" == "$PostFSjid" ]] || [[ "$a1" == "$fMRISjid" ]] || [[ "$a1" == "$fMRIVjid" ]] ||
#           [[ "$a1" == "$ICAjid" ]]; then

#          ysubjects_running=$[$ysubjects_running +1]
#           echo -e "ID RUNNING: $SUBJECT_ID\n"
#           skip=1
#           break

#        fi
#      done < <(squeue -u $otherUser)

#      if [[ "$skip" == "1" ]]; then
#        continue
#      fi

    fi


    if [[ $ncount -lt $n ]]; then

      nparsed_count=$[$nparsed_count +1]
      SubSF=${SF}/${SUBJECT_ID}           # Subject specific study folder
      SubDTS=${SF}/${SUBJECT_ID}/${DTS}
      SubDTS_clean=${SF}/${SUBJECT_ID}/${DTS_clean}

        if [[ -e "$SubSF" ]]; then

          if [[ ! -e "$SubSF/$(basename $T1)" ]] || [[ ! -e "$SubSF/$(basename $T2)" ]] ||
             [[ ! -e "$SubSF/$(basename $fMRI)" ]] || [[ ! -e "$SubSF/$(basename $SBREF)" ]]; then

            echo "$SUBJECT_ID missing files"
            $SUBJECT_ID >> MISSING_FILES
            nmissingFiles_count=$[$nmissingFiles_count +1]

          else

            if [[ -e "$SubDTS" ]]; then

              if [[ -e "$SubDTS_clean" ]]; then

               nalreadyProcessed_count=$[$nalreadyProcessed_count +1]
               continue

              else

                nNoDTS_clean_count=$[$nNoDTS_clean_count +1]
                local NoIdStr+="$SUBJECT_ID "
                echo "$SUBJECT_ID" >> $toBeP
                ncount=$[$ncount +1]

              fi

            else

              nNoDTS_count=$[$nNoDTS_count +1]
              local NoIdStr+="$SUBJECT_ID "
              echo "$SUBJECT_ID" >> $toBeP
              ncount=$[$ncount +1]

            fi
          fi

        else

          local NoIdStr+="$SUBJECT_ID "
          echo "$SUBJECT_ID" >> $toBeP
          ncount=$[$ncount +1]

        fi

    fi
  fi
done


echo -e "\nNumber of no subjects set to be processed: $n"
echo "Number of no subjects parsed: $nparsed_count"
echo -e "Number of no subjects skipped due to them currently being run through either" \
        "the HCP Structural, Functional or ICAFIX pipeline: $nsubjects_running"
echo "Number of no subjects excluded due to missing files: $nmissingFiles_count"
echo "Number of no subjects excluded due to having already been processed: $nalreadyProcessed_count"
echo "Number of no subjects already copied for which 'rfMRI_Atlas.dtseries.nii does not exist: $nNoDTS_count"
echo -e "Number of no subjects already copied for which 'rfMRI_Atlas.dtseries.nii exists'" \
        "but 'rfMRI_Atlas_hp100_clean.dtseries.nii' does not exist: $nNoDTS_clean_count"
echo -e "Number of no subjects added to list of subjects to be processed: $(echo "$NoIdStr" | wc -w)\n"

SubIdStr=$YesIdStr$NoIdStr
local TotalToBeProcessed=$(( $y + $n ))
local TotalParsed=$(( $yparsed_count + $nparsed_count ))
local TotalSubjectsRunning=$(( $ysubjects_running + $nsubjects_running ))
local TotalMissingFiles=$(( $ymissingFiles_count + $nmissingFiles_count ))
local TotalAlreadyProcessed=$(( $yalreadyProcessed_count + $nalreadyProcessed_count ))
local TotalNoDTS=$(( $yNoDTS_count + $nNoDTS_count ))
local TotalNoDTS_clean=$(( $yNoDTS_clean_count + $nNoDTS_clean_count ))

echo -e "\nTotal number of subjects set to be processed: $TotalToBeProcessed"
echo "Total number of subjects parsed: $TotalParsed"
echo -e "Total number of subjects skipped due to them currently being ran through\n" \
        "one of the HCP Pipelines: $TotalSubjectsRunning"
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

copyIds

