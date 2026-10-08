#' Ingest a dataset registered in the Gaia catalog
#'
#' Runs `backbone.ingest_datasource()`: loads the dataset's JSON-LD metadata, downloads the source data and loads it into PostGIS, then cleans the geometry and adds the local projection.
#'
#' @param connection A connection from [connectGaia()].
#' @param tableId Catalog identifier of the dataset, for example `"us_2014_2019_monthly_pm25_by_county_cdc"`.
#' @param shell Shell used by the database to run the dataset's ETL scripts.
#'
#' @return Invisibly, a data frame with one row per ingestion step (`step`, `status`, `message`).
#'   An error is raised if a step failed.
#' @examples
#' \dontrun{
#' ingestDatasource(connection, "us_2023_county_tl")
#' ingestDatasource(connection, "us_2014_2019_monthly_pm25_by_county_cdc")
#' }
#' @export
ingestDatasource <- function(connection, tableId, shell = "/bin/sh") {
  checkmate::assertString(tableId)
  checkmate::assertString(shell)
  sql <- sprintf(
    "SELECT step, status, message FROM backbone.ingest_datasource(%s, %s)",
    .sqlString(tableId), .sqlString(shell)
  )
  result <- .query(connection, sql)
  failed <- result$status == "error"
  result$message <- substr(gsub("\\s+", " ", result$message), 1, 200)
  if (any(failed)) {
    stop(sprintf("Ingestion of '%s' failed at step '%s': %s", tableId, result$step[failed][1], result$message[failed][1]),
         call. = FALSE)
  }
  invisible(result)
}

#' Datasets registered in the database
#'
#' @param connection A connection from [connectGaia()].
#' @return A data frame with the registered datasets (`backbone.data_source`).
#' @export
listDatasources <- function(connection) {
  .query(connection, paste(
    "SELECT dataset_id, dataset_name, dataset_version, geom_type, srid",
    "FROM backbone.data_source ORDER BY dataset_name"
  ))
}

#' Variables registered in the attribute index
#'
#' @param connection A connection from [connectGaia()].
#' @return A data frame with one row per variable of every ingested dataset: its table, name,
#'   concept, unit, period and the `variable_source_id` that becomes `exposure_source_value`.
#' @export
listVariables <- function(connection) {
  .query(connection, paste(
    "SELECT table_name, variable_name, attr_concept_id, unit_source_value,",
    "attr_start_date, attr_end_date, variable_source_id",
    "FROM backbone.attr_index ORDER BY table_name, variable_name"
  ))
}

#' Build the geometry and attribute tables of an ingested dataset
#'
#' Runs `backbone.gdsc_load_all_variables()`: creates the `working` geometry and attribute tables of every variable registered for the dataset, which [spatialJoin()] reads.
#'
#' @param connection A connection from [connectGaia()].
#' @param tableId Catalog identifier of an ingested dataset.
#' @param geomLabel Column of the source table used as the name of each geometry (for example `"name"` or `"geoid"`).
#' @param variableNodata Value that marks missing data in the source, or `NULL`.
#' @param source Free-text description of the source stored with the attributes, or `NULL`.
#'
#' @return Invisibly, a data frame with one row per variable (`variable_name`, `status`, `message`).
#'   An error is raised if a variable failed to load.
#' @export
loadVariables <- function(connection, tableId, geomLabel = "name", variableNodata = NULL, source = NULL) {
  checkmate::assertString(tableId)
  checkmate::assertString(geomLabel)
  sql <- sprintf(
    "SELECT variable_name, status, message FROM backbone.gdsc_load_all_variables(p_table_id => %s, p_geom_label => %s, p_variable_nodata => %s, p_source => %s)",
    .sqlString(tableId), .sqlString(geomLabel), .sqlNumber(variableNodata), .sqlString(source)
  )
  result <- .query(connection, sql)
  failed <- result$status == "error"
  if (any(failed)) {
    stop(sprintf("Loading variable '%s' of '%s' failed: %s", result$variable_name[failed][1], tableId, result$message[failed][1]),
         call. = FALSE)
  }
  invisible(result)
}
