#' Bootstrap CAP 735 R package dependencies
#'
#' Installs only missing packages needed by the CAP 735 workflow.
#'
#' Sources are configurable via environment variables:
#' - CAPEML_GITHUB_REF (default: CAPLTER/capeml@taxadb)
#' - CAPEMLGIS_LOCAL_PATH (default: /scratch/srearl/capemlGIS)

cran_repo <- "https://cloud.r-project.org"

required_cran <- c(
  "yaml", "purrr", "readr", "readxl", "dplyr", "stringr", "glue",
  "EML", "rdflib", "EDIutils", "sf"
)

is_installed <- function(pkg) {
  base::requireNamespace(pkg, quietly = TRUE)
}

install_cran_if_missing <- function(pkg) {
  if (!is_installed(pkg)) {
    message(base::sprintf("Installing missing CRAN package: %s", pkg))
    utils::install.packages(pkg, repos = cran_repo)
  }
}

for (pkg in required_cran) {
  install_cran_if_missing(pkg)
}

if (!is_installed("remotes")) {
  message("Installing missing CRAN package: remotes")
  utils::install.packages("remotes", repos = cran_repo)
}

capeml_ref <- base::Sys.getenv("CAPEML_GITHUB_REF", unset = "CAPLTER/capeml@taxadb")
if (!is_installed("capeml")) {
  message(base::sprintf("Installing missing package capeml from GitHub: %s", capeml_ref))
  remotes::install_github(capeml_ref, upgrade = "never", dependencies = TRUE)
}

if (!is_installed("capemlGIS")) {
  capemlgis_local_path <- base::Sys.getenv(
    "CAPEMLGIS_LOCAL_PATH",
    unset = "/scratch/srearl/capemlGIS"
  )

  if (base::dir.exists(capemlgis_local_path)) {
    message(base::sprintf(
      "Installing missing package capemlGIS from local path: %s",
      capemlgis_local_path
    ))
    remotes::install_local(capemlgis_local_path, upgrade = "never", dependencies = TRUE)
  } else {
    base::stop(
      paste(
        "capemlGIS is missing and local source path was not found.",
        "Expected CAPEMLGIS_LOCAL_PATH at:",
        capemlgis_local_path
      )
    )
  }
}

required_final <- c(required_cran, "capeml", "capemlGIS")
missing_final <- required_final[!vapply(required_final, is_installed, logical(1))]

if (base::length(missing_final) > 0) {
  base::stop(base::sprintf(
    "Dependency bootstrap failed. Still missing: %s",
    paste(missing_final, collapse = ", ")
  ))
}

message("Dependency bootstrap complete.")
