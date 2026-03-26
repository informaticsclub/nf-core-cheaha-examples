#!/bin/bash
#
# Download FASTQ files from GEO/SRA using nf-core/fetchngs.
# Usage: sbatch scripts/run_fetchngs.sh
#
#SBATCH --job-name=fetchngs
#SBATCH --output=logs/fetchngs_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --partition=express,short

cd "$SLURM_SUBMIT_DIR"

module load Singularity
module load Java

# Run the fetchngs pipeline with the following parameters:
# -r 1.12.0              Pin the pipeline version
# -profile cheaha         Load Cheaha HPC config (Singularity + SLURM)
# -params-file            Read pipeline parameters from YAML file
./nextflow -log logs/nextflow_fetchngs.log \
    run nf-core/fetchngs \
    -r 1.12.0 \
    -profile cheaha \
    -params-file params.fetchngs.yml
