# Running nf-core/fetchngs on Cheaha (UAB HPC)

A minimal guide to downloading public FASTQ files from GEO/SRA using the [nf-core/fetchngs](https://nf-co.re/fetchngs/1.12.0) pipeline on UAB's Cheaha cluster.

This example fetches RNA-seq data from **[GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613)** — iPSC-derived endothelial cell transcriptomes from control, unaffected BMPR2 mutation carriers, and FPAH patients (11 samples, Illumina HiSeq 2000, *Homo sapiens*).

## Prerequisites

- A Cheaha HPC account ([request access](https://www.uab.edu/it/home/research-computing))
- Familiarity with the Linux command line and SLURM

## Repo contents    

| File | Description |
|---|---|
| [`ids.csv`](ids.csv) | GEO accession to download (one ID per line) |
| [`params.yml`](params.yml) | Pipeline parameters (input, output, download method, etc.) |
| [`cheaha.config`](cheaha.config) | Cheaha HPC Nextflow config ([source](https://github.com/nf-core/configs/blob/master/conf/cheaha.config)) |
| [`install_nextflow.sh`](install_nextflow.sh) | One-time script to install a compatible Nextflow version locally |
| [`run_fetchngs.sh`](run_fetchngs.sh) | SLURM batch script that runs the pipeline |
| [`.gitignore`](.gitignore) | Ignores `logs/`, `work/`, `results/`, `nextflow`, and `.nextflow*` |

## Quick start

SSH into Cheaha, then:

```bash
git clone https://github.com/<your-org>/nf-core-cheaha-examples.git
cd nf-core-cheaha-examples
bash install_nextflow.sh   # one-time setup
sbatch run_fetchngs.sh
```

The install script is only needed once — it downloads a compatible Nextflow binary into the repo directory. The Cheaha `Nextflow` module (v21.08.0) is too old for this pipeline.

The batch script then loads the required modules (Singularity, Java) and launches the pipeline. The included [`cheaha.config`](cheaha.config) tells Nextflow to use Singularity and submit each task as its own SLURM job.

Monitor progress with:

```bash
# Check job status
squeue -u $USER

# Follow the log in real time
tail -f logs/fetchngs_*.log
```

> **Tip:** If a run fails partway through, add `-resume` to the `nextflow run` line in `run_fetchngs.sh` and resubmit with `sbatch`.

## Configuration

Pipeline parameters live in [`params.yml`](params.yml) — edit this file to change inputs or behaviour without touching the submission script:

```yaml
input: "ids.csv"            # Accession list
outdir: "results"           # Where final files are written
nf_core_pipeline: "rnaseq"  # Format samplesheet for nf-core/rnaseq
download_method: "ftp"      # ftp (default) or sratools
```

The SLURM script [`run_fetchngs.sh`](run_fetchngs.sh) handles modules and passes this file to Nextflow:

| Flag | Purpose |
|---|---|
| `-r 1.12.0` | Pin to a specific pipeline version for reproducibility |
| `-c cheaha.config` | Local copy of the [Cheaha config](https://github.com/nf-core/configs/blob/master/conf/cheaha.config) (Singularity + SLURM). Loaded with `-c` to avoid remote config-loading issues with `-profile` |
| `-params-file params.yml` | Reads all `--` pipeline parameters from the YAML file |

## Output

When finished you will find:

```
results/
├── fastq/           # Downloaded FASTQ files
├── samplesheet/     # Auto-generated samplesheet (ready for nf-core/rnaseq)
└── metadata/        # Sample metadata from ENA
```

## Clean up

The `work/` directory holds large intermediate files. Delete it once you have confirmed the results look correct:

```bash
rm -rf work results .nextflow* logs
```

---

## Quick reference

| What | Value |
|---|---|
| GEO accession | [GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613) |
| Organism | *Homo sapiens* |
| Samples | 11 (3 control, 3 unaffected carriers, 5 FPAH) |
| Platform | Illumina HiSeq 2000 |
| Pipeline version | [nf-core/fetchngs v1.12.0](https://nf-co.re/fetchngs/1.12.0) |
| Cheaha profile docs | [nf-core/configs — cheaha](https://github.com/nf-core/configs/blob/master/docs/cheaha.md) |

## Resources

- [nf-core/fetchngs usage docs](https://nf-co.re/fetchngs/1.12.0/docs/usage/)
- [Cheaha nf-core config](https://github.com/nf-core/configs/blob/master/docs/cheaha.md)
- [UAB Research Computing](https://www.uab.edu/it/home/research-computing)