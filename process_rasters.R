#' CAP 735 Raster Processing Helpers
#'
#' Batch-safe helpers for discovering GeoTIFF rasters, parsing metadata from
#' filenames, and generating deterministic entity-level EML snippets.

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

#' Parse raster metadata from filename
#'
#' @param raster_file Character file path.
#'
#' @return Named list with parsed metadata used in raster-level descriptions.
parse_raster_metadata <- function(raster_file) {
  file_basename <- base::basename(tools::file_path_sans_ext(raster_file))
  tokens <- stringr::str_split(file_basename, "_", simplify = TRUE)
  tokens_vec <- base::as.character(tokens)

  date_token <- tokens_vec |>
    stringr::str_subset(pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$") |>
    dplyr::first()

  hour_token <- tokens_vec |>
    stringr::str_subset(pattern = "^[0-2][0-9][0-5][0-9]$") |>
    dplyr::first()

  neighborhood_token <- tokens_vec |>
    stringr::str_subset(pattern = "^(711|W15|U18)$") |>
    dplyr::first()

  variable_type <- dplyr::case_when(
    stringr::str_detect(stringr::str_to_lower(file_basename), "shade") ~ "shade",
    stringr::str_detect(stringr::str_to_lower(file_basename), "mrt|tmrt") ~ "mrt",
    TRUE ~ "unknown"
  )

  list(
    file_basename = file_basename,
    date = null_coalesce(date_token, "unknown-date"),
    hour = null_coalesce(hour_token, "unknown-hour"),
    neighborhood = null_coalesce(neighborhood_token, "unknown-neighborhood"),
    variable_type = variable_type
  )
}

#' Build a deterministic xml filename for raster entity snippets
#'
#' @param parsed Parsed metadata from `parse_raster_metadata()`.
#'
#' @return Character filename ending in `.xml`.
build_entity_xml_name <- function(parsed) {
  stringr::str_c(
    parsed$neighborhood,
    parsed$date,
    parsed$hour,
    parsed$variable_type,
    sep = "_"
  ) |>
    stringr::str_replace_all(pattern = "[^A-Za-z0-9_-]", replacement = "-") |>
    stringr::str_c(".xml")
}

#' Build human-readable raster description
#'
#' @param parsed Parsed raster metadata list.
#'
#' @return Character description string.
build_raster_description <- function(parsed) {
  type_label <- dplyr::case_when(
    parsed$variable_type == "shade" ~ "Shade",
    parsed$variable_type == "mrt" ~ "Mean Radiant Temperature",
    TRUE ~ "Raster"
  )

  glue::glue(
    "Hourly {type_label} Distribution, PASS neighborhood {parsed$neighborhood}, {parsed$date} at {parsed$hour} MST"
  )
}

#' Build raster value description and units from variable type
#'
#' @param variable_type Character variable type.
#'
#' @return Named list containing value_description and units.
get_raster_value_metadata <- function(variable_type) {
  dplyr::case_when(
    variable_type == "shade" ~ list(
      value_description = "Shade from buildings and vegetation",
      units = "dimensionless"
    ),
    variable_type == "mrt" ~ list(
      value_description = "Mean Radiant Temperature",
      units = "DEG_C"
    ),
    TRUE ~ list(
      value_description = "Raster value",
      units = "dimensionless"
    )
  )
}

#' Create an entity-level EML snippet for one raster
#'
#' @param raster_file Character file path.
#' @param output_dir Character output directory.
#' @param epsg Numeric EPSG code.
#' @param geographic_description Character geographic description.
#'
#' @return Invisibly returns output xml path.
process_single_raster <- function(
  raster_file,
  output_dir,
  epsg,
  geographic_description
) {
  parsed <- parse_raster_metadata(raster_file)
  value_meta <- get_raster_value_metadata(parsed$variable_type)

  eml_raster <- capemlGIS::create_raster(
    raster_file = raster_file,
    description = build_raster_description(parsed),
    epsg = epsg,
    raster_value_description = value_meta$value_description,
    raster_value_units = value_meta$units,
    geographic_description = geographic_description,
    project_naming = FALSE
  )

  output_file <- file.path(output_dir, build_entity_xml_name(parsed))
  EML::write_eml(eml = eml_raster, file = output_file)

  message(glue::glue("Wrote entity EML: {output_file}"))
  invisible(output_file)
}

#' Process all rasters found under a root directory
#'
#' @param raster_root Character directory containing raster files.
#' @param output_dir Character output directory for xml snippets.
#' @param epsg Numeric EPSG code.
#' @param geographic_description Character geographic description.
#' @param max_rasters Optional integer limit for a trial run.
#'
#' @return Invisibly returns character vector of discovered raster files.
process_all_rasters <- function(
  raster_root,
  output_dir,
  epsg,
  geographic_description,
  max_rasters = NULL
) {
  raster_files <- list.files(
    path = raster_root,
    pattern = "\\.tif$",
    full.names = TRUE,
    recursive = TRUE
  ) |>
    base::sort()

  if (base::length(raster_files) == 0) {
    base::stop(glue::glue("No raster files found under: {raster_root}"))
  }

  if (!is.null(max_rasters)) {
    raster_files <- utils::head(raster_files, n = max_rasters)
    message(glue::glue("Trial mode enabled: processing first {base::length(raster_files)} raster files."))
  }

  base::dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  purrr::walk(
    .x = raster_files,
    .f = ~process_single_raster(
      raster_file = .x,
      output_dir = output_dir,
      epsg = epsg,
      geographic_description = geographic_description
    )
  )

  invisible(raster_files)
}
