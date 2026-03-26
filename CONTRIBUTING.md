# Contributing

Thanks for your interest in improving `nf-core-cheaha-examples`!

This repository is an example project: it documents how to run nf-core RNA-seq pipelines on the Cheaha HPC cluster, and includes helper scripts and parameter templates. Contributions are welcome for:

- Documentation improvements (tutorials, troubleshooting notes, explanations)
- Enhancements/fixes to helper scripts (e.g., `scripts/*.sh`)
- Updates to example configuration/parameters (e.g., `params/*.yml`) to keep them working with current tooling

## How to propose changes

1. Open an issue (recommended) describing the problem or suggestion.
2. If you already have a fix, open a pull request (PR) with a clear description of what changes and why.

## Pull request checklist

Before opening a PR, please:

- Keep PRs focused (one logical change per PR).
- Update relevant docs when the behavior or commands change.
- Follow the existing style in the repo (Markdown conventions, shell script style).
- Avoid adding large binary files or large datasets.
- For shell script changes, ensure scripts remain compatible with `bash` and avoid assumptions about local environments.

## What to include in a PR

Please include:

- A brief summary of the change.
- The motivation (what was broken / unclear / outdated).
- Any testing you performed (e.g., “ran `bash -n`” or “ran on Cheaha”).
- If your change affects parameters or outputs, mention which files/paths are impacted (e.g., `results/…` layout).

## Reporting issues

When filing an issue, include:

- What you tried (exact command(s), scripts, or steps).
- Expected vs actual behavior.
- Any relevant log snippets or error messages.
- Your environment details (Cheaha profile/version if applicable, and any Nextflow version).

## License

By contributing to this repository, you agree that your contributions will be licensed under the MIT License (see `LICENSE`).
