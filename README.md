# nf-core RNA-seq on Cheaha (UAB HPC)

Download public FASTQ files and run an RNA-seq analysis on UAB's Cheaha cluster using [nf-core](https://nf-co.re) pipelines.

| Step | Pipeline | What it does |
|---|---|---|
| 1 | [nf-core/fetchngs v1.12.0](https://nf-co.re/fetchngs/1.12.0) | Downloads FASTQs from GEO/SRA and generates a samplesheet |
| 2 | [nf-core/rnaseq v3.23.0](https://nf-co.re/rnaseq/3.23.0) | Alignment, quantification, and QC |

Dataset: **[GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613)** — 11 iPSC-derived endothelial cell transcriptomes (*Homo sapiens*, Illumina HiSeq 2000).

## Quick start

```bash
git clone https://github.com/<your-org>/nf-core-cheaha-examples.git
cd nf-core-cheaha-examples
bash scripts/install_nextflow.sh    # one-time setup
sbatch scripts/run_fetchngs.sh      # Step 1: download FASTQs
# … wait for completion …
sbatch scripts/run_rnaseq.sh        # Step 2: RNA-seq analysis
```

See the **[tutorial](docs/tutorial.md)** for a detailed walkthrough.

## Documentation

| Guide | Description |
|---|---|
| **[Tutorial](docs/tutorial.md)** | Step-by-step walkthrough of the full workflow |
| **[nf-core Overview](docs/nf-core-overview.md)** | How nf-core pipelines are structured and how they run on HPC |

## Repo structure

```
.
├── conf/
│   ├── cheaha.config              # Cheaha Nextflow config (source)
│   └── nfcore_custom.config       # Empty placeholder (prevents remote config loading)
├── docs/
│   ├── tutorial.md                # Step-by-step tutorial
│   └── nf-core-overview.md        # How nf-core pipelines work
├── input/
│   └── ids.csv                    # GEO accession(s), one per line
├── scripts/
│   ├── install_nextflow.sh        # One-time Nextflow install
│   ├── run_fetchngs.sh            # SLURM job for fetchngs
│   └── run_rnaseq.sh              # SLURM job for rnaseq
├── params.fetchngs.yml            # fetchngs parameters
├── params.rnaseq.yml              # rnaseq parameters
└── .gitignore
```

## Resources

- [nf-core/fetchngs docs](https://nf-co.re/fetchngs/1.12.0/docs/usage/) · [nf-core/rnaseq docs](https://nf-co.re/rnaseq/3.23.0/docs/usage/)
- [Cheaha nf-core config](https://github.com/nf-core/configs/blob/master/conf/cheaha.config) · [UAB Research Computing](https://www.uab.edu/it/home/research-computing)