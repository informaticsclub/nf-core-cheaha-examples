#!/bin/bash
# Install a specific version of Nextflow locally.
# The Cheaha Nextflow module (21.08.0) is too old for nf-core/fetchngs 1.12.0.

export NXF_VER=24.10.4

module load Java

curl -s https://get.nextflow.io | bash

echo "Installed ./nextflow version $(./nextflow -version 2>&1 | grep -oP '[\d.]+')"
