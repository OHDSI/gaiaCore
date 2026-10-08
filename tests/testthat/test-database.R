skip_if(Sys.getenv("GAIA_TEST_SERVER") == "", "GAIA_TEST_SERVER is not set")

connection <- NULL
withr::defer(if (!is.null(connection)) disconnectGaia(connection), teardown_env())
connection <- connectGaia(createGaiaConnectionDetails(
  server = Sys.getenv("GAIA_TEST_SERVER"), port = as.integer(Sys.getenv("GAIA_TEST_PORT", "5432")),
  password = Sys.getenv("GAIA_TEST_PASSWORD")))

test_that("the catalog can be listed", {
  expect_s3_class(listDatasources(connection), "data.frame")
  variables <- listVariables(connection)
  expect_true(all(c("table_name", "variable_name", "variable_source_id") %in% names(variables)))
})

test_that("derived exposure can be summarised and checked", {
  summary <- summarizeExposure(connection)
  expect_true(all(c("exposure_concept_id", "n_rows", "n_persons") %in% names(summary)))
  checks <- checkExposure(connection, valueRange = c(0, 200))
  expect_true(all(c("duplicate_rows", "outside_residence", "missing_value") %in% checks$check))
})

test_that("loading locations and joining them to a variable derives one row per interval overlap", {
  skip_if(Sys.getenv("GAIA_TEST_WRITE") != "true", "GAIA_TEST_WRITE is not true")
  occupied <- DatabaseConnector::querySql(connection, "SELECT (SELECT count(*) FROM working.location) + (SELECT count(*) FROM working.external_exposure)")[[1]]
  skip_if(occupied > 0, "working.location and working.external_exposure must be empty for the write test")
  table <- Sys.getenv("GAIA_TEST_TABLE"); variable <- Sys.getenv("GAIA_TEST_VARIABLE")
  geom <- DatabaseConnector::querySql(connection, sprintf(paste(
    "SELECT ST_X(ST_PointOnSurface(g.geom_wgs84)) AS x, ST_Y(ST_PointOnSurface(g.geom_wgs84)) AS y",
    "FROM working.geom_%1$s g WHERE EXISTS (SELECT 1 FROM working.attr_%1$s a WHERE a.geom_record_id = g.geom_record_id AND a.value_as_number IS NOT NULL)",
    "ORDER BY g.geom_record_id LIMIT 2"), table))
  names(geom) <- tolower(names(geom))
  location <- data.frame(location_id = c(900000001L, 900000002L), latitude = geom$y, longitude = geom$x)
  history <- data.frame(location_id = location$location_id, entity_id = c(900000001L, 900000002L),
                        start_date = as.Date("2014-01-01"), end_date = as.Date("2019-12-31"))
  withr::defer(DatabaseConnector::executeSql(connection, paste(
    "DELETE FROM working.external_exposure WHERE person_id >= 900000001;",
    "DELETE FROM working.location_history WHERE location_id >= 900000001;",
    "DELETE FROM working.location WHERE location_id >= 900000001;"), progressBar = FALSE, reportOverallTime = FALSE))
  loadLocations(connection, location, history)
  created <- spatialJoin(connection, variable, table, exposureTypeConceptId = 2052499878)
  expect_gte(created, 2)
  rows <- DatabaseConnector::querySql(connection, "SELECT count(*) AS n FROM working.external_exposure WHERE person_id >= 900000001")
  expect_equal(as.integer(rows[[1]]), created)
})
