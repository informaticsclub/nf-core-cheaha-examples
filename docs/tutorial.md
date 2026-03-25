# Tutorial: RNA-seq analysis on Cheaha with nf-core

This walkthrough takes you from a GEO accession to a complete RNA-seq analysis on UAB's Cheaha HPC cluster. No prior nf-core or Nextflow experience is needed.

> **New to nf-core?** Read the [nf-core pipeline overview](nf-core-overview.md) first to understand how pipelines are structured, how the config system works, and what happens inside the `work/` directory.

## Overview

```
GEO accession ──> fetchngs ──> FASTQs + samplesheet ──> rnaseq ──> counts, QC, reports
```

We use two nf-core pipelines back-to-back:

| Step | Pipeline | Version | Purpose |
|---|---|---|---|
| 1 | [nf-core/fetchngs](https://nf-co.re/fetchngs/1.12.0) | 1.12.0 | Download raw FASTQ files from a public repository |
| 2 | [nf-core/rnaseq](https://nf-co.re/rnaseq/3.23.0) | 3.23.0 | Align reads, quantify gene expression, run QC |

The key integration point: fetchngs outputs a **samplesheet** that rnaseq reads directly as input. No manual effort is needed.

## Prerequisites

- A Cheaha HPC account ([request access](https://www.uab.edu/it/home/research-computing))
- Basic familiarity with the Linux command line
- Basic familiarity with SLURM job submission (`sbatch`, `squeue`)

## Dataset

This example uses [GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613):

| | |
|---|---|
| **Title** | iPSCs Reveal Protective Modifiers of the BMPR2 mutation in Pulmonary Arterial Hypertension |
| **Organism** | *Homo sapiens* |
| **Samples** | 11 (3 control, 3 unaffected BMPR2 mutation carriers, 5 FPAH patients) |
| **Platform** | Illumina HiSeq 2000 |
| **Library** | mRNA-seq, paired-end |

## Step 0: Clone and set up

SSH into Cheaha and clone the repo:

```bash
ssh <your-blazerid>@cheaha.rc.uab.edu
git clone https://github.com/<your-org>/nf-core-cheaha-examples.git
cd nf-core-cheaha-examples
```

### Install Nextflow

The Cheaha `Nextflow` module is v21.08.0, which is too old for current nf-core pipelines (fetchngs 1.12.0 requires >=23.04.0). Run the install script once to get a compatible version:

```bash
bash scripts/install_nextflow.sh
```

This downloads `./nextflow` (v24.10.4) into the repo directory and creates the `logs/` directory that SLURM needs.

Verify it works:

```bash
module load Java
./nextflow -version
```

You should see `nextflow version 24.10.4`.

## Step 1: Download FASTQs with fetchngs

### What this step does

1. Resolves the GEO accession (`GSE79613`) to individual SRA run IDs
2. Downloads metadata from the ENA (European Nucleotide Archive)
3. Downloads FASTQ files using `sratools` (`prefetch` + `fasterq-dump`)
4. Generates a samplesheet formatted for nf-core/rnaseq

### Input file

The input is [`input/ids.csv`](../input/ids.csv) — a plain text file with one accession per line:

```
GSE79613
```

You can use any supported accession type (GEO series, SRA project, individual run IDs, etc.). See the [fetchngs docs](https://nf-co.re/fetchngs/1.12.0/docs/usage/#introduction) for the full list.

### Parameters

The pipeline parameters are in [`params.fetchngs.yml`](../params.fetchngs.yml):

```yaml
input: "input/ids.csv"          # Accession list
outdir: "results/fetchngs"     # Output directory
nf_core_pipeline: "rnaseq"      # Format samplesheet for nf-core/rnaseq
download_method: "sratools"     # Use sratools (FTP is blocked on Cheaha compute nodes)
custom_config_base: "conf"     # Load local empty placeholder instead of remote nf-core/configs
```

Key choices:
- **`download_method: "sratools"`** — FTP is blocked on Cheaha compute nodes, so we use sratools which downloads over HTTPS instead.
- **`nf_core_pipeline: "rnaseq"`** — This tells fetchngs to format the output samplesheet with the columns that nf-core/rnaseq expects (`sample`, `fastq_1`, `fastq_2`, `strandedness`). Strandedness defaults to `auto`.
- **`custom_config_base: "conf"`** — Every nf-core pipeline tries to load institutional configs from `${custom_config_base}/nfcore_custom.config`. By default this is a remote URL that can fail. We point it at our local `conf/` directory which contains an empty [`nfcore_custom.config`](../conf/nfcore_custom.config) placeholder. We supply the real Cheaha config via `-c` instead.

### Submit the job

```bash
sbatch scripts/run_fetchngs.sh
```

### Monitor progress

```bash
# Check if the job is running
squeue -u $USER

# Watch the SLURM log
tail -f logs/fetchngs_*.log

# Check the Nextflow debug log if something goes wrong
less logs/nextflow_fetchngs.log
```

### Expected output

Once complete, you'll find:

```
results/fetchngs/
├── fastq/                          # Downloaded FASTQ files
│   ├── SRX1603629_SRR3192396_1.fastq.gz
│   ├── SRX1603629_SRR3192396_2.fastq.gz
│   ├── ...
│   └── md5/                        # md5 checksums
├── samplesheet/
│   ├── samplesheet.csv             # <-- This feeds into Step 2
│   ├── id_mappings.csv
│   └── multiqc_config.yml
├── metadata/
│   ├── GSE79613.runinfo.tsv
│   └── GSE79613.runinfo_ftp.tsv
└── pipeline_info/
```

The critical file is **`results/fetchngs/samplesheet/samplesheet.csv`** — this is the input for the rnaseq pipeline.

> **Tip:** Open the samplesheet and verify sample names look reasonable. fetchngs uses SRA experiment aliases, which may not match the naming convention from the paper.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `metadata/` exists but no `fastq/` | FTP downloads failed silently | Verify `download_method: "sratools"` in params |
| `Unknown method invocation 'env'` | Cheaha config uses `env()` (Nextflow 25+) | Our local [`conf/cheaha.config`](../conf/cheaha.config) uses `System.getenv()` instead |
| `Config file does not exist: .../workflows/sra/nextflow.config` | Pipeline tries to load remote pipeline-specific config | Verify `custom_config_base: "conf"` in params |
| Job completes instantly with no output | `./nextflow` not found | Run `bash scripts/install_nextflow.sh` first |

## Step 2: Run RNA-seq analysis

### What this step does

1. Reads the samplesheet from Step 1
2. Runs FastQC on raw reads
3. Trims adapters with Trim Galore
4. Aligns to the GRCh38 reference genome using STAR
5. Quantifies gene expression with Salmon
6. Generates a MultiQC report

### Parameters

The parameters are in [`params.rnaseq.yml`](../params.rnaseq.yml):

```yaml
input: "results/fetchngs/samplesheet/samplesheet.csv"  # From fetchngs
outdir: "results/rnaseq"                                # Output directory
genome: "GRCh38"                                        # iGenomes reference
custom_config_base: "conf"
```

Key choices:
- **`genome: "GRCh38"`** — Uses the [iGenomes](https://ewels.github.io/AWS-iGenomes/) GRCh38 reference, which includes the genome FASTA, STAR index, and gene annotation. Nextflow downloads these automatically on first use.
- **`input`** — Points directly at the samplesheet that fetchngs created. The strandedness column is set to `auto`, so rnaseq will auto-detect it using Salmon.

### Submit the job

Make sure Step 1 has completed successfully before running this:

```bash
# Verify the samplesheet exists
cat results/fetchngs/samplesheet/samplesheet.csv

# Submit
sbatch scripts/run_rnaseq.sh
```

> **Note:** The rnaseq pipeline is much more compute-intensive than fetchngs. STAR alignment uses ~38 GB of RAM per sample. The SLURM job requests 48 hours, but the actual runtime depends on cluster load.

### Monitor progress

```bash
squeue -u $USER
tail -f logs/rnaseq_*.log
```

### Expected output

```
results/rnaseq/
├── fastqc/              # Raw read quality reports
├── trimgalore/          # Adapter-trimmed reads and reports
├── star_salmon/         # STAR alignments + Salmon quantification per sample
├── multiqc/
│   └── multiqc_report.html   # <-- Start here for QC overview
├── pipeline_info/       # Execution reports and resource usage
└── ...
```

The **MultiQC report** (`results/rnaseq/multiqc/multiqc_report.html`) is the best starting point. It aggregates QC metrics across all samples into a single interactive HTML report.

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `No such file: samplesheet.csv` | Step 1 didn't complete | Check `results/fetchngs/samplesheet/` exists |
| STAR jobs fail with OOM | Not enough memory | Cheaha config allows up to 750 GB; retries auto-increase |
| Very slow genome download | First run downloads iGenomes reference (~30 GB) | This is cached for future runs |

## Understanding the Cheaha config

The [`conf/cheaha.config`](../conf/cheaha.config) is a local copy of the [upstream nf-core Cheaha config](https://github.com/nf-core/configs/blob/master/conf/cheaha.config), modified for compatibility with Nextflow 24.x. It configures:

| Setting | Value | Why |
|---|---|---|
| `singularity.enabled` | `true` | Cheaha uses Singularity for containers (no Docker) |
| `process.executor` | `slurm` | Each pipeline task is submitted as its own SLURM job |
| `process.queue` | Dynamic | Automatically picks express/short/medium/long based on task time |
| `resourceLimits` | 750 GB RAM, 128 CPUs, 150h | Matches Cheaha's maximum node specs |
| `SINGULARITY_TMPDIR` | `$USER_SCRATCH` | Temp files go to scratch space, not `/tmp` |

You should not need to edit this file.

## Clean up

After verifying your results, clean up intermediate files:

```bash
# Remove Nextflow work directory (can be very large)
rm -rf work

# Remove Nextflow cache files
rm -rf .nextflow*

# Remove logs
rm -rf logs

# Optionally remove results when no longer needed
# rm -rf results
```

> **Important:** The `work/` directory can grow to hundreds of gigabytes. Don't forget to clean it up, especially on shared HPC storage.

## Adapting for your own data

To use this repo with a different dataset:

1. **Change the accession** — Edit [`input/ids.csv`](../input/ids.csv) with your GEO/SRA accession(s).

2. **Change the reference genome** — Edit `genome` in [`params.rnaseq.yml`](../params.rnaseq.yml). Common options:
   - `GRCh38` — Human
   - `GRCm39` — Mouse
   - `BDGP6` — *Drosophila*
   - See the full list at [iGenomes](https://ewels.github.io/AWS-iGenomes/)

3. **Adjust strandedness** — By default, fetchngs sets strandedness to `auto` and rnaseq auto-detects it. If you know your library prep, you can set it to `forward`, `reverse`, or `unstranded` in the samplesheet.

4. **Change the aligner** — The default is STAR + Salmon (`star_salmon`). Add `aligner: "hisat2"` to `params.rnaseq.yml` if you have memory constraints.

## Further reading

- [How nf-core pipelines work](nf-core-overview.md) — Pipeline structure, config system, work directory, containers
- [nf-core/fetchngs usage](https://nf-co.re/fetchngs/1.12.0/docs/usage/) · [output](https://nf-co.re/fetchngs/1.12.0/docs/output/)
- [nf-core/rnaseq usage](https://nf-co.re/rnaseq/3.23.0/docs/usage/) · [output](https://nf-co.re/rnaseq/3.23.0/docs/output/)
- [Cheaha nf-core config docs](https://github.com/nf-core/configs/blob/master/docs/cheaha.md)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/)
- [UAB Research Computing](https://www.uab.edu/it/home/research-computing)
