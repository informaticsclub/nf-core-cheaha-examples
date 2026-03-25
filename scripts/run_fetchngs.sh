#!/bin/bash
#SBATCH --job-name=fetchngs
#SBATCH --output=logs/fetchngs_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --partition=express,short

# SLURM runs from the directory where sbatch was called
cd "$SLURM_SUBMIT_DIR"

module load Singularity
module load Java

./nextflow -log logs/nextflow_fetchngs.log run nf-core/fetchngs \
    -r 1.12.0 \
    -profile cheaha \
    -params-file params.fetchngs.yml
