#' Day-weighted exposure over windows
#'
#' Exposure rows cover intervals (a month, a residence).
#'
#' @param exposure A data frame with `person_id`, `exposure_start_date`, `exposure_end_date` and a value column.
#' @param windows A data frame with `person_id`, `window_start` and `window_end`, one row per window,
#'   optionally with `window_id`. If `NULL`, each person's whole exposure period is the window.
#' @param valueColumn Name of the value column of `exposure`.
#'
#' @return A data frame with, per window: `weighted_mean` (day-weighted mean), `naive_mean` (mean of
#'   the overlapping rows), `n_rows`, `days_covered`, `window_days` and `coverage` (share of the
#'   window days with exposure data; below 1 when the window is only partly observed or exposure
#'   rows overlap).
#' @examples
#' exposure <- data.frame(
#'   person_id = 1,
#'   exposure_start_date = as.Date(c("2016-01-01", "2016-02-01")),
#'   exposure_end_date = as.Date(c("2016-01-31", "2016-02-29")),
#'   value_as_number = c(10, 20)
#' )
#' windows <- data.frame(
#'   person_id = 1,
#'   window_start = as.Date("2016-01-16"),
#'   window_end = as.Date("2016-02-10")
#' )
#' dayWeightedExposure(exposure, windows)
#' @export
dayWeightedExposure <- function(exposure, windows = NULL, valueColumn = "value_as_number") {
  checkmate::assertDataFrame(exposure)
  checkmate::assertNames(names(exposure), must.include = c("person_id", "exposure_start_date", "exposure_end_date", valueColumn))
  exposure <- data.frame(
    person_id = exposure$person_id,
    start = as.numeric(as.Date(exposure$exposure_start_date)),
    end = as.numeric(as.Date(exposure$exposure_end_date)),
    value = exposure[[valueColumn]]
  )
  if (is.null(windows)) {
    windows <- data.frame(person_id = sort(unique(exposure$person_id)))
    windows$window_start <- as.Date(vapply(windows$person_id, function(p) min(exposure$start[exposure$person_id == p]), numeric(1)), origin = "1970-01-01")
    windows$window_end <- as.Date(vapply(windows$person_id, function(p) max(exposure$end[exposure$person_id == p]), numeric(1)), origin = "1970-01-01")
  }
  checkmate::assertDataFrame(windows)
  checkmate::assertNames(names(windows), must.include = c("person_id", "window_start", "window_end"))
  if (!"window_id" %in% names(windows)) windows$window_id <- seq_len(nrow(windows))
  windows$ws <- as.numeric(as.Date(windows$window_start))
  windows$we <- as.numeric(as.Date(windows$window_end))
  joined <- merge(windows[, c("window_id", "person_id", "ws", "we")], exposure, by = "person_id")
  joined$days <- pmax(pmin(joined$end, joined$we) - pmax(joined$start, joined$ws) + 1, 0)
  joined <- joined[joined$days > 0, , drop = FALSE]
  result <- windows[, intersect(c("window_id", "person_id", "window_start", "window_end"), names(windows)), drop = FALSE]
  result$window_days <- windows$we - windows$ws + 1
  key <- as.character(joined$window_id)
  idx <- as.character(result$window_id)
  fill <- function(x, default = NA_real_) { out <- rep(default, length(idx)); names(out) <- idx; out[rownames(x)] <- x[, 1]; unname(out) }
  if (nrow(joined)) {
    result$weighted_mean <- fill(rowsum(joined$value * joined$days, key) / rowsum(joined$days, key))
    result$naive_mean <- fill(rowsum(joined$value, key) / rowsum(rep(1, nrow(joined)), key))
    result$n_rows <- fill(rowsum(rep(1, nrow(joined)), key), 0)
    result$days_covered <- fill(rowsum(joined$days, key), 0)
  } else {
    result$weighted_mean <- result$naive_mean <- NA_real_
    result$n_rows <- result$days_covered <- 0
  }
  result$coverage <- result$days_covered / result$window_days
  result
}

#' Effect of an exposure on a binary outcome, with intervals that hold up with few clusters
#'
#' Fits a logistic regression and reports the coefficient of the exposure with a confidence interval that accounts for clustering (persons in the same county or tract share unmeasured influences).
#'
#' @param formula A model formula with a 0/1 outcome, for example `y ~ pm25 + ses + age + female`.
#' @param data A data frame.
#' @param exposure Name of the exposure term whose coefficient is reported.
#' @param cluster Name of the column of `data` that identifies the clusters, or a vector of cluster ids.
#' @param interval `"jackknife"` (default): leave-one-cluster-out standard error, t quantile.
#'   `"cr1"`: clustered sandwich standard error, t quantile. `"model"`: model-based standard error,
#'   normal quantile (ignores clustering). `"glmm"`: logistic mixed model with a random intercept
#'   for the cluster ([lme4::glmer()], needs the lme4 package), Wald interval.
#' @param level Confidence level.
#'
#' @return A one-row data frame with `estimate`, `se`, `lower`, `upper`, `level`, `method`,
#'   `n_clusters` and `n`. Coefficients are log-odds per unit of exposure.
#' @examples
#' set.seed(1)
#' d <- data.frame(county = rep(1:30, each = 40), x = rnorm(1200))
#' d$y <- rbinom(1200, 1, plogis(-1 + 0.3 * d$x + rep(rnorm(30, sd = 0.3), each = 40)))
#' fitExposureEffect(y ~ x, d, exposure = "x", cluster = "county")
#' @export
fitExposureEffect <- function(formula, data, exposure, cluster, interval = c("jackknife", "cr1", "model", "glmm"), level = 0.95) {
  interval <- match.arg(interval)
  checkmate::assertDataFrame(data)
  checkmate::assertString(exposure)
  checkmate::assertNumber(level, lower = 0.5, upper = 0.999)
  clusterId <- if (is.character(cluster) && length(cluster) == 1 && cluster %in% names(data)) data[[cluster]] else cluster
  checkmate::assertTRUE(length(clusterId) == nrow(data))
  if (interval == "glmm") {
    if (!requireNamespace("lme4", quietly = TRUE)) stop("interval = 'glmm' needs the lme4 package", call. = FALSE)
    data$.cluster <- factor(clusterId)
    fit <- suppressWarnings(suppressMessages(lme4::glmer(stats::update(formula, . ~ . + (1 | .cluster)), data = data,
                                                        family = stats::binomial(), nAGQ = 0)))
    s <- summary(fit)$coefficients
    est <- unname(s[exposure, "Estimate"]); se <- unname(s[exposure, "Std. Error"])
    crit <- stats::qnorm(1 - (1 - level) / 2)
    return(data.frame(estimate = est, se = se, lower = est - crit * se, upper = est + crit * se, level = level, method = "glmm",
                      n_clusters = nlevels(data$.cluster), n = nrow(data)))
  }
  fit <- stats::glm(formula, data = data, family = stats::binomial())
  X <- stats::model.matrix(fit)
  checkmate::assertTRUE(exposure %in% colnames(X))
  y <- fit$y
  mu <- fit$fitted.values
  w <- mu * (1 - mu)
  beta <- stats::coef(fit)
  H <- crossprod(X * sqrt(w))
  bread <- solve(H)
  cl <- factor(clusterId)
  G <- nlevels(cl); n <- nrow(X); k <- ncol(X)
  s <- rowsum(X * (y - mu), cl)
  j <- match(exposure, colnames(X))
  if (interval == "model") {
    se <- sqrt(bread[j, j]); crit <- stats::qnorm(1 - (1 - level) / 2)
  } else if (interval == "cr1") {
    cr1 <- (G / (G - 1)) * ((n - 1) / (n - k)) * bread %*% crossprod(s) %*% bread
    se <- sqrt(cr1[j, j]); crit <- stats::qt(1 - (1 - level) / 2, G - 1)
  } else {
    Hg <- array(0, c(G, k, k))
    for (a in seq_len(k)) for (b in a:k) {
      v <- rowsum(X[, a] * X[, b] * w, cl)[, 1]
      Hg[, a, b] <- v; Hg[, b, a] <- v
    }
    bj <- t(vapply(seq_len(G), function(g) beta - solve(H - Hg[g, , ], s[g, ]), numeric(k)))
    cr3 <- ((G - 1) / G) * crossprod(sweep(bj, 2, colMeans(bj)))
    se <- sqrt(cr3[j, j]); crit <- stats::qt(1 - (1 - level) / 2, G - 1)
  }
  est <- unname(beta[j])
  data.frame(estimate = est, se = se, lower = est - crit * se, upper = est + crit * se, level = level, method = interval,
             n_clusters = G, n = n)
}
