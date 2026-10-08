test_that("dayWeightedExposure weights rows by the days they overlap the window", {
  exposure <- data.frame(
    person_id = 1,
    exposure_start_date = as.Date(c("2016-01-01", "2016-02-01")),
    exposure_end_date = as.Date(c("2016-01-31", "2016-02-29")),
    value_as_number = c(10, 20)
  )
  windows <- data.frame(person_id = 1, window_start = as.Date("2016-01-16"), window_end = as.Date("2016-02-10"))
  result <- dayWeightedExposure(exposure, windows)
  expect_equal(result$days_covered, 26)
  expect_equal(result$n_rows, 2)
  expect_equal(result$weighted_mean, (16 * 10 + 10 * 20) / 26)
  expect_equal(result$naive_mean, 15)
  expect_equal(result$coverage, 1)
})

test_that("dayWeightedExposure handles several persons, partly observed windows and windows without data", {
  exposure <- data.frame(
    person_id = c(1, 1, 2),
    exposure_start_date = as.Date(c("2016-01-01", "2016-02-01", "2016-01-01")),
    exposure_end_date = as.Date(c("2016-01-31", "2016-02-29", "2016-01-31")),
    value_as_number = c(10, 20, 5)
  )
  windows <- data.frame(
    person_id = c(1, 2, 3),
    window_start = as.Date(c("2016-01-01", "2016-01-21", "2016-01-01")),
    window_end = as.Date(c("2016-02-29", "2016-02-10", "2016-01-31"))
  )
  result <- dayWeightedExposure(exposure, windows)
  expect_equal(nrow(result), 3)
  expect_equal(result$weighted_mean[1], (31 * 10 + 29 * 20) / 60)
  expect_equal(result$days_covered[2], 11)
  expect_equal(result$coverage[2], 11 / 21)
  expect_true(is.na(result$weighted_mean[3]))
  expect_equal(result$n_rows[3], 0)
})

test_that("dayWeightedExposure defaults to each person's whole exposure period", {
  exposure <- data.frame(
    person_id = c(1, 1),
    exposure_start_date = as.Date(c("2016-01-01", "2016-02-01")),
    exposure_end_date = as.Date(c("2016-01-31", "2016-02-29")),
    value_as_number = c(10, 20)
  )
  result <- dayWeightedExposure(exposure)
  expect_equal(result$weighted_mean, (31 * 10 + 29 * 20) / 60)
  expect_equal(result$coverage, 1)
})

simulateClusters <- function(seed = 1, clusters = 40, perCluster = 60, beta = 0.3) {
  set.seed(seed)
  d <- data.frame(county = rep(seq_len(clusters), each = perCluster), x = stats::rnorm(clusters * perCluster))
  d$z <- stats::rnorm(nrow(d))
  d$y <- stats::rbinom(nrow(d), 1, stats::plogis(-1 + beta * d$x + 0.5 * d$z + rep(stats::rnorm(clusters, sd = 0.3), each = perCluster)))
  d
}

test_that("fitExposureEffect returns the logistic coefficient with ordered interval limits", {
  d <- simulateClusters()
  glmEstimate <- unname(stats::coef(stats::glm(y ~ x + z, data = d, family = stats::binomial()))["x"])
  for (method in c("jackknife", "cr1", "model")) {
    result <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = "county", interval = method)
    expect_equal(result$estimate, glmEstimate)
    expect_gt(result$se, 0)
    expect_lt(result$lower, result$estimate)
    expect_gt(result$upper, result$estimate)
    expect_equal(result$n_clusters, 40)
    expect_equal(result$method, method)
  }
})

test_that("the jackknife interval is not narrower than the model-based one when clusters matter", {
  d <- simulateClusters(seed = 3)
  jackknife <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = "county")
  model <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = "county", interval = "model")
  expect_gt(jackknife$upper - jackknife$lower, 0.8 * (model$upper - model$lower))
})

test_that("fitExposureEffect accepts a cluster vector and a mixed model", {
  d <- simulateClusters(seed = 2)
  fromVector <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = d$county)
  fromColumn <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = "county")
  expect_equal(fromVector, fromColumn)
  skip_if_not_installed("lme4")
  mixed <- fitExposureEffect(y ~ x + z, d, exposure = "x", cluster = "county", interval = "glmm")
  expect_equal(mixed$method, "glmm")
  expect_lt(abs(mixed$estimate - 0.3), 0.15)
})
