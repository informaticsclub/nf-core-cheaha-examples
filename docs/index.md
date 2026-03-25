---
title: Home
layout: home
nav_order: 1
---

# nf-core RNA-seq on Cheaha

Download public FASTQ files and run an RNA-seq analysis on UAB's Cheaha cluster using [nf-core](https://nf-co.re) pipelines.
{: .fs-6 .fw-300 }

| Step | Pipeline | What it does |
|:--|:--|:--|
| 1 | [nf-core/fetchngs v1.12.0](https://nf-co.re/fetchngs/1.12.0) | Downloads FASTQs from GEO/SRA and generates a samplesheet |
| 2 | [nf-core/rnaseq v3.23.0](https://nf-co.re/rnaseq/3.23.0) | Alignment, quantification, and QC |

**Dataset:** [GSE79613](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE79613) — 11 iPSC-derived endothelial cell transcriptomes (*Homo sapiens*, Illumina HiSeq 2000).

---

## Quick start


