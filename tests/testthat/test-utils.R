test_that("SQL string literals are escaped", {
  expect_equal(gaiaCore:::.sqlString("a'b"), "'a''b'")
  expect_equal(gaiaCore:::.sqlString(NULL), "NULL")
  expect_equal(gaiaCore:::.sqlString(NA), "NULL")
  expect_equal(gaiaCore:::.sqlNumber(0.5), "0.5")
  expect_equal(gaiaCore:::.sqlNumber(NULL), "NULL")
})

test_that("schema names are validated", {
  expect_equal(gaiaCore:::.identifier("omopgis"), "omopgis")
  expect_error(gaiaCore:::.identifier("omopgis; DROP TABLE x"), "not a valid")
})

test_that("exposure filters are built from the source value and concept", {
  expect_equal(gaiaCore:::.filterClause(), character())
  expect_equal(gaiaCore:::.filterClause("40", c(1, 2), alias = "e"),
               c("e.exposure_source_value = '40'", "e.exposure_concept_id IN (1, 2)"))
})

test_that("spatialJoin rejects operators that are not on the list", {
  expect_error(spatialJoin(NULL, "v", "t", spatialOperator = "ST_Within); DROP TABLE x; --"))
})

test_that("connection details are created for PostgreSQL", {
  details <- createGaiaConnectionDetails(server = "localhost/gaiacore", port = 5433, password = "x", pathToDriver = "")
  expect_equal(details$dbms, "postgresql")
  expect_equal(details$server(), "localhost/gaiacore")
})
