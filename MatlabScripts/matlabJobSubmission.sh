#!/bin/bash

#SWATCH --mail-type=END                         
#SBATCH --mail-user=ian.wiggins@nottingham.ac.uk
#SBATCH --partition=imgcomputeq
#SBATCH --qos=img
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=12g
#SBATCH --time=120:00:00

export MODULEPATH=/gpfs01/software/imaging/modulefiles:$MODULEPATH
module load connectome-uon/workbench-1.3.2 
module load matlab-uon/r2019b 
module load fsl-img/6.0.2

Script_name='FSLNetsAnalysis'
fCA='/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis'

# Redirect script input and output to files
exec > "${fCA}/log_files/${Script_name}.o$(date +%d-%m-%Y_%R)"
exec 2>"${fCA}/log_files/${Script_name}.e$(date +%d-%m-%Y_%R)"

MS='/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/MatlabScripts'
matlab -nodisplay -nodesktop  -r "run $(printf '%s/%s.m' $MS $Script_name);exit;" 
