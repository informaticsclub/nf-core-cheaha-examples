---
title: Home
layout: home
nav_order: 1
---

# nf-core RNA-seq on Cheaha

This site documents how to download public RNA-seq data and analyze it on UAB's Cheaha HPC cluster using [nf-core](https://nf-co.re) pipelines.
{: .fs-6 .fw-300 }

The workflow runs two pipelines in sequence. [nf-core/fetchngs](https://nf-co.re/fetchngs/1.12.0) (v1.12.0) downloads FASTQ files from GEO/SRA and writes a samplesheet. [nf-core/rnaseq](https://nf-co.re/rnaseq/3.23.0) (v3.23.0) then reads that samplesheet, aligns reads, quantifies genes, and runs QC.

The example dataset is [GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613), 11 human iPSC-derived endothelial cell samples (paired-end, HiSeq 2000).

## Getting started

- [**Tutorial**]({% link tutorial.md %}) — step-by-step walkthrough from clone to results
- [**nf-core Overview**]({% link nf-core-overview.md %}) — how pipelines are structured, the config system, the work directory
- [**Contributing**]({% link contributing.md %})
- [**GitHub repo**](https://github.com/informaticsclub/nf-core-cheaha-examples)

