#!/bin/bash
#
#SBATCH --job-name=tag-seq
#SBATCH --ntasks=8 # Number of cores/threads
#SBATCH --mem=32000 # Ram in Mb
#SBATCH --partition=high
#SBATCH --time=0-00:30:00
#SBATCH -o /home/kristen1/22projects/DOProgenitor/config/tag-seq-%A_%a.out
#SBATCH -e /home/kristen1/22projects/DOProgenitor/config/tag-seq-%A_%a.err

##########################################################################################
# Original Author: Ben Laufer
# Email: blaufer@ucdavis.edu 
# Modified from: https://www.lexogen.com/quantseq-data-analysis/
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

#######################
# Load Modules        #
# check Farm versions #
#######################

module load samtools/1.9
module load fastqc/0.11.9
module load bbmap/38.60
module load star/2.6.1a

######################
# Set Up Environment #
######################

directory=${PWD}/
sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" task_samples.txt`
rawpath=${directory}raw_sequences/
mappath=${directory}${sample}
fastq=${rawpath}${sample}.fastq.gz
trim=${sample}_trimmed.fastq.gz
BAM=${sample}_Aligned.sortedByCoord.out.bam

#############
# QC Report #
#############
# adjust threads

mkdir -p QC # make folder QC, nested, and only if it doesn't exist

call="fastqc \
--outdir QC \
--format fastq \
--threads 8 \
${fastq}"

echo $call
eval $call

########
# Trim #
########
# polyA file workaround: https://www.biostars.org/p/236515/
# Added stats for multiQC: https://multiqc.info/docs/#bbmap

mkdir ${mappath}
cd ${mappath}

call="bbduk.sh \
in=${fastq} \
out=${trim} \
ref=${directory}data/truseq_rna.fa.gz \
literal=AAAAAAAAAAAAAAAAAA \
k=13 \
ktrim=r \
useshortkmers=t \
mink=5 \
qtrim=r \
trimq=10 \
minlength=20 \
stats=${sample}_stats"

echo $call
eval $call

#########
# Align #
#########
# adjust threads and genome directory
# Use zcat command for fastq.gz https://www.biostars.org/p/243683/
# Use qauntMode to get GeneCounts for R https://www.biostars.org/p/218995/

call="STAR \
--runThreadN 8 \
--genomeDir /share/lasallelab/Ben/PEBBLES/tag-seq/data/GRCm38/star_100/ \
--readFilesIn ${trim} \
--readFilesCommand zcat \
--outFilterType BySJout \
--outFilterMultimapNmax 20 \
--alignSJoverhangMin 8 \
--alignSJDBoverhangMin 1 \
--outFilterMismatchNmax 999 
--outFilterMismatchNoverLmax 0.1 \
--alignIntronMin 20 \
--alignIntronMax 1000000 \
--alignMatesGapMax 1000000 \
--outSAMattributes NH HI NM MD \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix ${sample}_ \
--quantMode GeneCounts"

echo $call
eval $call

#########
# Index #
#########
# Indexed bam files are necessary for many visualization and downstream analysis tools

call="samtools \
index \
${BAM}"

echo $call
eval $call

###################
# Run Information #
###################

end=`date +%s`
runtime=$((end-start))
echo $runtime
