#!/bin/bash
#SBATCH -n 30
#SBATCH -p ultrahigh
#SBATCH --qos mrmckain
#SBATCH -N 1
#SBATCH --mem=100G
#SBATCH -o slurm_output.%J
#SBATCH -e slurm_error.%J
#SBATCH --mail-type=ALL
#SBATCH --mail-user=skdeb@uahpc.ua.edu

module load java/1.8.0
for i in *_R1.fastq.gz
do
  SAMPLE=$(echo ${i} | sed "s/_R1\.fastq\.gz//")
  #echo ${SAMPLE}_R1.fastq.gz ${SAMPLE}_R2.fastq.gz
java -classpath /mrm/bin/Fast-Plast_JG/Fast-Plast/bin/Trimmomatic-0.39/trimmomatic-0.39.jar  org.usadellab.trimmomatic.TrimmomaticPE -threads 20 ${SAMPLE}_R1.fastq.gz ${SAMPLE}_R2.fastq.gz trimmed_${SAMPLE}_R1.fastq trimmed_${SAMPLE}_U1.fastq trimmed_${SAMPLE}_R2.fastq trimmed_${SAMPLE}_U2.fastq ILLUMINACLIP:/mrm/bin/Fast-Plast/bin/Trimmomatic-0.36/adapters/TruSeq3-PE.fa:1:30:10 SLIDINGWINDOW:10:20 MINLEN:140

done
