---
title: Overview of nf-core
layout: default
nav_order: 3
---

# How nf-core Pipelines Work
{: .no_toc }

A quick intro to Nextflow and nf-core for people who haven't used them before.
{: .fs-6 .fw-300 }

<details open markdown="block">
  <summary>Table of contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

## What is Nextflow?

[Nextflow](https://www.nextflow.io/) is a workflow engine. Instead of running tools one at a time in a bash script, you define steps (called **processes**) and Nextflow figures out the order and runs them in parallel where it can.

On an HPC like Cheaha, Nextflow also:
- Submits each step as its own SLURM job
- Runs each step inside a Singularity container (so you don't install anything)
- Supports `-resume` to restart from where a failed run left off

You don't need to write Nextflow code to use nf-core pipelines.

## What is nf-core?

[nf-core](https://nf-co.re/) is a community that builds peer-reviewed bioinformatics pipelines on top of Nextflow. There are 100+ pipelines for genomics, transcriptomics, proteomics, etc.

All nf-core pipelines share the same conventions: same parameter names (`--input`, `--outdir`, `--genome`), same config system, same container setup, same output layout. Once you've used one, the rest work the same way.

## How a pipeline runs on Cheaha

Here's what actually happens when you run `sbatch scripts/run_fetchngs.sh`:

```
You (login node)
  │
  ├─ sbatch ──> SLURM allocates a node for the "head job"
  │               │
  │               ├─ Nextflow starts and reads:
  │               │    - The pipeline code (cached in ~/.nextflow/assets/)
  │               │    - Cheaha profile from nf-core/configs (Singularity + SLURM)
  │               │    - params.fetchngs.yml (your parameters)
  │               │
  │               ├─ For each pipeline step, Nextflow:
  │               │    1. Creates a unique directory under work/
  │               │    2. Stages input files (symlinks)
  │               │    3. Submits a SLURM job that runs inside a Singularity container
  │               │    4. Collects outputs when the job finishes
  │               │
  │               └─ When all steps complete:
  │                    - Copies final results to outdir (results/fetchngs/)
  │                    - Writes execution reports to pipeline_info/
  │
  └─ You check: squeue -u $USER, tail -f logs/*.log
```

The head job (8 GB, 1 CPU) just coordinates. The real work happens in the task jobs that Nextflow submits to SLURM. You'll see these in `squeue` with names like `nf-SRA_IDS_TO_RUNINFO` or `nf-STAR_ALIGN`.

## Anatomy of an nf-core pipeline

Every nf-core pipeline is a Git repository with a standard layout. Here's a simplified view using fetchngs as an example:

```
nf-core/fetchngs/
├── main.nf                    # Entry point — defines the overall workflow
├── nextflow.config            # Default parameters and config
├── workflows/
│   └── sra/
│       └── main.nf            # The actual workflow logic
├── modules/
│   ├── local/                 # Custom modules specific to this pipeline
│   │   ├── sra_ids_to_runinfo/
│   │   ├── sra_fastq_ftp/
│   │   └── sra_to_samplesheet/
│   └── nf-core/               # Shared modules from nf-core/modules
│       └── sratools/
│           └── prefetch/
├── subworkflows/              # Groups of modules chained together
├── conf/
│   ├── base.config            # Default CPU/memory/time per process
│   └── test.config            # Minimal test dataset config
├── assets/                    # Static files (schemas, logos, etc.)
├── bin/                       # Helper scripts (Python, R, etc.)
└── docs/                      # Documentation
```

### Key concepts

#### Processes

A **process** is a single step — one tool, one job. For example:

```groovy
process STAR_ALIGN {
    cpus 12
    memory '36 GB'
    time '8h'
    container 'quay.io/biocontainers/star:2.7.10a'

    input:
    tuple val(meta), path(reads)
    path index

    output:
    tuple val(meta), path("*.bam"), emit: bam

    script:
    """
    STAR --runThreadN ${task.cpus} \
         --genomeDir ${index} \
         --readFilesIn ${reads} \
         --outSAMtype BAM SortedByCoordinate
    """
}
```

Each process defines what resources it needs, what container to use, its inputs and outputs, and the shell command.

#### Modules

A module wraps a single tool as a reusable process. nf-core maintains a shared library at [nf-core/modules](https://github.com/nf-core/modules) (STAR, Salmon, FastQC, etc.), so pipelines import them instead of reimplementing.

#### Subworkflows

A subworkflow chains several modules together. For example, rnaseq has one that runs STAR alignment then Salmon quantification.

#### Channels

Channels connect processes. When one process finishes, its output goes onto a channel and the next process picks it up. Nextflow uses this to figure out what can run in parallel.

## The work directory

When a pipeline runs, Nextflow creates a `work/` directory with a subdirectory for every task execution:

```
work/
├── 3a/
│   └── f2c1d8e9b0...
│       ├── .command.sh      # The actual shell command that ran
│       ├── .command.log      # stdout + stderr
│       ├── .command.run      # SLURM submission script
│       ├── .exitcode         # Exit code (0 = success)
│       ├── SRR3192396_1.fastq.gz -> /path/to/input  # Symlinked inputs
│       └── output.bam        # Actual outputs
├── 7b/
│   └── a4e3f1c2d7...
│       └── ...
└── ...
```

When a task fails, this is where you look:

1. Find the task hash in the Nextflow log or SLURM output
2. Go to `work/<hash>/`
3. Read `.command.log` for error messages
4. Read `.command.sh` to see exactly what command ran
5. Check `.exitcode`

`work/` gets big because every intermediate file lives here (BAMs, trimmed FASTQs, etc.). A 10-sample RNA-seq run can easily use hundreds of gigabytes. Always delete it after a successful run.

## The config system

Nextflow has a layered config system. Settings are applied in order, with later sources overriding earlier ones:

```
Pipeline defaults (nextflow.config)
  └── Base config (conf/base.config)        # Default resources per process
       └── Institutional profile (-profile)  # e.g. -profile cheaha
            └── Params file (-params-file)  # Your params.fetchngs.yml
                 └── CLI flags (--outdir)   # Highest priority
```

### Parameters vs config

This is the most common point of confusion. **Parameters** (`--input`, `--genome`, `--outdir`) control what the pipeline does. You set them in a params file or on the command line. **Config** (`executor`, `singularity`, `queue`) controls how it runs on your cluster. You set it with `-profile cheaha` or `-c custom.config`.

The params file says what to analyze. The profile says how to run it.

## Containers on Cheaha

Every process runs inside a Singularity container with the exact tool version it needs. You don't install STAR, Salmon, FastQC, or anything else. The containers are downloaded automatically and cached in `~/.singularity/`.

The Cheaha profile sets Singularity to use `$USER_SCRATCH` for temp files.

## Reproducibility

This repo pins everything needed to reproduce the analysis. The pipeline versions are fixed in the run scripts (`-r 1.12.0`, `-r 3.23.0`). Software versions are locked inside the containers. Parameters are tracked in YAML files. The reference genome is specified by name (`GRCh38`).

A collaborator can clone this repo, run the same scripts, and get the same results.

## Links

- [Nextflow training](https://training.nextflow.io/)
- [nf-core tutorials](https://nf-co.re/docs/tutorials/)
- [nf-core/modules](https://github.com/nf-core/modules)
- [Nextflow patterns](https://nextflow-io.github.io/patterns/)
