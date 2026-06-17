#' Bootstrap CAP 735 R package dependencies
#'
#' Installs only missing packages needed by the CAP 735 workflow.
#'
#' Sources are configurable via environment variables:
#' - CAPEML_LOCAL_PATH (optional local source path)
#' - CAPEML_TARBALL_URL (default: taxadb branch tarball URL)
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

if (!is_installed("capeml")) {
  capeml_local_path <- base::Sys.getenv("CAPEML_LOCAL_PATH", unset = "")
  capeml_tarball_url <- base::Sys.getenv(
    "CAPEML_TARBALL_URL",
    unset = "https://github.com/CAPLTER/capeml/archive/refs/heads/taxadb.tar.gz"
  )

  if (capeml_local_path != "" && base::dir.exists(capeml_local_path)) {
    message(base::sprintf(
      "Installing missing package capeml from local path: %s",
      capeml_local_path
    ))
    remotes::install_local(capeml_local_path, upgrade = "never", dependencies = TRUE)
  } else {
    message(base::sprintf(
      "Installing missing package capeml from tarball URL: %s",
      capeml_tarball_url
    ))
    remotes::install_url(capeml_tarball_url, upgrade = "never", dependencies = TRUE)
  }
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

    install_ok <- FALSE

    # First try remotes without dependency resolution to avoid DESCRIPTION parsing
    # issues in local development metadata.
    try({
      remotes::install_local(
        capemlgis_local_path,
        upgrade = "never",
        dependencies = FALSE
      )
      install_ok <- TRUE
    }, silent = TRUE)

    # Fallback to base source install (R CMD INSTALL path) if remotes fails.
    if (!install_ok) {
      message("remotes::install_local failed for capemlGIS; trying base source install.")
      utils::install.packages(capemlgis_local_path, repos = NULL, type = "source")
    }
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
