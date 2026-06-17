#' Convert all GPKG files in maps/ to GeoJSON
#'
#' Reads every .gpkg file in the maps directory and writes a .geojson file
#' with the same base filename in the same directory.

maps_dir <- "maps"

if (!base::dir.exists(maps_dir)) {
  base::stop("Directory not found: maps")
}

gpkg_files <- list.files(
  path = maps_dir,
  pattern = "\\.gpkg$",
  full.names = TRUE
)

if (base::length(gpkg_files) == 0) {
  message("No .gpkg files found in maps/")
} else {
  purrr::walk(
    .x = gpkg_files,
    .f = function(gpkg_path) {
      geojson_path <- file.path(
        maps_dir,
        stringr::str_c(
          tools::file_path_sans_ext(base::basename(gpkg_path)),
          ".geojson"
        )
      )

      sf::st_read(dsn = gpkg_path, quiet = TRUE) |>
        sf::st_write(
          dsn = geojson_path,
          driver = "GeoJSON",
          delete_dsn = TRUE,
          quiet = TRUE
        )

      message(stringr::str_c("Wrote ", geojson_path))
    }
  )
}
