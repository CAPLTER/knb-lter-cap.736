#!/bin/bash
#SBATCH -c 1
#SBATCH -J knb_735
#SBATCH -o %j.out
#SBATCH -e %j.err
#SBATCH -t 3-00:00:00
#SBATCH --mem=64G
#SBATCH --mail-type=END
#SBATCH --mail-user=%u@asu.edu

set -euo pipefail

module purge
module load r-4.4.2-gcc-12.1.0 raptor2-2.0.15-gcc-12.1.0 redland-1.0.17-gcc-12.1.0 rasqal-0.9.33-gcc-12.1.0

# Fixed scratch raster root can be set here or exported at submit time.
# Example:
# export CAP735_RASTER_ROOT="/scratch/srearl/cap735/rasters"

# Optional preflight-only mode:
# export CAP735_PREFLIGHT_ONLY="true"

Rscript knb-lter-cap.735.R
