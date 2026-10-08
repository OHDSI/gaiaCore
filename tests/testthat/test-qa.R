test_that("staged rows are flagged for duplicates, missing residence overlap, missing, implausible and mismatched values", {
  existing <- data.frame(person_id = 1, location_id = 10, exposure_concept_id = 5,
                         exposure_start_date = as.Date("2016-01-01"), exposure_end_date = as.Date("2016-01-31"))
  history <- data.frame(entity_id = 1, start_date = as.Date("2014-01-01"), end_date = as.Date("2016-12-31"))
  staged <- data.frame(
    person_id = 1, location_id = 10, exposure_concept_id = 5,
    exposure_start_date = as.Date(c("2016-01-01", "2016-02-01", "2018-01-01", "2016-03-01", "2016-04-01", "2016-05-01")),
    exposure_end_date = as.Date(c("2016-01-31", "2016-02-29", "2018-01-31", "2016-03-31", "2016-04-30", "2016-05-31")),
    value_as_number = c(8, 8, 8, NA, 900, 8),
    dose_unit_source_value = c(NA, NA, NA, NA, NA, "mg/m3"))
  result <- .flagStaged(staged, existing, history, c(0, 200), "micrograms/cubic meter")
  expect_equal(which(result$duplicate_row), 1)
  expect_equal(which(result$outside_residence), 3)
  expect_equal(which(result$missing_value), 4)
  expect_equal(which(result$implausible_value), 5)
  expect_equal(which(result$unit_mismatch), 6)
  expect_equal(which(!result$reject), 2)
})
