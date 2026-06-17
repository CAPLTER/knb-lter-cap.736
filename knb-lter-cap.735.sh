#!/bin/bash
#SBATCH -c 1
#SBATCH -J knb_735
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH -t 02:00:00
#SBATCH --mem=64G
#SBATCH --mail-type=END
#SBATCH --mail-user=%u@asu.edu

set -euo pipefail

# Some module stacks export R_HOME for a different build; unset to avoid warnings
# like: "WARNING: ignoring environment value of R_HOME".
unset R_HOME

module purge
module load r-4.4.2-gcc-12.1.0 raptor2-2.0.15-gcc-12.1.0 redland-1.0.17-gcc-12.1.0 rasqal-0.9.33-gcc-12.1.0
module load r-raster-3.6-23-gcc-12.1.0

echo "=== Module sanity check ==="
module list 2>&1

echo "=== R sanity check ==="
which R
Rscript --vanilla -e 'cat(R.version.string, "\n")'

Rscript --vanilla -e 'if (!requireNamespace("raster", quietly = TRUE)) { stop("raster package not available after module load") }; cat("raster version:", as.character(utils::packageVersion("raster")), "\n")'

# Fixed scratch raster root can be set here or exported at submit time.
# Example:
# export CAP735_RASTER_ROOT="/scratch/srearl/cap735/rasters"

# Optional preflight-only mode:
# export CAP735_PREFLIGHT_ONLY="true"

# Dependency bootstrap runs on every job launch.
# export CAPEML_GITHUB_REF="CAPLTER/capeml@taxadb"
# export CAPEMLGIS_LOCAL_PATH="/scratch/srearl/capemlGIS"

Rscript bootstrap_r_packages.R

Rscript knb-lter-cap.735.R
