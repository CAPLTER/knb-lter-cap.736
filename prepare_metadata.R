#' CAP 735 Metadata Preparation
#'
#' Converts CAP 735 metadata workbook sheets into repository-local CSV/YAML files
#' used by the batch driver.

#' Prepare metadata artifacts from workbook
#'
#' @param metadata_workbook Character path to metadata xlsx.
#'
#' @return Invisibly returns TRUE.
prepare_metadata <- function(metadata_workbook) {
  if (!base::file.exists(metadata_workbook)) {
    base::stop(glue::glue("Metadata workbook not found: {metadata_workbook}"))
  }

  readxl::read_excel(path = metadata_workbook, sheet = "attributes") |>
    readr::write_csv("attributes.csv")

  readxl::read_excel(path = metadata_workbook, sheet = "attribute_codes") |>
    readr::write_csv("attribute_codes.csv")

  readxl::read_excel(path = metadata_workbook, sheet = "dataset") |>
    readr::write_csv("dataset.csv")

  readxl::read_excel(path = metadata_workbook, sheet = "data_entities") |>
    readr::write_csv("data_entities.csv")

  readxl::read_excel(path = metadata_workbook, sheet = "keywords") |>
    readr::write_csv("keywords.csv")

  personnel_raw <- readxl::read_excel(path = metadata_workbook, sheet = "personnel")

  personnel_raw$project_role <- dplyr::if_else(
    personnel_raw$role == "associatedParty",
    "some_project_role",
    NA_character_
  )
  personnel_raw$data_source <- "cap_authors.csv"

  personnel <- personnel_raw[, c(
    "last_name", "first_name", "role", "project_role", "email", "ORCiD", "data_source"
  )]
  base::names(personnel) <- c(
    "last_name", "first_name", "role_type", "project_role", "email", "orcid", "data_source"
  )

  personnel_list <- purrr::transpose(personnel)

  yaml::write_yaml(
    x = personnel_list,
    file = "people.yaml"
  )

  message("Metadata artifacts refreshed from workbook.")
  invisible(TRUE)
}
