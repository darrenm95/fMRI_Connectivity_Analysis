#!/bin/bash 
#
# # Struc_and_fMRI_Pipeline.sh
#
# # Structural and Functional Pipelines
#
# ## Description
#
# Structural and functional pipelines is a set of commands that 
# call various scripts to process a subjects structural and 
# functional MRI data.
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
#   Location of shared sub-scripts that are used to carry out some of the
#   steps of the PreFreeSurfer pipeline and are also used to carry out
#   some steps of other pipelines.
#
# * FSLDIR
#
#   Home directory for [FSL][FSL] the FMRIB Software Library from Oxford
#   University
#
# * FREESURFER_HOME
#
# * CARET7DIR
# 
# * PATH (for gradient_unwarp.py)
#
# * hcp-pipelines-img module file
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
echo "PreFSjs=$PreFSjs"
echo "FSjs=$FSjs"
echo "PostFSjs=$PostFSjs"
echo "fMRIVjs=$fMRIVjs"
echo -e "fMRISjs=$fMRISjs\n"

if [[ -z "${SF}" ]]; then
  echo "${script_name}: ABORTING: SF variable must be set"
  exit 1
fi

if [[ -z "${SubIdStr}" ]]; then
  echo "${script_name}: ABORTING: SubIdStr variable must be set"
  exit 1
fi

if [[ -z "${PreFSjs}" ]]; then
  echo "${script_name}: ABORTING: PreFSjs variable must be set"
  exit 1
fi

if [[ -z "${FSjs}" ]]; then
  echo "${script_name}: ABORTING: FSjs variable must be set"
  exit 1
fi

if [[ -z "${PostFSjs}" ]]; then
  echo "${script_name}: ABORTING: PostFSjs variable must be set"
  exit 1
fi

if [[ -z "${fMRIVjs}" ]]; then
  echo "${script_name}: ABORTING: fMRIVjs variable must be set"
  exit 1
fi

if [[ -z "${fMRISjs}" ]]; then
  echo "${script_name}: ABORTING: fMRISjs variable must be set"
  exit 1
fi


for SUBJECT_ID in $SubIdStr; do
 
  SubDTS=${SF}/${SUBJECT_ID}/${DTS}

  if [[ -e "$SubDTS" ]]; then

    echo -e "$SUBJECT_ID has already been processed through the structural and" \
            "functional pipelines. Removing id from string of id's that are to" \
            "be processed\n"
    SubIdStr=${SubIdStr/$SUBJECT_ID/}
    if [[ -z "${SubIdStr}" ]]; then
      echo -e "${script_name}: ABORTING: no remaining subjects to be processed" \
              "in SubIdStr"
      exit 1
    fi
  fi
done

# ------------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------------

Usage() {
  echo -e "`basename $0`: Script runs the following steps from the HCP pipeline:" \
          "PreFreeSurfer; FreeSurfer; PostFreeSurfer; fMRIVolume; fMRISurface "
  echo "Usage: `basename $0` --parameterFile=<InputParameterFile.sh>"
  echo "             [--EnvScript=<SetUpHCPPipeline.sh>]"
  echo -e "             [--startat=<use if you want to start the pipeline at a later" \
          "stage; set to the one of the following:>"
  echo "                        <freesurfer> <postfreesurfer> <fMRIVolume> <fMRISurface>] "
  echo -e "       where <InputParameterFile.sh> contains input parameters and correct" \
          "paths to directories"
  echo -e "       where <SetUpHCPPipeline.sh> can be set when you do not want to use" \
          "the paths that are predefined in the script"
}

# function for parsing options
getopt1() {
  sopt="$1"
  shift 1
    for fn in $@ ; do
      if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
	echo $fn | sed "s/^${sopt}=//"
	return 0
      fi
    done
}

# ------------------------------------------------------------------------------------
# INPUTS
# ------------------------------------------------------------------------------------

# Just give usage if no arguments specified
if [ $# -eq 0 ] ; then Usage; exit 0; fi

# parse arguments
InputParameterFile=`getopt1 "--parameterFile" $@`  # "$1" #Path to InputParameterFile
EnvironmentScript=`getopt1 "--EnvScript" $@`  # "$2" #Environment script
startat=`getopt1 "--startat" $@`

# Default parameters
SetPreFreeSurfer=0
SetFreeSurfer=0
SetPostFreeSurfer=1
SetfMRIVolume=1
SetfMRISurface=1

# Check which parts of the pipeline need to be run/skipped
if [[  $startat == "freesurfer" ]] ; then
  echo "Start the pipeline from the Freesurfer part"
  SetPreFreeSurfer=0

elif [[ $startat == "postfreesurfer" ]] ; then
  echo "Start the pipeline from the PostFreesurfer part"
  SetPreFreeSurfer=0
  SetFreeSurfer=0

elif [[ $startat == "fMRIVolume" ]] ; then
  echo "Start the pipeline from the fMRIVolume part"
  SetPreFreeSurfer=0
  SetFreeSurfer=0
  SetPostFreeSurfer=0

elif [[ $startat == "fMRISurface" ]] ; then
  echo "Start the pipeline from the fMRISurface part"
  SetPreFreeSurfer=0
  SetFreeSurfer=0
  SetPostFreeSurfer=0
  SetfMRIVolume=0

else
  echo "Run the whole pipeline"
fi
  
# Importing input variables from the InputParameterFile.sh
if [[ ${InputParameterFile} && ${InputParameterFile-_} ]] ; then
  source ${InputParameterFile}
else
  echo "There is no input file"
  exit 1
fi

# Log the originating call
echo "$@"

if [[ X$SGE_ROOT != X ]] ; then
  QUEUE="-q long.q"
fi

PRINTCOM=""            # use ="echo" for just printing everything and
#PRINTCOM="echo"       # not running the commands (default is to run, ="")

# set directory for output files
if [ ! -d "log_files" ] ; then
  mkdir  log_files
fi

# Default values of cluster job IDs
jobidPreFreeSurfer="-1"
jobidFreeSurfer="-1"
jobidPostFreeSurfer="-1"
jobidfMRIVolume="-1"
jobidfMRISurface="-1"

# ------------------------------------------------------------------------------------
# EXECUTION
# ------------------------------------------------------------------------------------

for Subject in $Subjlist ; do
  echo "Subject " $Subject
  
  ###### PreFreeSurfer #####

  #Change input image filenames in the case they have "subject ID" in the filename (replace wildcard %subjectID% with actual ID) 
  T1wInputImage="${T1wInputImages}"
  T1wInputImages=`echo ${T1wInputImages} | sed 's/@/ /g'`
  for Tmp in ${T1wInputImages} ; do
    Tt="${StudyFolder}/${Subject}/${Tmp}"
    T1wInputImage=`echo ${T1wInputImage} | sed "s%${Tmp}%${Tt}%"`
  done
  T1wInputImage="`echo ${T1wInputImage} | sed s/%subjectID%/${Subject}/g`"

  if [ ! $FmapMagnitudeInputName = "NONE" ] ; then
    MagnitudeInputName="${StudyFolder}/${Subject}/`echo ${FmapMagnitudeInputName} | sed s/%subjectID%/${Subject}/g`"   #Expects 4D magnitude volume with two 3D timepoints or "NONE" if not used
  fi
  if [ ! $FmapPhaseInputName = "NONE" ] ; then
    PhaseInputName="${StudyFolder}/${Subject}/`echo ${FmapPhaseInputName} | sed s/%subjectID%/${Subject}/g`" #Expects 3D phase difference volume or "NONE" if not used
  fi
  # For T2 (if it exists) 
  if [ ! $T2wInputImages = "NONE" ] ; then
    T2wInputImage="${T2wInputImages}"
    T2wInputImages=`echo ${T2wInputImages} | sed 's/@/ /g'`
    for Tmp in ${T2wInputImages} ; do
      Tt="${StudyFolder}/${Subject}/${Tmp}"
      T2wInputImage=`echo ${T2wInputImage} | sed "s%${Tmp}%${Tt}%"`
    done
    T2wInputImage="`echo ${T2wInputImage} | sed s/%subjectID%/${Subject}/g`"
  else
    T2wInputImage="NONE"
    T2wTemplate="NONE" 
    T2wTemplateBrain="NONE" 
    T2wTemplate2mm="NONE" 
    T2wSampleSpacing="NONE" 
  fi

  if [ $SetPreFreeSurfer == 1 ] ; then
    jobidPreFreeSurfer=`${FSLDIR}/bin/fsl_sub ${QUEUE} -l ./log_files \
	                ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
	                --path="$StudyFolder" \
	                --subject="$Subject" \
	                --t1="$T1wInputImage" \
	                --t2="$T2wInputImage" \
	                --t1template="$T1wTemplate" \
	                --t1templatebrain="$T1wTemplateBrain" \
	                --t1template2mm="$T1wTemplate2mm" \
	                --t2template="$T2wTemplate" \
	                --t2templatebrain="$T2wTemplateBrain" \
	                --t2template2mm="$T2wTemplate2mm" \
	                --templatemask="$TemplateMask" \
	                --template2mmmask="$Template2mmMask" \
	                --brainsize="$BrainSize" \
	                --fnirtconfig="$FNIRTConfig" \
	                --fmapmag="$MagnitudeInputName" \
	                --fmapphase="$PhaseInputName" \
	                --echospacing="$TE" \
	                --t1samplespacing="$T1wSampleSpacing" \
	                --t2samplespacing="$T2wSampleSpacing" \
	                --unwarpdir="$UnwarpDir" \
	                --gdcoeffs="$GradientDistortionCoeffs" \
	                --avgrdcmethod="$AvgrdcMethod" \
	                --topupconfig="$TopupConfig" \
	                --printcom=$PRINTCOM`
      
    echo "$jobidPreFreeSurfer : $Subject" >> $PreFSjs

    # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
    echo "### PreFreeSurfer ###"
    echo "set -- --path=${StudyFolder} \ 
                        --subject=${Subject} \ 
                        --t1=${T1wInputImage} \ 
                        --t2=${T2wInputImage} \  
                        --t1template=${T1wTemplate} \ 
                        --t1templatebrain=${T1wTemplateBrain} \ 
                        --t1template2mm=${T1wTemplate2mm} \ 
                        --t2template=${T2wTemplate} \ 
                        --t2templatebrain=${T2wTemplateBrain} \ 
                        --t2template2mm=${T2wTemplate2mm} \ 
                        --templatemask=${TemplateMask} \ 
                        --template2mmmask=${Template2mmMask} \ 
                        --brainsize=${BrainSize} \ 
                        --fnirtconfig=${FNIRTConfig} \ 
                        --fmapmag=${MagnitudeInputName} \ 
                        --fmapphase=${PhaseInputName} \ 
                        --echospacing=${TE} \ 
                        --t1samplespacing=${T1wSampleSpacing} \ 
                        --t2samplespacing=${T2wSampleSpacing} \ 
                        --unwarpdir=${UnwarpDir} \ 
                        --gdcoeffs=${GradientDistortionCoeffs} \ 
                        --avgrdcmethod=${AvgrdcMethod} \ 
                        --topupconfig=${TopupConfig} \ 
                        --printcom=${PRINTCOM}"

    echo ". ${EnvironmentScript}"     
  fi

  ###### FreeSurfer #####


  #Input Variables (created in the PreFreesurfer step)
  SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution), the script will check if it exists or not

  if [ $SetFreeSurfer == 1 ] ; then
    jobidFreeSurfer=`${FSLDIR}/bin/fsl_sub ${QUEUE} -l ./log_files \
	                -j $jobidPreFreeSurfer \
	                ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
	                --subject="$Subject" \
	                --subjectDIR="$SubjectDIR" \
	                --t1="$T1wImage" \
	                --t1brain="$T1wImageBrain" \
	                --t2="$T2wImage" \
	                --printcom=$PRINTCOM`

    echo "$jobidFreeSurfer : $Subject" >> $FSjs
      
  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo "### Freesurfer ###"
  echo "set -- --subject="$Subject" \ 
                        --subjectDIR="$SubjectDIR" \ 
                        --t1="$T1wImage" \ 
                        --t1brain="$T1wImageBrain" \ 
                        --t2="$T2wImage" \ 
                        --printcom=$PRINTCOM"
  fi


  ###### PostFreeSurfer #####
  

  if [ $SetPostFreeSurfer == 1 ] ; then
    jobidPostFreeSurfer=`${FSLDIR}/bin/fsl_sub ${QUEUE} -l ./log_files \
	                -j $jobidFreeSurfer \
	                ${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
	                --path="$StudyFolder" \
	                --subject="$Subject" \
	                --surfatlasdir="$SurfaceAtlasDIR" \
	                --grayordinatesdir="$GrayordinatesSpaceDIR" \
	                --grayordinatesres="$GrayordinatesResolution" \
	                --hiresmesh="$HighResMesh" \
	                --lowresmesh="$LowResMesh" \
	                --subcortgraylabels="$SubcorticalGrayLabels" \
	                --freesurferlabels="$FreeSurferLabels" \
	                --refmyelinmaps="$ReferenceMyelinMaps" \
	                --printcom=$PRINTCOM`

    echo "$jobidPostFreeSurfer : $Subject" >> $PostFSjs

    # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...    
    echo  "### PostFreesurfer ###"
    echo "set -- --path="$StudyFolder" \ 
                        --subject="$Subject" \ 
                        --surfatlasdir="$SurfaceAtlasDIR" \ 
                        --grayordinatesdir="$GrayordinatesSpaceDIR" \ 
                        --grayordinatesres="$GrayordinatesResolution" \ 
                        --hiresmesh="$HighResMesh" \ 
                        --lowresmesh="$LowResMesh" \ 
                        --subcortgraylabels="$SubcorticalGrayLabels" \ 
                        --freesurferlabels="$FreeSurferLabels" \ 
                        --refmyelinmaps="$ReferenceMyelinMaps" \ 
                        --printcom=$PRINTCOM"
  fi
 
       #########  fMRI  #########

  for fMRIName in $Tasklist ; do

    #####  fMRI Volume #####
    fMRITimeSer="${StudyFolder}/${Subject}/`echo ${fMRITimeSeries} | sed s/%TaskName%/${fMRIName}/g  | sed s/%subjectID%/${Subject}/g`"

    if  [ ! $fMRISBRef = "NONE" ] ; then  
      fMRISBRefe="${StudyFolder}/${Subject}/`echo ${fMRISBRef} | sed s/%TaskName%/${fMRIName}/g  | sed s/%subjectID%/${Subject}/g`"
    fi
    
    if [ ! $FmapMagnitudeInputNameForFUNC = "NONE" ] ; then   
      MagnitudeInputNameForFUNC="${StudyFolder}/${Subject}/`echo ${FmapMagnitudeInputNameForFUNC} | sed s/%TaskName%/${fMRIName}/g | sed s/%subjectID%/${Subject}/g`" 
    fi
    
    if [ ! $FmapPhaseInputNameForFUNC = "NONE" ] ; then
      PhaseInputNameForFUNC="${StudyFolder}/${Subject}/`echo ${FmapPhaseInputNameForFUNC} | sed s/%TaskName%/${fMRIName}/g | sed s/%subjectID%/${Subject}/g`" 
    fi  

    if [ ! $SpinEchoPhaseEncodeNegative = "NONE" ] ; then
      SpinEchoPhaseEncodeNegat="${StudyFolder}/${Subject}/`echo ${SpinEchoPhaseEncodeNegative} | sed s/%TaskName%/${fMRIName}/g  | sed s/%subjectID%/${Subject}/g`"
    fi

    if [ ! $SpinEchoPhaseEncodePositive = "NONE" ] ; then
      SpinEchoPhaseEncodePosit="${StudyFolder}/${Subject}/`echo ${SpinEchoPhaseEncodePositive} | sed s/%TaskName%/${fMRIName}/g  | sed s/%subjectID%/${Subject}/g`"
    fi


    if [ $SetfMRIVolume == 1 ] ; then
      jobidfMRIVolume=`${FSLDIR}/bin/fsl_sub $QUEUE -l ./log_files \
                          -j $jobidPostFreeSurfer \
                          ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
                          --path=$StudyFolder \
                          --subject=$Subject \
                          --fmriname=$fMRIName \
                          --fmritcs=$fMRITimeSer \
                          --fmriscout=$fMRISBRefe \
                          --SEPhaseNeg=$SpinEchoPhaseEncodeNegat \
                          --SEPhasePos=$SpinEchoPhaseEncodePosit \
                          --fmapmag=$MagnitudeInputNameForFUNC \
                          --fmapphase=$PhaseInputNameForFUNC \
                          --echospacing=$DwellTime \
                          --echodiff=$DeltaTE \
                          --unwarpdir=$UnwarpdirForFUNC \
                          --fmrires=$FinalFMRIResolution \
                          --dcmethod=$DistortionCorrection \
                          --gdcoeffs=$GradientDistortionCoeffsForFUNC \
                          --topupconfig=$TopUpConfigForFUNC \
                          --printcom=$PRINTCOM`

    echo "$jobidfMRIVolume : $Subject" >> $fMRIVjs
	  
      # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
      echo  "### fMRI Volume  ###"
      echo "set ----path=$StudyFolder \ 
                          --subject=$Subject \ 
                          --fmriname=$fMRIName \ 
                          --fmritcs=$fMRITimeSer \ 
                          --fmriscout=$fMRISBRefe \ 
                          --SEPhaseNeg=$SpinEchoPhaseEncodeNegat \ 
                          --SEPhasePos=$SpinEchoPhaseEncodePosit \ 
                          --fmapmag=$MagnitudeInputNameForFUNC \ 
                          --fmapphase=$PhaseInputNameForFUNC \ 
                          --echospacing=$DwellTime \ 
                          --echodiff=$DeltaTE \ 
                          --unwarpdir=$UnwarpdirForFUNC \ 
                          --fmrires=$FinalFMRIResolution \ 
                          --dcmethod=$DistortionCorrection \ 
                          --gdcoeffs=$GradientDistortionCoeffsForFUNC \ 
                          --topupconfig=$TopUpConfigForFUNC \ 
                          --printcom=$PRINTCOM"
      fi

      ##### fMRI Surface #####

      if [ $SetfMRISurface == 1 ] ; then   
	jobidfMRISurface=`${FSLDIR}/bin/fsl_sub $QUEUE -l ./log_files \
                          -j $jobidfMRIVolume \
	                  ${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh \
	                  --path=$StudyFolder \
	                  --subject=$Subject \
	                  --fmriname=$fMRIName \
	                  --lowresmesh=$LowResMesh \
	                  --fmrires=$FinalFMRIResolutio \
	                  --smoothingFWHM=$SmoothingFWHM \
	                  --grayordinatesres=$GrayordinatesResolution`

        jobidfMRISurfaceStr+="[\"$Subject\"]=\"$jobidfMRISurface\" " 
        echo "$jobidfMRISurface : $Subject" >> $fMRISjs
        # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
	echo "### fMRI Surface ###"
	echo "set -- --path=$StudyFolder \ 
                          --subject=$Subject \ 
                          --fmriname=$fMRIName \ 
                          --lowresmesh=$LowResMesh \ 
                          --fmrires=$FinalFMRIResolution \ 
                          --smoothingFWHM=$SmoothingFWHM \ 
                          --grayordinatesres=$GrayordinatesResolution"
	  
      fi
  done
done


tmp="$jobidfMRISurfaceStr"
tmp="$(echo -e "${tmp}" | sed -e 's/[[:space:]]*$//')"
jobidfMRISurfaceStr="$tmp"
unset tmp

echo $jobidfMRISurfaceStr > ${BS}/jobidfMRISurfaceStrPipe &

echo -e "\n${script_name} finished.\n"
