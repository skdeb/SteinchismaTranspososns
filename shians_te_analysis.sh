#!/bin/bash
#SBATCH -n 20
#SBATCH -p ultrahigh
#SBATCH --qos mrmckain
#SBATCH -N 1
#SBATCH --mem=100G
#SBATCH -o slurm_output.%J
#SBATCH -e slurm_error.%J
#SBATCH --mail-type=ALL
#SBATCH --mail-user=skdeb@uahpc.ua.edu

module load java/1.8.0
module load bio/bowtie/2.3
export PATH=$PATH:/mrm/bin/parallel-20211022/:/mrm/bin/parallel-20211022/bin:/mrm/bin/parallel-20211022/share

##########################
# The scirpt was originally wrote by Nate Hofford (MS student, McKain Lab). Modified for this analysis by me (Sontosh Deb).
########################
#STEP 1
# Trimming illumina reads. done seperately.using Trimmomatic
# FASTQC before and after trimming reads. done seperatly.
#########################
# STEP 2
# Make bowtie index for organellar genome
###################################

cd $(pwd)/2_organelle
bowtie2-build organelle_genomes.fasta organelle_genomes
cd ../
##########
# STEP 3 #
##########
# Removal of organellar and contaminated reads
ids="/scratch/skdeb/shians_transposome/analysis_5_16_23/ids.txt"
# Make overall bowtie directory
mkdir 3_Bowtie
cd 3_Bowtie

# Make bowtie directory for organellar reads removal
mkdir 3a_Organellar
cd 3a_Organellar
# Bowtie call to remove organellar reads
cat $ids | parallel -j 1 "bowtie2 --very-sensitive-local --quiet --un {}.UP_pass.fq --un-conc {}.PE_pass.fq --al {}.UP_fail.fq --al-conc {}.PE_fail.fq -p 1 -x /scratch/skdeb/shians_transposome/analysis_5_16_23/2_organelle/organelle_genomes -1 /scratch/skdeb/shians_transposome/data/trimmed/{}_R1.fastq -2 /scratch/skdeb/shians_transposome/data/trimmed/{}_R2.fastq -S {}.sam"
cd ../

# Make bowtie directory for fungal contamination removal
mkdir 3b_Fungal
cd 3b_Fungal
# Bowtie call to remove fungal contaminated read
cat $ids | parallel -j 1 "bowtie2 --very-sensitive-local --quiet --un {}.UP_pass_fun.fq --un-conc {}.PE_pass_fun.fq --al {}.UP_fail_fun.fq --al-conc {}.PE_fail_fun.fq -p 1 -x /scratch/mrmckain/TE_pipeline/Bowtie_data/Fungal_Test/Fungal_bowtie -1 ../3a_Organellar/{}.PE_pass.1.fq -2 ../3a_Organellar/{}.PE_pass.2.fq -S {}_fun.sam"
cd ../

# Make bowtie directory for bacterial contamination removal
mkdir 3c_Bacterial
cd /scratch/skdeb/shians_transposome/analysis_5_16_23/3_Bowtie/3c_Bacterial
# Bowtie call to remve bacterial contamination

cat $ids | parallel -j 1 "bowtie2 --very-sensitive-local --quiet --un {}.UP_pass_clean.fq --un-conc {}.PE_pass_clean.fq --al {}.UP_fail_clean.fq --al-conc {}.PE_fail_clean.fq -p 20 -x /mrm/bin/Bacterial_Genome_DB/NCBI_Bacterial_bowtie -1 ../3b_Fungal/{}.PE_pass_fun.1.fq -2 ../3b_Fungal/{}.PE_pass_fun.2.fq -S {}_bact.sam"
cd ../../


##########
# STEP 4 #
##########
# Deduplication of decontaminated reads
# Make deduplication directory
mkdir 4_Deduplication
cd 4_Deduplication
# Nubeamdedup call
# Note that '-r 1' indicates I want the removed duplicates saved to files
cat $ids | parallel -j 1 "/mrm/bin/nubeamdedup-master/Linux/nubeam-dedup -i1 ../3_Bowtie/3c_Bacterial/{}.PE_pass_clean.1.fq -i2 ../3_Bowtie/3c_Bacterial/{}.PE_pass_clean.2.fq -r 1"
cd ../


##########
# Interleave files for running on Transposome
# Make interleaved directory
mkdir 5_Interleaved
cd 5_Interleaved
# Copy both decontaminated/non-deduplicated and decontaminated/deduplicated fastq files
# We are interested in checking the effect of deduplicated on the transposome run
# Path to decontaminated/deduplicated reads
cp ../4_Deduplication/*uniq.fastq .
# Path to decontaminated/non-deduplicated reads
cat $ids | parallel -j 1 "cp ../3_Bowtie/3c_Bacterial/{}.PE_pass_clean.*.fq ."
# Rename deduplicated files from fastq to fq
cat $ids | parallel -j 1 "mv {}.PE_pass_clean.1.uniq.fastq {}.PE_pass_clean.1.uniq.fq"
cat $ids | parallel -j 1 "mv {}.PE_pass_clean.2.uniq.fastq {}.PE_pass_clean.2.uniq.fq"
# Non-deduplicated reads
cat $ids | parallel -j 1 "perl /mrm/bin/fastq2fasta_interleaved.pl {}.PE_pass_clean.1.fq {}.PE_pass_clean.2.fq"
# Deduplicated reads
cat $ids | parallel -j 1 "perl /mrm/bin/fastq2fasta_interleaved.pl {}.PE_pass_clean.1.uniq.fq {}.PE_pass_clean.2.uniq.fq"

#rm *fq
cd ../


##########
# STEP 6 #
##########
# Run Transposome on prepped reads
# Make Transposome overarching directory
mkdir 6_Transposome
cd 6_Transposome
# Directory for cleaned and deduplicated transposome outut
mkdir 6a_CleanDedup
cd 6a_CleanDedup
# Copy interleaved file to transposome directory
cp ../../5_Interleaved/*.PE_pass_clean.1.uniq.fasta .
# Transposome multiple runs call
cat $ids | parallel -j 1 "perl /scratch/mrmckain/TE_pipeline/Scripts/Transposome/transposome_multiple_runs.pl {}.PE_pass_clean.1.uniq.fasta {}"

