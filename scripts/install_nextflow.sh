#!/bin/bash
# Install a compatible version of Nextflow locally.
# The Cheaha Nextflow module (v21.08.0) is too old for current nf-core pipelines.
#
# Best practice: If you plan to use Nextflow across multiple projects,
# install it to ~/bin instead so it is on your $PATH everywhere:
#
#   mkdir -p ~/bin && cd ~/bin
#   export NXF_VER=24.10.4 && curl -s https://get.nextflow.io | bash
#
# Then you can use 'nextflow' directly instead of './nextflow'.

export NXF_VER=24.10.4

module load Java

curl -s https://get.nextflow.io | bash

# Create logs directory 
# SLURM needs it to exist before running pipeline jobs
mkdir -p logs

echo "Installed ./nextflow version $(./nextflow -version 2>&1 | grep -oP '[\d.]+')"
