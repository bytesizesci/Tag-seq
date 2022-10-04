#!/bin/bash
#SBATCH --job-name=tagQC
#SBATCH --ntasks=1 # Number of cores/threads
#SBATCH --mem=2000 # Ram in Mb
#SBATCH --partition=high 
#SBATCH --time=0-00:30:00
#SBATCH -o /home/kristen1/22projects/DOProgenitor/config/tag-seq-QC-%A_%a.out
#SBATCH -e /home/kristen1/22projects/DOProgenitor/config/tag-seq-QC-%A_%a.err

##########################################################################################
# Original Author: Ben Laufer
# Email: blaufer@ucdavis.edu 
#
# Adapted by: Kristen James
# Email: krijames@ucdavis.edu
# Lab: Bennett Lab, USDA-ARS WHNRC
# Date: 10/03/2022
##########################################################################################

###################
# Run Information #
###################

start=`date +%s`

hostname

THREADS=${SLURM_NTASKS}
MEM=$(expr ${SLURM_MEM_PER_CPU} / 1024)

echo "Allocated threads: " $THREADS
echo "Allocated memory: " $MEM

################
# Load Modules #
################

module load multiqc/bio3

###########
# MultiQC #
###########

call="multiqc ."
#. \
# --config multiqc_config.yaml"

echo $call
eval $call

########
# Copy #
########

mkdir GeneCounts
"$(find `.` -name '*ReadsPerGene.out.tab' -print0 | xargs -0 cp -t GeneCounts)"

###################
# Run Information #
###################

end=`date +%s`
runtime=$((end-start))
echo $runtime
