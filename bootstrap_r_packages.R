#' Bootstrap CAP 735 R package dependencies
#'
#' Installs only missing packages needed by the CAP 735 workflow.
#'
#' Sources are configurable via environment variables:
#' - CAPEML_LOCAL_PATH (optional local source path)
#' - CAPEML_TARBALL_URL (default: taxadb branch tarball URL)
#' - CAPEMLGIS_LOCAL_PATH (default: /scratch/srearl/capemlGIS)
#' - CAPEMLGIS_TARBALL_URL (default: capemlGIS main branch tarball URL)
#' - CAPEMLGIS_GITHUB_REF (optional GitHub ref fallback)

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
  capemlgis_tarball_url <- base::Sys.getenv(
    "CAPEMLGIS_TARBALL_URL",
    unset = "https://github.com/CAPLTER/capemlGIS/archive/refs/heads/main.tar.gz"
  )
  capemlgis_github_ref <- base::Sys.getenv("CAPEMLGIS_GITHUB_REF", unset = "")

  # capemlGIS imports raster; ensure it is available first. This is usually
  # provided by the HPC module r-raster-3.6-23-gcc-12.1.0 loaded in job script.
  if (!is_installed("raster")) {
    message("Installing missing dependency package: raster")
    utils::install.packages("raster", repos = cran_repo)
  }

  install_ok <- FALSE

  if (base::dir.exists(capemlgis_local_path)) {
    message(base::sprintf(
      "Installing missing package capemlGIS from local path: %s",
      capemlgis_local_path
    ))

    try({
      remotes::install_local(
        capemlgis_local_path,
        upgrade = "never",
        dependencies = FALSE
      )
      install_ok <- TRUE
    }, silent = TRUE)

    if (!install_ok) {
      message("remotes::install_local failed for capemlGIS; trying base source install.")
      try({
        utils::install.packages(capemlgis_local_path, repos = NULL, type = "source")
        install_ok <- TRUE
      }, silent = TRUE)
    }
  }

  if (!install_ok) {
    message(base::sprintf(
      "Installing missing package capemlGIS from tarball URL: %s",
      capemlgis_tarball_url
    ))
    try({
      remotes::install_url(capemlgis_tarball_url, upgrade = "never", dependencies = TRUE)
      install_ok <- TRUE
    }, silent = TRUE)
  }

  if (!install_ok && capemlgis_github_ref != "") {
    message(base::sprintf(
      "Installing missing package capemlGIS from GitHub: %s",
      capemlgis_github_ref
    ))
    try({
      remotes::install_github(capemlgis_github_ref, upgrade = "never", dependencies = TRUE)
      install_ok <- TRUE
    }, silent = TRUE)
  }

  if (!install_ok) {
    base::stop(
      paste(
        "Failed to install capemlGIS from all configured sources.",
        "Checked local path:", capemlgis_local_path,
        "and tarball URL:", capemlgis_tarball_url,
        "(plus CAPEMLGIS_GITHUB_REF if set)."
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
