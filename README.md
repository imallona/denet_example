Usage example for [denet](https://github.com/btraven00/denet) in bioinformatics.

Runs a small simulated read alignment workflow with [Snakemake](https://snakemake.readthedocs.io), once without denet and once with every rule wrapped by denet, then compares wall-clock time, peak RSS, and per-rule resource timeseries in an HTML report.

## Requirements

Snakemake and conda (or mamba). denet must be on PATH for the denet condition; install it with:

```
cargo install denet
```

## Running locally

```
make baseline   # snakemake only, results in results_baseline/
make denet      # denet-wrapped, results in results_denet/
make figures    # render analysis.Rmd to figures/analysis.html
```

`make all` runs all three in sequence.

## CI/CD

The workflow in `.github/workflows/tests.yml` runs automatically on every push to `master` and on pull requests. It has three jobs:

- `dry-run`: validates the Snakefile DAG without executing anything.
- `integration-baseline`: runs the pipeline without denet and uploads logs and benchmarks as artifacts.
- `integration-denet`: installs denet, runs both conditions (baseline and denet), renders the HTML report, and uploads it as an artifact alongside all logs, benchmarks, and denet metrics. Logs are uploaded whether the run succeeds or fails; the report is only uploaded on success.

CI uses reduced parameters (10k reads, 2 chromosomes, 100 kb each) to keep runtime short. denet is sampled at a fixed 100 ms interval (`-i 100 -m 100`) to prevent adaptive backoff on short-running steps. Conda environments and the denet binary are cached between runs.
