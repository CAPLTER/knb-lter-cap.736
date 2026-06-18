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

default_user_lib <- base::path.expand(base::Sys.getenv("R_LIBS_USER", unset = "~/R/library"))
if (!base::dir.exists(default_user_lib)) {
  base::dir.create(default_user_lib, recursive = TRUE, showWarnings = FALSE)
}

if (!base::file.access(default_user_lib, mode = 2L) == 0L) {
  base::stop(base::sprintf("User library is not writable: %s", default_user_lib))
}

base::.libPaths(c(default_user_lib, base::.libPaths()))
install_lib <- base::.libPaths()[[1]]
message(base::sprintf("Using install library: %s", install_lib))

required_cran <- c(
  "yaml", "purrr", "readr", "readxl", "dplyr", "stringr", "glue",
  "EML", "rdflib", "EDIutils", "sf"
)

required_versions <- list(
  EDIutils = "2.0.0"
)

is_installed <- function(pkg) {
  base::requireNamespace(pkg, quietly = TRUE)
}

remove_installed_package <- function(pkg) {
  pkg_paths <- base::file.path(base::.libPaths(), pkg)
  existing_paths <- pkg_paths[base::dir.exists(pkg_paths)]
  if (base::length(existing_paths) > 0) {
    purrr::walk(existing_paths, ~base::unlink(.x, recursive = TRUE, force = TRUE))
    message(base::sprintf(
      "Removed existing installation for %s from: %s",
      pkg,
      paste(existing_paths, collapse = ", ")
    ))
  }
}

install_cran_if_missing <- function(pkg) {
  if (!is_installed(pkg)) {
    message(base::sprintf("Installing missing CRAN package: %s", pkg))
    utils::install.packages(pkg, repos = cran_repo, lib = install_lib)
    return(invisible(NULL))
  }

  minimum_version <- required_versions[[pkg]]
  if (!base::is.null(minimum_version)) {
    installed_version <- base::as.character(utils::packageVersion(pkg))
    if (utils::compareVersion(installed_version, minimum_version) < 0) {
      message(base::sprintf(
        "Upgrading %s from %s to >= %s",
        pkg,
        installed_version,
        minimum_version
      ))
      utils::install.packages(pkg, repos = cran_repo, lib = install_lib)
    }
  }
}

for (pkg in required_cran) {
  install_cran_if_missing(pkg)
}

if (!is_installed("remotes")) {
  message("Installing missing CRAN package: remotes")
  utils::install.packages("remotes", repos = cran_repo, lib = install_lib)
}

if (!is_installed("capeml")) {
  capeml_local_path <- base::Sys.getenv("CAPEML_LOCAL_PATH", unset = "")
  capeml_tarball_url <- base::Sys.getenv(
    "CAPEML_TARBALL_URL",
    unset = "https://github.com/CAPLTER/capeml/archive/refs/heads/taxadb.tar.gz"
  )

  if (capeml_local_path != "" && base::dir.exists(capeml_local_path)) {
    remove_installed_package("capeml")
    message(base::sprintf(
      "Installing missing package capeml from local path: %s",
      capeml_local_path
    ))
    remotes::install_local(
      capeml_local_path,
      upgrade = "never",
      dependencies = TRUE,
      lib = install_lib
    )
  } else {
    remove_installed_package("capeml")
    message(base::sprintf(
      "Installing missing package capeml from tarball URL: %s",
      capeml_tarball_url
    ))
    remotes::install_url(
      capeml_tarball_url,
      upgrade = "never",
      dependencies = TRUE,
      lib = install_lib
    )
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
    utils::install.packages("raster", repos = cran_repo, lib = install_lib)
  }

  install_ok <- FALSE

  if (base::dir.exists(capemlgis_local_path)) {
    remove_installed_package("capemlGIS")
    message(base::sprintf(
      "Installing missing package capemlGIS from local path: %s",
      capemlgis_local_path
    ))

    try({
      remotes::install_local(
        capemlgis_local_path,
        upgrade = "never",
        dependencies = FALSE,
        force = TRUE,
        lib = install_lib
      )
      install_ok <- TRUE
    }, silent = TRUE)

    if (!install_ok) {
      message("remotes::install_local failed for capemlGIS; trying base source install.")
      try({
        utils::install.packages(
          capemlgis_local_path,
          repos = NULL,
          type = "source",
          lib = install_lib
        )
        install_ok <- TRUE
      }, silent = TRUE)
    }
  }

  if (!install_ok) {
    remove_installed_package("capemlGIS")
    message(base::sprintf(
      "Installing missing package capemlGIS from tarball URL: %s",
      capemlgis_tarball_url
    ))
    try({
      remotes::install_url(
        capemlgis_tarball_url,
        upgrade = "never",
        dependencies = TRUE,
        force = TRUE,
        lib = install_lib
      )
      install_ok <- TRUE
    }, silent = TRUE)
  }

  if (!install_ok && capemlgis_github_ref != "") {
    remove_installed_package("capemlGIS")
    message(base::sprintf(
      "Installing missing package capemlGIS from GitHub: %s",
      capemlgis_github_ref
    ))
    try({
      remotes::install_github(
        capemlgis_github_ref,
        upgrade = "never",
        dependencies = TRUE,
        force = TRUE,
        lib = install_lib
      )
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
message(base::sprintf(
  "EDIutils version in use: %s",
  base::as.character(utils::packageVersion("EDIutils"))
))
