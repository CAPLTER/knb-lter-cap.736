# knb-lter-cap.735
MRT and shade in PASS neighborhoods: 711, W15, and U18

## Production HPC Workflow

This repository now includes a production-oriented HPC pattern aligned to CAP 734,
with runtime package installation removed.

### Files

- `knb-lter-cap.735.sh`: SLURM launcher (module load + Rscript)
- `knb-lter-cap.735.R`: batch driver (preflight checks, raster processing, EML build)
- `process_rasters.R`: purrr-based raster discovery and entity-level EML generation
- `prepare_metadata.R`: optional workbook-to-CSV/YAML metadata refresh step

### One-time dependency provisioning

Provision package dependencies before production runs (not inside job runtime):

1. Install required R packages (including `rdflib`, `EDIutils`, `EML`, `capemlGIS`).
2. Install `capeml` from `CAPLTER/capeml` branch `taxadb`.
3. Install `capemlGIS` from the controlled shared local path snapshot.

### Runtime configuration

Configure `runtime` settings in `config.yaml`:

- `runtime.metadata_workbook`: metadata Excel file used for optional refresh
- `runtime.refresh_metadata_from_xlsx`: set true to regenerate CSV/YAML metadata from workbook
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
The bootstrap installs only missing packages.

Defaults:

- `capeml` source: `CAPLTER/capeml@taxadb`
- `capemlGIS` local source path: `/scratch/srearl/capemlGIS`

Override with environment variables if needed:

```bash
CAPEML_GITHUB_REF=CAPLTER/capeml@taxadb \
CAPEMLGIS_LOCAL_PATH=/scratch/srearl/capemlGIS \
sbatch knb-lter-cap.735.sh
```

### Preflight-only check

Run this to verify R version, library paths, required packages, and key paths
without starting raster processing:

```bash
CAP735_PREFLIGHT_ONLY=true sbatch knb-lter-cap.735.sh
```

The preflight fails fast if required packages are missing, including `capeml`,
`capemlGIS`, `rdflib`, and `EDIutils`.

### Style and implementation constraints

1. Iteration uses purrr approaches (no for-loops).
2. Non-base R function calls are namespaced.
3. Runtime scripts do not install packages.
