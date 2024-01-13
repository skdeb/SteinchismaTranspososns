#!/bin/bash
#SBATCH -n 4
#SBATCH -p ultrahigh
#SBATCH --qos mrmckain
#SBATCH -N 1
#SBATCH --mem=25G


# This script summarize outputs from each sample and count the average and standard deviation of each TE elements identified by transoposome software.

dir_id=$1 # ids of the sample directories in a txt file
out_pref=$2 # use any prefix to have with the output file name

perl /mrm/bin/Transposome_Scripts/pull_annotations_transposome_average.pl $1 $2 
