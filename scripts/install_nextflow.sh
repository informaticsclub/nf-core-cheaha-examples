#!/bin/bash
#
# Install Nextflow into the current directory.
#
# The Cheaha Nextflow module (v21.08.0) is too old for current nf-core
# pipelines. This script installs a compatible version locally as
# ./nextflow.  Run it once from the repo root.
#
# Best practice for multiple projects:
#   Install to ~/bin so nextflow is on your $PATH everywhere:
#
#     mkdir -p ~/bin && cd ~/bin
#     export NXF_VER=25.10.4 && curl -s https://get.nextflow.io | bash
#

export NXF_VER=25.10.4

module load Java

curl -s https://get.nextflow.io | bash

# SLURM needs the logs/ directory to exist before any job starts,
# because --output=logs/...  is evaluated before the script body runs.
mkdir -p logs

echo "Installed ./nextflow v${NXF_VER}"
