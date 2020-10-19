#!/bin/bash
# 
# # IcaFixProcessingBatch.sh
#
# # ICA FIX PROCESSING BATCH
#
# ## Description
#
#
# ## Prerequisites:
#
# ### Installed Software
#
# * [FSL][FSL] - FMRIB's Software Library (version 5.0.2 or higher)
#
# * [FREESURFER] - (version 5.2 or higher)
#
# * [gradunwarp] - (python code from MGH)
#
# ### Required Environment Variables
#
# * HCPPIPEDIR
#
#   The "home" directory for the version of the HCP Pipeline Tools product
#   being used. E.g. /nrgpackages/tools.release/hcp-pipeline-tools-V3.0
#
# * HCPPIPEDIR_Global
#
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
#   Location of shared sub-scripts that are used to carry out some of the
#   steps of the PreFreeSurfer pipeline and are also used to carry out
#   some steps of other pipelines.
#
# * FSLDIR
#
#   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
#   University
#
# ------------------------------------------------------------------------------------
# CODE START
# ------------------------------------------------------------------------------------

set -e 

script_name=$(basename "${0}")
echo -e "Starting ${script_name}\n"
exec > "${fCA}/log_files/${script_name}.o$(date +%d-%m-%Y_%R)"
exec 2>"${fCA}/log_files/${script_name}.e$(date +%d-%m-%Y_%R)"

# ------------------------------------------------------------------------------------
# VARIABLE CHECKS
# ------------------------------------------------------------------------------------

echo -e "Required Environment Variables: \n"
echo "SF: $SF"
echo "SubIdStr: $SubIdStr"
echo -e "ICAjs: $ICAjs\n"

if [[ -z "${SF}" ]]; then
  echo "${script_name}: ABORTING: SF variable must be set"
  exit 1
fi

if [[ -z "${SubIdStr}" ]]; then
  echo "${script_name}: ABORTING: SubIdStr variable must be set"
  exit 1
fi

if [[ -z "${ICAjs}" ]]; then
  echo "${script_name}: ABORTING: ICAjs variable must be set"
  exit 1
fi

for SUBJECT_ID in $SubIdStr; do

  SubDTS_clean=${SF}/${SUBJECT_ID}/${DTS_clean}

  if [[ -e "$SubDTS_clean" ]]; then

    echo -e "$SUBJECT_ID has already been processed through ICAFIX pipeline." \
            "Removing id from string of id's that are to be processed\n"
    SubIdStr=${SubIdStr/$SUBJECT_ID/}
    if [[ -z "${SubIdStr}" ]]; then
      echo -e "${script_name}: ABORTING: no remaining subjects to be processed" \
              "in SubIdStr"
      exit 1
    fi
  fi
done



# Global default values
DEFAULT_STUDY_FOLDER="$SF"
DEFAULT_SUBJECT_LIST="$SubIdStr"
##DEFAULT_ENVIRONMENT_SCRIPT="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh"
DEFAULT_RUN_LOCAL="FALSE"
#DEFAULT_FIXDIR="${HOME}/tools/fix1.06"  ##OPTIONAL: If not set will use $FSL_FIXDIR specified in EnvironmentScript

#
# Function Description
#	Get the command line options for this script
#
# Global Output Variables
#	${StudyFolder}			- Path to folder containing all subjects data in subdirectories named
#							  for the subject id
#	${Subjlist}				- Space delimited list of subject IDs
#	${EnvironmentScript}	- Script to source to setup pipeline environment
#	${FixDir}				- Directory containing FIX
#	${RunLocal}				- Indication whether to run this processing "locally" i.e. not submit
#							  the processing to a cluster or grid
#
get_options() {
	local scriptName=$(basename ${0})
	local arguments=("$@")

	# initialize global output variables
	StudyFolder="${DEFAULT_STUDY_FOLDER}"
	Subjlist="${DEFAULT_SUBJECT_LIST}"
#	EnvironmentScript="${DEFAULT_ENVIRONMENT_SCRIPT}"
	FixDir="${DEFAULT_FIXDIR}"
	RunLocal="${DEFAULT_RUN_LOCAL}"

	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]
	do
		argument=${arguments[index]}

		case ${argument} in
			--StudyFolder=*)
				StudyFolder=${argument#*=}
				index=$(( index + 1 ))
				;;
			--Subject=*)
				Subjlist=${argument#*=}
				index=$(( index + 1 ))
				;;
#			--EnvironmentScript=*)
#				EnvironmentScript=${argument#*=}
#				index=$(( index + 1 ))
#				;;
			--FixDir=*)
				FixDir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--runlocal | --RunLocal)
				RunLocal="TRUE"
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: Unrecognized Option: ${argument}"
				exit 1
				;;
		esac
	done

	# check required parameters
	if [ -z ${StudyFolder} ]
	then
		echo "ERROR: StudyFolder not specified"
		exit 1
	fi

	if [[ -z ${Subjlist} ]]
	then
		echo "ERROR: Subjlist not specified"
		exit 1
	fi

#	if [ -z ${EnvironmentScript} ]
#	then
#		echo "ERROR: EnvironmentScript not specified"
#		exit 1
#	fi

	# MPH: Allow FixDir to be empty at this point, so users can take advantage of the FSL_FIXDIR setting
	# already in their EnvironmentScript
#    if [ -z ${FixDir} ]
#    then
#        echo "ERROR: FixDir not specified"
#        exit 1
#    fi

	if [ -z ${RunLocal} ]
	then
		echo "ERROR: RunLocal is an empty string"
		exit 1
	fi

	# report options
	echo "-- ${scriptName}: Specified Command-Line Options: -- Start --"
	echo "   StudyFolder: ${StudyFolder}"
	echo "   Subjlist: ${Subjlist}"
#	echo "   EnvironmentScript: ${EnvironmentScript}"
	if [ ! -z ${FixDir} ]; then
		echo "   FixDir: ${FixDir}"
	fi
	echo "   RunLocal: ${RunLocal}"
	echo "-- ${scriptName}: Specified Command-Line Options: -- End --"
}  # get_options()

#
# Function Description
#	Main processing of this script
#
#	Gets user specified command line options and runs a batch of ICA+FIX processing
#
main() {
	# get command line options
	get_options "$@"

	# set up pipeline environment variables and software
#	source ${EnvironmentScript}

	# MPH: If DEFAULT_FIXDIR is set, or --FixDir argument was used, then use that to
	# override the setting of FSL_FIXDIR in EnvironmentScript
	if [ ! -z ${FixDir} ]; then
		export FSL_FIXDIR=${FixDir}
	fi

	# set list of fMRI on which to run ICA+FIX, separate MR FIX groups with %, use spaces (or @ like dedrift...) to otherwise separate runs
	# the MR FIX groups determine what gets concatenated before doing ICA
	# the groups can be whatever you want, you can make a day 1 group and a day 2 group, or just concatenate everything, etc
	fMRINames="rfMRI"

	# If you wish to run "multi-run" (concatenated) FIX, specify the names to give the concatenated output files
	# In this case, all the runs included in ${fMRINames} become the input to multi-run FIX
	# Otherwise, leave ConcatNames empty (in which case "single-run" FIX is executed serially on each run in ${fMRINames})
	ConcatNames=""
	ConcatNames=""  ## Use space (or @) to separate concatenation groups

	# set temporal highpass full-width (2*sigma) to use, in seconds, cannot be 0 for single-run FIX
	bandpass=100 # Default:	bandpass=2000

	# MR FIX also supports 0 for a linear detrend, or "pdX" for a polynomial detrend of order X
	# e.g., bandpass=pd1 is linear detrend (functionally equivalent to bandpass=0)
	# bandpass=pd2 is a quadratic detrend
	#bandpass=0 #comment out for single run FIX and use above line for bandpass=2000

	# set whether or not to regress motion parameters (24 regressors)
	# out of the data as part of FIX (TRUE or FALSE)
	domot=TRUE # Default:	domot=FALSE

	# set training data file
	TrainingData=UKBiobank.RData #	Default: TrainingData=HCP_hp2000.RData

	# set FIX threshold (controls sensitivity/specificity tradeoff)
	FixThreshold=20 # Default:	FixThreshold=10

	#delete highpass files (note that delete intermediates=TRUE is not recommended for MR+FIX)
	DeleteIntermediates=FALSE

	# establish queue for job submission
	#QUEUE="-q hcp_priority.q"
	QUEUE="-q long.q"
	if [ "${RunLocal}" == "TRUE" ]; then
		queuing_command=()
	else
		queuing_command=("${FSLDIR}/bin/fsl_sub" "${QUEUE}" "-l ./log_files" )
	fi
        
        # establish job dependency for job submission
        if [[ ! -z $jobidfMRISurfaceStr ]]; then
          declare -A jobidfMRISurfaceArr="($jobidfMRISurfaceStr)"
	fi

        for Subject in ${Subjlist}; do
		echo ${Subject}
                
                DEPENDENCY=""
                if [[ ! -z $jobidfMRISurfaceStr ]]; then
                  jobidfMRISurface=${jobidfMRISurfaceArr["$Subject"]}
                  if [[ ! -z $jobidfMRISurface ]]; then
                    DEPENDENCY="-j $jobidfMRISurface"
                  fi
                fi
    
                ResultsFolder="${StudyFolder}/${Subject}/MNINonLinear/Results"

		if [ -z "${ConcatNames}" ]; then
			# single-run FIX
			FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix

			fMRINamesFlat=$(echo ${fMRINames} | sed 's/[@%]/ /g')

			for fMRIName in ${fMRINamesFlat}; do
				echo "  ${fMRIName}"

				InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"

				cmd=("${queuing_command[@]} ${DEPENDENCY}" "${FixScript}" "${InputFile}" ${bandpass} ${domot} "${TrainingData}" ${FixThreshold} "${DeleteIntermediates}")
				echo "About to run: ${cmd[*]}"
				jobidICAFIX=`${cmd[@]}`
                                echo "$jobidICAFIX : $Subject" >> $ICAjs
			done

		else
        	#need arrays to sanity check number of concat groups
        	IFS=' @' read -a concatarray <<< "${ConcatNames}"
        	IFS=% read -a fmriarray <<< "${fMRINames}"

        	if ((${#concatarray[@]} != ${#fmriarray[@]})); then
        	    echo "ERROR: number of names in ConcatNames does not match number of fMRINames groups"
        	    exit 1
        	fi

		    for ((i = 0; i < ${#concatarray[@]}; ++i))
		    do
					echo "test_5"
				ConcatName="${concatarray[$i]}"
				fMRINamesGroup="${fmriarray[$i]}"
				# multi-run FIX
				FixScript=${HCPPIPEDIR}/ICAFIX/hcp_fix_multi_run
				ConcatFileName="${ResultsFolder}/${ConcatName}/${ConcatName}"

				IFS=' @' read -a namesgrouparray <<< "${fMRINamesGroup}"
				InputFile=""
				echo "test_6"
				for fMRIName in "${namesgrouparray[@]}"; do
					if [[ "$InputFile" == "" ]]; then
						InputFile="${ResultsFolder}/${fMRIName}/${fMRIName}"
					else
						InputFile+="@${ResultsFolder}/${fMRIName}/${fMRIName}"
					fi
				done

				echo "  InputFile: ${InputFile}"

				echo "original command: ("${queuing_command[@]}" "${FixScript}" "${InputFile}" ${bandpass} "${ConcatFileName}" ${domot} "${TrainingData}" ${FixThreshold} "${DeleteIntermediates}")"
				cmd=("${queuing_command[@]}" "${FixScript}" "${InputFile}" ${bandpass} "${ConcatFileName}" ${domot} "${TrainingData}" ${FixThreshold} "${DeleteIntermediates}")
				echo "test_8"
				echo "About to run: ${cmd[*]}"
				"${cmd[@]}"
			done

		fi

	done

echo "$jobidICAFIX" > ${BS}/jobidICAFIXpipe &

}  # main()

#
# Invoke the main function to get things started
#
main $@

echo -e "\n${script_name} finished.\n"
