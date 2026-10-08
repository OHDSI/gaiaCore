# Effect of an exposure on a binary outcome, with intervals that hold up with few clusters

Fits a logistic regression and reports the coefficient of the exposure
with a confidence interval that accounts for clustering (persons in the
same county or tract share unmeasured influences).

## Usage

``` r
fitExposureEffect(
  formula,
  data,
  exposure,
  cluster,
  interval = c("jackknife", "cr1", "model", "glmm"),
  level = 0.95
)
```

## Arguments

- formula:

  A model formula with a 0/1 outcome, for example
  `y ~ pm25 + ses + age + female`.

- data:

  A data frame.

- exposure:

  Name of the exposure term whose coefficient is reported.

- cluster:

  Name of the column of `data` that identifies the clusters, or a vector
  of cluster ids.

- interval:

  `"jackknife"` (default): leave-one-cluster-out standard error, t
  quantile. `"cr1"`: clustered sandwich standard error, t quantile.
  `"model"`: model-based standard error, normal quantile (ignores
  clustering). `"glmm"`: logistic mixed model with a random intercept
  for the cluster
  ([`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html), needs the
  lme4 package), Wald interval.

- level:

  Confidence level.

## Value

A one-row data frame with `estimate`, `se`, `lower`, `upper`, `level`,
`method`, `n_clusters` and `n`. Coefficients are log-odds per unit of
exposure.

## Examples

``` r
set.seed(1)
d <- data.frame(county = rep(1:30, each = 40), x = rnorm(1200))
d$y <- rbinom(1200, 1, plogis(-1 + 0.3 * d$x + rep(rnorm(30, sd = 0.3), each = 40)))
fitExposureEffect(y ~ x, d, exposure = "x", cluster = "county")
#>    estimate         se     lower     upper level    method n_clusters    n
#> 1 0.2325906 0.05609663 0.1178601 0.3473211  0.95 jackknife         30 1200
```
