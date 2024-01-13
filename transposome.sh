#!/bin/bash
#SBATCH -n 4
#SBATCH -p ultrahigh
#SBATCH --qos=mrmckain
#SBATCH -N 1
#SBATCH --mem=100G

export DK_ROOT=/share/apps/dotkit
. /share/apps/dotkit/bash/.dk_init


module load bio/transposome/0.12.1  

#$1 --> BASE_transposome_config.yml file

transposome --config $1
