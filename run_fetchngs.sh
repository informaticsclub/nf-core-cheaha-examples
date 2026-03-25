#!/bin/bash
#SBATCH --job-name=fetchngs
#SBATCH --output=logs/fetchngs_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --partition=express,short

mkdir -p logs

module load Singularity
module load Java

./nextflow -log logs/nextflow.log run nf-core/fetchngs \
    -r 1.12.0 \
    -c cheaha.config \
    -params-file params.yml
