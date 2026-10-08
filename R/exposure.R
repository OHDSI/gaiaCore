#' Derive exposures with Gaia's spatial-temporal join
#'
#' Runs `working.spatial_join_from_catalog()`: joins every loaded location interval to the geometries of one variable in space (the spatial operator) and in time (the variable's periods), and writes one `working.external_exposure` row per person, location, exposure concept and interval overlap.
#'
#' @param connection A connection from [connectGaia()].
#' @param variableName Variable to join (a `variable_name` of [listVariables()]).
#' @param tableId Catalog identifier of the dataset the variable belongs to. Needed when the same
#'   variable name exists in several datasets.
#' @param spatialOperator PostGIS predicate relating the location to the geometry: `"ST_Within"`
#'   (point in polygon, the default), `"ST_Intersects"`, `"ST_Overlaps"` or `"ST_Touches"`. The
#'   operator is stored verbatim in `exposure_relationship_source_value` and mapped to an OMOP GIS
#'   geometry relationship concept.
#' @param bufferMeters Buffer around the geometry, in metres, or 0.
#' @param exposureTypeConceptId Concept of the kind of data source (an "Exposure Type Concept", for
#'   example 2052499878, Air Quality Database), stored in `exposure_type_concept_id`. Gaia cannot
#'   infer it. 0 if unknown.
#'
#' @return The number of exposure rows created.
#' @examples
#' \dontrun{
#' spatialJoin(connection, "pm25_mean_pred", "us_2014_2019_monthly_pm25_by_county_cdc",
#'             exposureTypeConceptId = 2052499878)
#' }
#' @export
spatialJoin <- function(connection, variableName, tableId = NULL, spatialOperator = "ST_Within",
                        bufferMeters = 0, exposureTypeConceptId = 0) {
  checkmate::assertString(variableName)
  checkmate::assertString(tableId, null.ok = TRUE)
  checkmate::assertChoice(tolower(spatialOperator), c("st_within", "st_intersects", "st_overlaps", "st_touches", "st_coveredby"))
  checkmate::assertNumber(bufferMeters, lower = 0)
  checkmate::assertInt(exposureTypeConceptId)
  sql <- sprintf(
    "SELECT working.spatial_join_from_catalog(%s, %s, %s, %s, %d) AS n",
    .sqlString(variableName), .sqlString(tableId), .sqlString(spatialOperator),
    .sqlNumber(bufferMeters), as.integer(exposureTypeConceptId)
  )
  as.integer(.query(connection, sql)$n)
}

#' Derive exposures for every variable of a dataset
#'
#' Runs `working.spatial_join_all_from_catalog()`.
#'
#' @inheritParams spatialJoin
#' @return A data frame with the number of rows created per variable.
#' @export
spatialJoinAll <- function(connection, tableId, spatialOperator = "ST_Within", bufferMeters = 0, exposureTypeConceptId = 0) {
  checkmate::assertString(tableId)
  checkmate::assertNumber(bufferMeters, lower = 0)
  checkmate::assertInt(exposureTypeConceptId)
  .query(connection, sprintf(
    "SELECT variable_name, records_created FROM working.spatial_join_all_from_catalog(%s, %s, %s, %d)",
    .sqlString(tableId), .sqlString(spatialOperator), .sqlNumber(bufferMeters), as.integer(exposureTypeConceptId)
  ))
}

#' Remove derived exposure rows
#'
#' @param connection A connection from [connectGaia()].
#' @param variableName Remove only the rows of this variable (by name), or all rows if `NULL`.
#' @return Invisibly, the number of rows deleted.
#' @export
clearExposure <- function(connection, variableName = NULL) {
  checkmate::assertString(variableName, null.ok = TRUE)
  invisible(as.integer(.query(connection, sprintf("SELECT working.clear_exposure_data(%s) AS n", .sqlString(variableName)))$n))
}

#' Summarise the derived exposure rows
#'
#' @param connection A connection from [connectGaia()].
#' @return A data frame with, per exposure concept and source value, the number of rows and persons,
#'   the period covered and the mean value.
#' @export
summarizeExposure <- function(connection) {
  .query(connection, paste(
    "SELECT exposure_concept_id, exposure_source_value, exposure_type_concept_id,",
    "count(*) AS n_rows, count(DISTINCT person_id) AS n_persons,",
    "min(exposure_start_date) AS first_date, max(exposure_end_date) AS last_date, avg(value_as_number) AS mean_value",
    "FROM working.external_exposure GROUP BY 1, 2, 3 ORDER BY 1, 2"
  ))
}

#' Fetch derived exposure rows
#'
#' @param connection A connection from [connectGaia()].
#' @param sourceValue Only rows with this `exposure_source_value` (the `variable_source_id` of the variable).
#' @param conceptId Only rows of these exposure concepts.
#' @param limit Maximum number of rows, or `NULL`.
#' @return A data frame of `working.external_exposure` rows.
#' @export
getExposure <- function(connection, sourceValue = NULL, conceptId = NULL, limit = NULL) {
  checkmate::assertInt(limit, null.ok = TRUE, lower = 1)
  where <- .filterClause(sourceValue, conceptId)
  .query(connection, paste(
    "SELECT * FROM working.external_exposure",
    if (length(where)) paste("WHERE", paste(where, collapse = " AND ")),
    "ORDER BY person_id, exposure_start_date, location_id",
    if (!is.null(limit)) paste("LIMIT", as.integer(limit))
  ))
}

#' Copy derived exposure into an OMOP CDM
#'
#' Inserts the rows assigned to a person from `working.external_exposure` into the CDM's `EXTERNAL_EXPOSURE` table, which the OHDSI tools then query.
#'
#' @param connection A connection from [connectGaia()].
#' @param cdmSchema Schema of the CDM (for example `"omopgis"`).
#' @param sourceValue Copy only rows with this `exposure_source_value`, or all if `NULL`.
#' @param conceptId Copy only rows of these exposure concepts, or all if `NULL`.
#' @return The number of rows inserted.
#' @export
copyExposureToOmop <- function(connection, cdmSchema = "omopgis", sourceValue = NULL, conceptId = NULL) {
  cdmSchema <- .identifier(cdmSchema, "cdmSchema")
  columns <- paste(
    "location_id, person_id, exposure_concept_id, exposure_start_date, exposure_start_datetime,",
    "exposure_end_date, exposure_end_datetime, exposure_type_concept_id, exposure_relationship_concept_id,",
    "exposure_source_concept_id, exposure_source_value, exposure_relationship_source_value,",
    "dose_unit_source_value, quantity, modifier_source_value, operator_concept_id, value_as_number,",
    "value_as_concept_id, unit_concept_id"
  )
  where <- c("person_id > 0", .filterClause(sourceValue, conceptId))
  sql <- sprintf(
    "WITH inserted AS (INSERT INTO %s.external_exposure (%s) SELECT %s FROM working.external_exposure WHERE %s RETURNING 1) SELECT count(*) AS n FROM inserted",
    cdmSchema, columns, columns, paste(where, collapse = " AND ")
  )
  as.integer(.query(connection, sql)$n)
}
