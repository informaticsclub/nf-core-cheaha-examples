#!/bin/bash
#SBATCH --job-name=fetchngs
#SBATCH --output=fetchngs_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --partition=express,short

module purge
module load Singularity
module load Nextflow

nextflow run nf-core/fetchngs \
    -r 1.12.0 \
    -profile cheaha \
    --input ids.csv \
    --outdir results \
    --nf_core_pipeline rnaseq \
    --download_method ftp
