
process_raster <- function(filename, output_directory = runtime$entities_output_dir) {

  fileBasename <- basename(tools::file_path_sans_ext(filename))
  date         <- stringr::str_split(fileBasename, "_")[[1]][[1]]
  hour         <- stringr::str_split(fileBasename, "_")[[1]][[2]]
  site         <- stringr::str_split(fileBasename, "_")[[1]][[3]]
  type         <- stringr::str_split(fileBasename, "_")[[1]][[4]]

  if (grepl("mrt", type, ignore.case = TRUE)) {
    full_type <- "Hourly Mean Radiant Temperature Distribution"
    rvd       <- "Mean Radiant Temperature"
    rvu       <- "DEG_C"
  } else {
    full_type <- "Shade"
    rvd       <- "Binary value indicating presence (1) or absence (0) of shade"
    rvu       <- "NUM"
  }

  rasterDesc <- glue::glue(
    "{full_type} on {date} at {hour} for the PASS neighborhood {site}, Maricopa County, Arizona (USA)"
  )

  eml_raster <- capemlGIS::create_raster(
    raster_file              = filename,
    description              = rasterDesc,
    epsg                     = 3857,
    raster_value_description = rvd,
    raster_value_units       = rvu,
    geographic_description   = "central Arizona, USA",
    project_naming           = FALSE
  )

  assign(
    x     = paste0(fileBasename, "_SR"),
    value = eml_raster,
    envir = .GlobalEnv
  )

  EML::write_eml(
    eml  = get(paste0(fileBasename, "_SR")),
    file = paste0(output_directory, fileBasename, ".xml")
  )

}

# sub_path <- "/scratch/srearl/tiffs"
sub_path <- runtime$raster_root

list_of_rasters <- list.files(
  path       = sub_path,
  pattern    = "\\.tif$",
  full.names = TRUE,
  recursive  = TRUE
)

purrr::walk(list_of_rasters, process_raster)
