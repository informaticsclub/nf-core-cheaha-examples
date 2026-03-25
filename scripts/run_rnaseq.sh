#!/bin/bash
#SBATCH --job-name=rnaseq
#SBATCH --output=logs/rnaseq_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=48:00:00
#SBATCH --partition=short,medium,long

# Resolve paths relative to repo root regardless of where sbatch is called
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

module load Singularity
module load Java

./nextflow -log logs/nextflow_rnaseq.log run nf-core/rnaseq \
    -r 3.23.0 \
    -c conf/cheaha.config \
    -params-file params.rnaseq.yml
