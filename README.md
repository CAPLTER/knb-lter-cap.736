# knb-lter-cap.735
MRT and shade in PASS neighborhoods: 711, W15, and U18

## Production HPC Workflow

This repository now includes a production-oriented HPC pattern aligned to CAP 734,
with batch-safe startup checks and dependency bootstrap.

### Files

- `knb-lter-cap.735.sh`: SLURM launcher (module load + Rscript)
- `knb-lter-cap.735.R`: batch driver (validation, raster processing, EML build)
- `process_rasters.R`: purrr-based raster discovery and entity-level EML generation

### One-time dependency provisioning

Provision package dependencies before production runs when possible:

1. Install required R packages (including `rdflib`, `EDIutils`, `EML`, `capemlGIS`).
2. Install `capeml` from `CAPLTER/capeml` branch `temp-hardcode-version`.
3. Install `capemlGIS` from the controlled shared local path snapshot.

### Runtime configuration

Configure `runtime` settings in `config.yaml`:

- `runtime.raster_root`: fixed scratch path containing input rasters
- `runtime.entities_output_dir`: output folder for entity XML snippets
- `runtime.max_rasters`: optional integer limit for trial runs; use `null` for full runs
- `runtime.epsg`: EPSG code used for raster metadata
- `runtime.coverage_begin` and `runtime.coverage_end`: temporal coverage values

The environment variable `CAP735_RASTER_ROOT` overrides `runtime.raster_root`.

### Submit job

```bash
sbatch knb-lter-cap.735.sh
```

### Package bootstrap in job

Each SLURM job runs `bootstrap_r_packages.R` before the workflow starts.
The bootstrap installs missing packages and can force reinstall selected packages.

Defaults:

- `capeml` source tarball: `https://github.com/CAPLTER/capeml/archive/refs/heads/temp-hardcode-version.tar.gz`
- `capemlGIS` local source path: `/scratch/srearl/capemlGIS`
- `capemlGIS` tarball fallback: `https://github.com/CAPLTER/capemlGIS/archive/refs/heads/main.tar.gz`
- `CAPEML_FORCE_REINSTALL=true` by default in bootstrap, so `capeml` is refreshed from configured source

The launcher loads the HPC raster module `r-raster-3.6-23-gcc-12.1.0` so
`raster` is typically available without source install.

Bootstrap also ensures required CRAN dependencies are present, including `raster`.

Override with environment variables if needed:

```bash
CAPEML_TARBALL_URL=https://github.com/CAPLTER/capeml/archive/refs/heads/temp-hardcode-version.tar.gz \
CAPEMLGIS_LOCAL_PATH=/scratch/srearl/capemlGIS \
sbatch knb-lter-cap.735.sh
```

Optional fallback overrides:

- `CAPEMLGIS_TARBALL_URL` for alternate branch/tag tarball
- `CAPEMLGIS_GITHUB_REF` as a final fallback (if tarball/local fails)

### Temporary capeml version workaround

The current `capeml` temporary branch (`temp-hardcode-version`) supports a
hardcoded package version override to bypass EDI API revision lookup during
`create_eml()`.

In the SLURM launcher, this is set with:

```bash
export CAPEML_HARDCODED_VERSION="1"
```

Behavior:

- If `CAPEML_HARDCODED_VERSION` is set to a positive integer, that value is
	used as the package version directly.
- If unset, `capeml` falls back to EDI API revision lookup.

Important: when using this workaround, increment `CAPEML_HARDCODED_VERSION`
manually to avoid version collisions when publishing or updating packages.

### EDIutils HPC issue note

On SOL/HPC runs, we observed intermittent EDI API failures at request setup:

`Error in curl::handle_setopt(handle, .list = req$options) : length(keys) == length(values) is not TRUE`

Observed context:

- Happened in batch execution during EDI revision lookup
- Persisted after upgrading `EDIutils` (including `2.1.0`)
- Not consistently reproducible in local interactive runs

Current mitigation in this repository:

- Enforce minimum `EDIutils` version (`>= 2.0.0`) in bootstrap
- Run job scripts with `Rscript --vanilla`
- Unset proxy-related environment variables in launcher
- Use temporary `capeml` hardcoded-version override to avoid runtime EDI
	revision lookup

### Style and implementation constraints

1. Iteration uses purrr approaches (no for-loops).
2. Non-base R function calls are namespaced.
3. Runtime scripts do not install packages.
