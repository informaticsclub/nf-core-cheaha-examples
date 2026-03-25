# Understanding nf-core Pipelines

This guide explains what nf-core pipelines are, how they work, and what happens when you run one on Cheaha. It's written for people who are new to Nextflow and nf-core.

## What is Nextflow?

[Nextflow](https://www.nextflow.io/) is a workflow engine. Instead of running bioinformatics tools one at a time in a bash script, you describe your analysis as a series of **processes** connected by **channels**. Nextflow then handles:

- **Parallelism** — Running independent steps at the same time
- **Job submission** — Sending each step to SLURM as its own job
- **Resumability** — If a run fails halfway, `-resume` picks up where it left off
- **Containers** — Each step runs inside an isolated Singularity container with its own software

You don't need to write Nextflow code to use nf-core pipelines. But understanding the basics helps when troubleshooting.

## What is nf-core?

[nf-core](https://nf-co.re/) is a community project that builds and maintains **standardised, peer-reviewed bioinformatics pipelines** using Nextflow. There are 100+ pipelines covering genomics, transcriptomics, proteomics, and more.

Every nf-core pipeline follows the same conventions:

- Same parameter style (`--input`, `--outdir`, `--genome`)
- Same config system (`-profile`, `-c`, `-params-file`)
- Same container strategy (Docker/Singularity images for every tool)
- Same output structure (`results/pipeline_info/`, MultiQC reports, etc.)
- Same testing and CI infrastructure

This means once you learn how one pipeline works, the others feel familiar.

## How a pipeline runs on Cheaha

Here's what actually happens when you run `sbatch scripts/run_fetchngs.sh`:

```
You (login node)
  │
  ├─ sbatch ──> SLURM allocates a node for the "head job"
  │               │
  │               ├─ Nextflow starts and reads:
  │               │    - The pipeline code (cached in ~/.nextflow/assets/)
  │               │    - conf/cheaha.config (Singularity + SLURM settings)
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

The **head job** (8 GB, 1 CPU) is lightweight — it just orchestrates. The real compute happens in the **task jobs** that Nextflow submits to SLURM. You'll see these in `squeue` with names like `nf-SRA_IDS_TO_RUNINFO` or `nf-STAR_ALIGN`.

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

Each process defines its **resources**, **container**, **inputs**, **outputs**, and the **shell command** to run.

#### Modules

A **module** is a reusable, self-contained process. nf-core maintains a shared library of modules at [nf-core/modules](https://github.com/nf-core/modules) — tools like STAR, Salmon, FastQC, Trim Galore, etc. Pipelines import these rather than rewriting them.

#### Subworkflows

A **subworkflow** chains multiple modules together. For example, the rnaseq pipeline has a subworkflow that runs STAR alignment followed by Salmon quantification.

#### Channels

**Channels** are how data flows between processes. When fetchngs downloads a FASTQ file, it puts it on a channel. The next process (e.g., md5sum check) reads from that channel. Nextflow figures out the dependencies and runs everything that can run in parallel.

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

This is extremely useful for debugging. If a task fails:

1. Find the task hash in the Nextflow log or SLURM output
2. Go to `work/<hash>/`
3. Read `.command.log` for error messages
4. Read `.command.sh` to see exactly what command ran
5. Check `.exitcode`

> **Why is `work/` so large?** Every intermediate file lives here. A 10-sample RNA-seq run can generate hundreds of gigabytes of BAM files, trimmed FASTQs, etc. Always clean it up after a successful run.

## The config system

Nextflow has a layered config system. Settings are applied in order, with later sources overriding earlier ones:

```
Pipeline defaults (nextflow.config)
  └── Base config (conf/base.config)        # Default resources per process
       └── Institutional config (-c)        # Our cheaha.config
            └── Params file (-params-file)  # Your params.fetchngs.yml
                 └── CLI flags (--outdir)   # Highest priority
```

### Parameters vs config

This is the most common source of confusion:

| | Parameters (`--` or params file) | Config (`-c` file) |
|---|---|---|
| **What** | Pipeline-specific inputs | Infrastructure settings |
| **Examples** | `--input`, `--genome`, `--outdir` | `executor`, `singularity`, `queue` |
| **How to set** | `-params-file params.yml` or `--flag` | `-c cheaha.config` |
| **Who changes it** | You (the user) | Cluster admins / once per HPC |

The params file (`params.fetchngs.yml`) says **what** to analyze. The config file (`cheaha.config`) says **how** to run it on this cluster.

## Containers on Cheaha

Every nf-core process runs inside a **Singularity container** — a self-contained package with the exact software version needed. This means:

- You don't need to install STAR, Salmon, FastQC, etc.
- Every run uses identical software, regardless of what's installed on the cluster
- Results are reproducible across different HPCs

The Cheaha config enables Singularity and sets it to use `$USER_SCRATCH` for temp files. Containers are cached in `~/.singularity/` after the first download.

## Reproducibility

nf-core pipelines are designed for reproducible science. This repo pins:

| What | Where | Why |
|---|---|---|
| Pipeline version | `-r 1.12.0` / `-r 3.23.0` in scripts | Same code every time |
| Software versions | Containers (automatic) | Same tools every time |
| Parameters | `params.fetchngs.yml` / `params.rnaseq.yml` | Same settings every time |
| Reference genome | `genome: "GRCh38"` | Same reference every time |

To share your analysis with a collaborator, you just share this repo. They clone it, run the same scripts, and get the same results.

## Further reading

- [Nextflow training](https://training.nextflow.io/) — Official Nextflow tutorial
- [nf-core tutorials](https://nf-co.re/docs/tutorials/) — nf-core-specific guides
- [nf-core/modules](https://github.com/nf-core/modules) — Shared module library
- [Nextflow patterns](https://nextflow-io.github.io/patterns/) — Common workflow patterns
