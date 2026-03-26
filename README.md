# nf-core RNA-seq on Cheaha

This repository shows how to download public RNA-seq data and analyze it on UAB's [Cheaha HPC](https://www.uab.edu/it/home/research-computing) cluster using [nf-core](https://nf-co.re) pipelines. It runs two pipelines in sequence:

1. [nf-core/fetchngs](https://nf-co.re/fetchngs/1.12.0) (v1.12.0) downloads FASTQ files from GEO/SRA and generates a samplesheet.
2. [nf-core/rnaseq](https://nf-co.re/rnaseq/3.23.0) (v3.23.0) aligns reads, quantifies genes, and runs QC.

The example dataset is [GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613), 11 human iPSC-derived endothelial cell samples (paired-end, HiSeq 2000).

## Repository Structure

- `docs/` — [Tutorial](docs/tutorial.md) and [nf-core overview](docs/nf-core-overview.md), also published at [informaticsclub.github.io/nf-core-cheaha-examples](https://informaticsclub.github.io/nf-core-cheaha-examples/)
- `input/` — Accession list (`ids.csv`)
- `scripts/` — Nextflow install script and SLURM submission scripts
- `params.fetchngs.yml` / `params.rnaseq.yml` — Pipeline parameters

## Setup

Clone the repo and install Nextflow (the Cheaha module is too old for current nf-core pipelines):

```bash
git clone https://github.com/informaticsclub/nf-core-cheaha-examples.git
cd nf-core-cheaha-examples
bash scripts/install_nextflow.sh
```

This only needs to be done once.

## Running the Pipelines

```bash
sbatch scripts/run_fetchngs.sh      # Step 1: download FASTQs
# wait for it to finish...
sbatch scripts/run_rnaseq.sh        # Step 2: run the analysis
```

For a full walkthrough including monitoring, expected output, troubleshooting, and how to adapt this for your own data, see the [tutorial](docs/tutorial.md).

## Resources

- [nf-core/fetchngs docs](https://nf-co.re/fetchngs/1.12.0/docs/usage/) and [nf-core/rnaseq docs](https://nf-co.re/rnaseq/3.23.0/docs/usage/)
- [Cheaha nf-core config](https://github.com/nf-core/configs/blob/master/conf/cheaha.config)
- [UAB Research Computing](https://www.uab.edu/it/home/research-computing)

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to propose changes.

## License

This repository is licensed under the MIT License. See [`LICENSE`](LICENSE).