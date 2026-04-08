Usage example for [denet](https://github.com/btraven00/denet) in bioinformatics.

Runs a simulated short-read alignment workflow with [Snakemake](https://snakemake.readthedocs.io) under three conditions and compares wall-clock time, peak RSS, and per-rule resource timeseries in an HTML report and a PDF figure.

The three conditions are:

- baseline: plain snakemake, no denet
- denet wrap: denet attaches to each rule's subprocess via a shell wrapper and writes a JSONL timeseries per step
- denet native: denet is on PATH and snakemake uses it as its built-in resource monitor; no per-rule changes, no JSONL output

## Requirements

- conda or mamba
- snakemake (conda-managed)
- Rust toolchain for denet; install denet with:

```
cargo install denet
```

denet is not available via conda and must be installed this way for the denet wrap and denet native conditions.

## Configuration

Workflow parameters are set in `config.yaml`. By default the pipeline simulates a 500 kb genome (5 chromosomes of 100 kb each) and 1 million paired-end reads of 150 bp, with 3 benchmark repeats per rule. The output directory defaults to
`results/`. The `use_denet` and `use_denet_native` flags select the monitoring condition; both default to false (baseline run).

## Running locally

```
make baseline      # results in results_baseline/
make denet         # results in results_denet/
make denet-native  # results in results_denet_native/
make figures       # renders analysis.Rmd to figures/analysis.html and figures/denet_benchmark.pdf
```

`make all` runs all four targets in sequence.

## Output

- `results_baseline/benchmarks/` — snakemake benchmark TSVs (wall time, peak RSS, CPU time, I/O)
- `results_denet/benchmarks/` and `results_denet/denet_metrics/` — benchmark TSVs and per-step JSONL timeseries
- `results_denet_native/benchmarks/` — benchmark TSVs (denet integrated as native profiler)
- `figures/analysis.html` — interactive HTML report
- `figures/denet_benchmark.pdf` — figure for the paper

## CI/CD

The workflow in `.github/workflows/tests.yml` runs on every push to `master` and on pull requests. It has five jobs:

- `dry-run`: validates the Snakefile DAG without executing anything.
- `integration-baseline`: runs the baseline condition and uploads logs and benchmarks as artifacts.
- `integration-denet`: installs denet, runs the denet wrap condition, and uploads logs, benchmarks, and denet metrics as artifacts.
- `integration-denet-native`: installs denet, runs the denet native condition, and uploads logs and benchmarks as artifacts.
- `render-report`: downloads artifacts from all three integration jobs and renders the HTML report and PDF figure, uploaded as artifacts on success.

The three integration jobs run in parallel. CI uses reduced parameters (10k reads, 2 chromosomes, 100 kb each, 3 benchmark repeats) to keep runtime short. Conda environments and the denet binary are cached between runs.

## License

GPLv3

## Contact

izaskun mallona work at gmail com
