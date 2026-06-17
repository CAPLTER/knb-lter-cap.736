#' CAP 735 Batch Driver
#'
#' Production-oriented HPC entrypoint for metadata assembly, raster-entity EML
#' generation, EML validation, and package write. This script intentionally does
#' not install packages at runtime.

#' Null coalescing helper
#'
#' @param x Any object.
#' @param y Fallback value.
#'
#' @return `x` when non-null, otherwise `y`.
null_coalesce <- function(x, y) {
  if (is.null(x)) {
    return(y)
  }
  x
}

#' Ensure required namespaces are available
#'
#' @param package_names Character vector of package names.
#'
#' @return Invisible TRUE, or stop with informative error.
check_required_packages <- function(package_names) {
  missing_packages <- package_names[!purrr::map_lgl(
    .x = package_names,
    .f = ~base::requireNamespace(.x, quietly = TRUE)
  )]

  if (base::length(missing_packages) > 0) {
    base::stop(
      glue::glue(
        "Missing required packages: {stringr::str_c(missing_packages, collapse = ', ')}"
      )
    )
  }

  invisible(TRUE)
}

#' Print runtime context for troubleshooting environment mismatches
#'
#' @return Invisible TRUE.
print_runtime_context <- function() {
  base::cat("CAP735 preflight runtime context\n")
  base::cat(glue::glue("R.version: {base::R.version.string}\n"))
  base::cat(glue::glue("R.home: {base::R.home()}\n"))
  base::cat(
    glue::glue(
      "libPaths: {stringr::str_c(base::.libPaths(), collapse = ' | ')}\n"
    )
  )
  base::cat(
    glue::glue(
      "CAP735_CONDA_ENV: {base::Sys.getenv('CAP735_CONDA_ENV', unset = '<unset>')}\n"
    )
  )
  base::cat(
    glue::glue(
      "CAP735_RASTER_ROOT: {base::Sys.getenv('CAP735_RASTER_ROOT', unset = '<unset>')}\n"
    )
  )
  invisible(TRUE)
}

#' Ensure required files and directories exist
#'
#' @param required_files Character vector of files.
#' @param required_dirs Character vector of directories.
#'
#' @return Invisible TRUE, or stop when one or more paths are missing.
check_required_paths <- function(required_files, required_dirs) {
  missing_files <- required_files[!base::file.exists(required_files)]
  missing_dirs <- required_dirs[!base::dir.exists(required_dirs)]

  if (base::length(missing_files) > 0) {
    base::stop(
      glue::glue(
        "Missing required files: {stringr::str_c(missing_files, collapse = ', ')}"
      )
    )
  }

  if (base::length(missing_dirs) > 0) {
    base::stop(
      glue::glue(
        "Missing required directories: {stringr::str_c(missing_dirs, collapse = ', ')}"
      )
    )
  }

  invisible(TRUE)
}

#' Read runtime configuration
#'
#' @param config_file Character config yaml path.
#'
#' @return Named list of runtime values.
read_runtime_config <- function(config_file) {
  cfg <- yaml::read_yaml(config_file)
  runtime <- null_coalesce(cfg$runtime, list())

  metadata_workbook <- null_coalesce(
    runtime$metadata_workbook,
    "Metadata_mrt_shade_2025_May_to_Sept_3_PASS_neighborhoods.xlsx"
  )
  refresh_metadata <- base::isTRUE(runtime$refresh_metadata_from_xlsx)

  raster_root <- base::Sys.getenv(
    "CAP735_RASTER_ROOT",
    unset = null_coalesce(runtime$raster_root, "")
  )
  entities_dir <- null_coalesce(runtime$entities_output_dir, "entity_eml")
  max_rasters <- null_coalesce(runtime$max_rasters, NULL)
  epsg <- base::as.numeric(null_coalesce(runtime$epsg, 3857))
  coverage_begin <- null_coalesce(runtime$coverage_begin, "2025-05-01")
  coverage_end <- null_coalesce(runtime$coverage_end, "2025-09-30")

  list(
    geographic_description = cfg$geographic_description,
    metadata_workbook = metadata_workbook,
    refresh_metadata_from_xlsx = refresh_metadata,
    raster_root = raster_root,
    entities_output_dir = entities_dir,
    max_rasters = max_rasters,
    epsg = epsg,
    coverage_begin = coverage_begin,
    coverage_end = coverage_end
  )
}

#' Build and validate CAP 735 EML
#'
#' @param runtime Named runtime config list.
#'
#' @return Invisibly returns validated eml object.
build_and_validate_eml <- function(runtime) {

  dataset <- readr::read_csv("dataset.csv", show_col_types = FALSE)

  select_pass_columns <- function(x) {
    dplyr::select(
      x,
      name = dplyr::all_of("Name"),
      PASS_ID = dplyr::all_of("PASS_ID"),
      FIPSSTCO = dplyr::all_of("FIPSSTCO"),
      TRACT = dplyr::all_of("TRACT"),
      GROUP = dplyr::all_of("GROUP_"),
      STFID = dplyr::all_of("STFID"),
      BG2000 = dplyr::all_of("BG2000")
    )
  }

  register_global_object <- function(name, value) {
    base::assign(name, value, envir = .GlobalEnv)
    value
  }

  ## 711

  pass_711 <- sf::st_read("maps/711.geojson") |>
    select_pass_columns()
  pass_711 <- register_global_object("pass_711", pass_711)

  try({
    capeml::write_attributes(pass_711, overwrite = FALSE)
  })

  pass_711_SV <- capemlGIS::create_vector(
    vector_name = pass_711,
    description = "boundary of PASS neighborhood 711",
    driver = "GeoJSON"
  )

  pass_711_bounding_box <- sf::st_read("maps/711_bounding_box.geojson") |>
    select_pass_columns()
  pass_711_bounding_box <- register_global_object("pass_711_bounding_box", pass_711_bounding_box)

  try({
    capeml::write_attributes(pass_711_bounding_box, overwrite = FALSE)
  })

  pass_711_bounding_box_SV <- capemlGIS::create_vector(
    vector_name = pass_711_bounding_box,
    description = "bounding box of PASS neighborhood 711",
    driver      = "GeoJSON"
  )

  ## U18

  pass_U18 <- sf::st_read("maps/U18.geojson") |>
    select_pass_columns()
  pass_U18 <- register_global_object("pass_U18", pass_U18)

  try({
    capeml::write_attributes(pass_U18, overwrite = FALSE)
  })

  pass_U18_SV <- capemlGIS::create_vector(
    vector_name = pass_U18,
    description = "boundary of PASS neighborhood U18",
    driver = "GeoJSON"
  )

  pass_U18_bounding_box <- sf::st_read("maps/U18_bounding_box.geojson") |>
    select_pass_columns()
  pass_U18_bounding_box <- register_global_object("pass_U18_bounding_box", pass_U18_bounding_box)

  try({
    capeml::write_attributes(pass_U18_bounding_box, overwrite = FALSE)
  })

  pass_U18_bounding_box_SV <- capemlGIS::create_vector(
    vector_name = pass_U18_bounding_box,
    description = "bounding box of PASS neighborhood U18",
    driver      = "GeoJSON"
  )

  pass_W15 <- sf::st_read("maps/W15.geojson") |>
    select_pass_columns()
  pass_W15 <- register_global_object("pass_W15", pass_W15)

  try({
    capeml::write_attributes(pass_W15, overwrite = FALSE)
  })

  pass_W15_SV <- capemlGIS::create_vector(
    vector_name = pass_W15,
    description = "boundary of PASS neighborhood W15",
    driver = "GeoJSON"
  )

  pass_W15_bounding_box <- sf::st_read("maps/W15_bounding_box.geojson") |>
    select_pass_columns()
  pass_W15_bounding_box <- register_global_object("pass_W15_bounding_box", pass_W15_bounding_box)

  try({
    capeml::write_attributes(pass_W15_bounding_box, overwrite = FALSE)
  })

  pass_W15_bounding_box_SV <- capemlGIS::create_vector(
    vector_name = pass_W15_bounding_box,
    description = "bounding box of PASS neighborhood W15",
    driver      = "GeoJSON"
  )

  pass_objects <- base::list(
    pass_711 = pass_711,
    pass_711_SV = pass_711_SV,
    pass_711_bounding_box = pass_711_bounding_box,
    pass_711_bounding_box_SV = pass_711_bounding_box_SV,
    pass_U18 = pass_U18,
    pass_U18_SV = pass_U18_SV,
    pass_U18_bounding_box = pass_U18_bounding_box,
    pass_U18_bounding_box_SV = pass_U18_bounding_box_SV,
    pass_W15 = pass_W15,
    pass_W15_SV = pass_W15_SV,
    pass_W15_bounding_box = pass_W15_bounding_box,
    pass_W15_bounding_box_SV = pass_W15_bounding_box_SV
  )

  # capeml internals resolve vector objects via get(namestr) in .GlobalEnv.
  # Publish these workflow objects explicitly so dataset assembly can find them.
  base::list2env(pass_objects, envir = .GlobalEnv)
  invisible(pass_objects)

  EML::set_coverage(
    begin = runtime$coverage_begin,
    end = runtime$coverage_end,
    geographicDescription = runtime$geographic_description,
    west = dataset[dataset$metadata_field == "west", ]$metadata,
    east = dataset[dataset$metadata_field == "east", ]$metadata,
    north = dataset[dataset$metadata_field == "north", ]$metadata,
    south = dataset[dataset$metadata_field == "south", ]$metadata
  )

  capeml::create_dataset()
  eml <- capeml::create_eml()

  EML::eml_validate(eml)
  capeml::write_cap_eml()

  message("EML created, validated, and written.")
  invisible(eml)
}

#' Main entrypoint
#'
#' @return Invisible TRUE on success.
main <- function() {
  preflight_only <- base::tolower(
    base::Sys.getenv("CAP735_PREFLIGHT_ONLY", unset = "false")
  ) %in% c("1", "true", "yes")

  required_packages <- c(
    "yaml", "purrr", "readr", "readxl", "dplyr", "stringr", "glue", "EML",
    "capeml", "capemlGIS", "rdflib", "EDIutils"
  )

  print_runtime_context()

  check_required_packages(required_packages)

  check_required_paths(
    required_files = c("config.yaml", "dataset.csv", "process_rasters.R"),
    required_dirs = base::character()
  )

  runtime <- read_runtime_config("config.yaml")

  if (runtime$refresh_metadata_from_xlsx) {
    check_required_paths(
      required_files = c("prepare_metadata.R", runtime$metadata_workbook),
      required_dirs = base::character()
    )
    source("prepare_metadata.R", local = FALSE)
    prepare_metadata_fn <- base::get("prepare_metadata", mode = "function")
    prepare_metadata_fn(runtime$metadata_workbook)
  }

  check_required_paths(
    required_files = c("dataset.csv"),
    required_dirs = base::character()
  )

  if (runtime$raster_root == "") {
    base::stop(
      "Raster root is empty. Set CAP735_RASTER_ROOT or runtime.raster_root in config.yaml."
    )
  }

  check_required_paths(
    required_files = base::character(),
    required_dirs = c(runtime$raster_root)
  )

  if (preflight_only) {
    message("CAP735 preflight completed successfully. Exiting before raster processing.")
    return(invisible(TRUE))
  }

  source("process_rasters.R", local = FALSE)
  process_all_rasters_fn <- base::get("process_all_rasters", mode = "function")

  process_all_rasters_fn(
    raster_root = runtime$raster_root,
    output_dir = runtime$entities_output_dir,
    epsg = runtime$epsg,
    geographic_description = runtime$geographic_description,
    max_rasters = runtime$max_rasters
  )

  build_and_validate_eml(runtime)

  invisible(TRUE)
}

main()
