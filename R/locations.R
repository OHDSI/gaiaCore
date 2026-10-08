#' Load person locations from an OMOP CDM with the Gaia extension
#'
#' Copies `LOCATION` and `LOCATION_HISTORY` of a CDM that carries the Gaia extension tables into the `working` schema, which is where [spatialJoin()] looks for them, and builds the point geometry (EPSG:4326) from latitude and longitude.
#'
#' @param connection A connection from [connectGaia()].
#' @param cdmSchema Schema of the CDM (for example `"omopgis"`).
#' @param clear If `TRUE`, first empty `working.location` and `working.location_history`.
#'
#' @return Invisibly, the number of locations and location history rows now in `working`.
#' @export
loadLocationsFromOmop <- function(connection, cdmSchema = "omopgis", clear = FALSE) {
  cdmSchema <- .identifier(cdmSchema, "cdmSchema")
  checkmate::assertFlag(clear)
  if (clear) {
    .execute(connection, "TRUNCATE working.location_history, working.location CASCADE;")
  }
  .execute(connection, sprintf(paste(
    "INSERT INTO working.location (location_id, address_1, address_2, city, state, zip, county,",
    "  location_source_value, country_concept_id, country_source_value, latitude, longitude, geom)",
    "SELECT location_id, address_1, address_2, city, state, zip, county, location_source_value,",
    "  country_concept_id, country_source_value, latitude, longitude,",
    "  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)",
    "FROM %1$s.location;",
    "INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id,",
    "  entity_id, start_date, end_date)",
    "SELECT location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date",
    "FROM %1$s.location_history;"
  ), cdmSchema))
  invisible(.query(connection, paste(
    "SELECT (SELECT count(*) FROM working.location) AS locations,",
    "(SELECT count(*) FROM working.location_history) AS location_history"
  )))
}

#' Load person locations from data frames
#'
#' Inserts locations and their residence history into the `working` schema and builds the point geometry (EPSG:4326) from latitude and longitude.
#'
#' @param connection A connection from [connectGaia()].
#' @param location A data frame with `location_id`, `latitude` and `longitude`, and optionally
#'   `address_1`, `address_2`, `city`, `state`, `zip`, `county`, `location_source_value`,
#'   `country_concept_id` and `country_source_value`.
#' @param locationHistory A data frame with `location_id`, `entity_id` (the person), `start_date`,
#'   `end_date`, and optionally `relationship_type_concept_id` (default 2052496995, OMOP GIS
#'   "Patient Residence") and `domain_id` (default 1147314, Person). Gaia assigns an exposure to a
#'   person only when `domain_id` is 1147314.
#'
#' @return Invisibly, the number of locations and location history rows now in `working`.
#' @export
loadLocations <- function(connection, location, locationHistory) {
  checkmate::assertDataFrame(location)
  checkmate::assertDataFrame(locationHistory)
  checkmate::assertNames(names(location), must.include = c("location_id", "latitude", "longitude"), .var.name = "location")
  checkmate::assertNames(names(locationHistory), must.include = c("location_id", "entity_id", "start_date", "end_date"),
                         .var.name = "locationHistory")
  if (!"relationship_type_concept_id" %in% names(locationHistory)) {
    locationHistory$relationship_type_concept_id <- 2052496995L
  }
  if (!"domain_id" %in% names(locationHistory)) {
    locationHistory$domain_id <- 1147314L
  }
  allowed <- c("location_id", "address_1", "address_2", "city", "state", "zip", "county", "location_source_value",
               "country_concept_id", "country_source_value", "latitude", "longitude")
  location <- location[, intersect(names(location), allowed), drop = FALSE]
  history <- locationHistory[, c("location_id", "relationship_type_concept_id", "domain_id", "entity_id", "start_date", "end_date")]
  for (column in c("start_date", "end_date")) {
    history[[column]] <- as.Date(history[[column]])
  }
  DatabaseConnector::insertTable(connection, databaseSchema = "working", tableName = "location", data = location,
                                 dropTableIfExists = FALSE, createTable = FALSE, camelCaseToSnakeCase = FALSE,
                                 progressBar = FALSE)
  DatabaseConnector::insertTable(connection, databaseSchema = "working", tableName = "location_history", data = history,
                                 dropTableIfExists = FALSE, createTable = FALSE, camelCaseToSnakeCase = FALSE,
                                 progressBar = FALSE)
  .execute(connection, "UPDATE working.location SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) WHERE geom IS NULL;")
  invisible(.query(connection, paste(
    "SELECT (SELECT count(*) FROM working.location) AS locations,",
    "(SELECT count(*) FROM working.location_history) AS location_history"
  )))
}

#' Validate the loaded locations
#'
#' Runs Gaia's location statistics and validation checks (missing geometry, invalid coordinates, history rows without a location, invalid date ranges).
#'
#' @param connection A connection from [connectGaia()].
#' @param stopOnFailure If `TRUE`, raise an error when a check fails.
#'
#' @return A list with `statistics` (metric, value) and `checks` (check_name, status, details).
#' @export
validateLocations <- function(connection, stopOnFailure = FALSE) {
  statistics <- .query(connection, "SELECT * FROM working.location_statistics()")
  checks <- .query(connection, "SELECT * FROM working.validate_location_data()")
  if (any(checks$status != "PASS")) {
    message <- sprintf("Location checks failed: %s", paste(checks$check_name[checks$status != "PASS"], collapse = ", "))
    if (stopOnFailure) stop(message, call. = FALSE) else warning(message, call. = FALSE)
  }
  list(statistics = statistics, checks = checks)
}
