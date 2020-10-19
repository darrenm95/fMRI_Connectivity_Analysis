#!/bin/bash

source /gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/BashScripts/SetupFile.sh

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
      echo "sid: $SUBJECT_ID, data-code: $col2" >> yes  
    
    fi

    if [[ "$col2" == "0" ]]; then

      count_no=$[$count_no +1]
      echo  "0 1" >> $des
      echo "sid: $SUBJECT_ID, data-code: $col2" >> no

    fi

    if [[ "$col2" != "11" && "$col2" != "0" ]]; then

      count_excluded=$[$count_excluded +1]
      echo  "sid: $SUBJECT_ID, data-code: $col2, index:$index" >> $excluded

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

designCreator
