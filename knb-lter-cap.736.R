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
    raster_root = raster_root,
    entities_output_dir = entities_dir,
    max_rasters = max_rasters,
    epsg = epsg,
    coverage_begin = coverage_begin,
    coverage_end = coverage_end
  )
}


required_packages <- c(
  "yaml", "purrr", "readr", "dplyr", "stringr", "glue", "EML",
  "capeml", "capemlGIS", "rdflib", "EDIutils"
)

check_required_packages(required_packages)

check_required_paths(
  required_files = c("config.yaml", "dataset.csv"),
  required_dirs = base::character()
)

check_required_paths(
  required_files = c("dataset.csv"),
  required_dirs = base::character()
)

runtime <- read_runtime_config("config.yaml")

if (runtime$raster_root == "") {
  base::stop(
    "Raster root is empty. Set CAP735_RASTER_ROOT or runtime.raster_root in config.yaml."
  )
}

check_required_paths(
  required_files = base::character(),
  required_dirs = c(runtime$raster_root)
)

# source("process_rasters.R", local = FALSE)

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

write_attrs_if_missing <- function(object_name, object_value) {
  attrs_file <- base::sprintf("%s_attrs.yaml", object_name)
  if (base::file.exists(attrs_file)) {
    message(base::sprintf("Attributes file exists, skipping: %s", attrs_file))
    return(invisible(FALSE))
  }

  capeml::write_attributes(object_value, overwrite = FALSE)
  invisible(TRUE)
}

# vectors

## 711

pass_711 <- sf::st_read("maps/711.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_711", pass_711)

pass_711_SV <- capemlGIS::create_vector(
  vector_name = pass_711,
  description = "boundary of PASS neighborhood 711",
  driver = "GeoJSON",
  projectNaming = FALSE
)

pass_711_bounding_box <- sf::st_read("maps/711_bounding_box.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_711_bounding_box", pass_711_bounding_box)

pass_711_bounding_box_SV <- capemlGIS::create_vector(
  vector_name = pass_711_bounding_box,
  description = "bounding box of PASS neighborhood 711",
  driver = "GeoJSON",
  projectNaming = FALSE
)

## U18

pass_U18 <- sf::st_read("maps/U18.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_U18", pass_U18)

pass_U18_SV <- capemlGIS::create_vector(
  vector_name = pass_U18,
  description = "boundary of PASS neighborhood U18",
  driver = "GeoJSON",
  projectNaming = FALSE
)

pass_U18_bounding_box <- sf::st_read("maps/U18_bounding_box.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_U18_bounding_box", pass_U18_bounding_box)

pass_U18_bounding_box_SV <- capemlGIS::create_vector(
  vector_name = pass_U18_bounding_box,
  description = "bounding box of PASS neighborhood U18",
  driver = "GeoJSON",
  projectNaming = FALSE
)

pass_W15 <- sf::st_read("maps/W15.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_W15", pass_W15)

pass_W15_SV <- capemlGIS::create_vector(
  vector_name = pass_W15,
  description = "boundary of PASS neighborhood W15",
  driver = "GeoJSON",
  projectNaming = FALSE
)

pass_W15_bounding_box <- sf::st_read("maps/W15_bounding_box.geojson") |>
  select_pass_columns()

write_attrs_if_missing("pass_W15_bounding_box", pass_W15_bounding_box)

pass_W15_bounding_box_SV <- capemlGIS::create_vector(
  vector_name = pass_W15_bounding_box,
  description = "bounding box of PASS neighborhood W15",
  driver = "GeoJSON",
  projectNaming = FALSE
)

coverage <- EML::set_coverage(
  begin                 = runtime$coverage_begin,
  end                   = runtime$coverage_end,
  geographicDescription = runtime$geographic_description,
  west                  = dataset[dataset$metadata_field == "west", ]$metadata,
  east                  = dataset[dataset$metadata_field == "east", ]$metadata,
  north                 = dataset[dataset$metadata_field == "north", ]$metadata,
  south                 = dataset[dataset$metadata_field == "south", ]$metadata
)

dataset <- capeml::create_dataset()
eml     <- capeml::create_eml()

EML::eml_validate(eml)
capeml::write_cap_eml()

message("EML created, validated, and written.")
