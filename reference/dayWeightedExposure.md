# Day-weighted exposure over windows

Exposure rows cover intervals (a month, a residence).

## Usage

``` r
dayWeightedExposure(exposure, windows = NULL, valueColumn = "value_as_number")
```

## Arguments

- exposure:

  A data frame with `person_id`, `exposure_start_date`,
  `exposure_end_date` and a value column.

- windows:

  A data frame with `person_id`, `window_start` and `window_end`, one
  row per window, optionally with `window_id`. If `NULL`, each person's
  whole exposure period is the window.

- valueColumn:

  Name of the value column of `exposure`.

## Value

A data frame with, per window: `weighted_mean` (day-weighted mean),
`naive_mean` (mean of the overlapping rows), `n_rows`, `days_covered`,
`window_days` and `coverage` (share of the window days with exposure
data; below 1 when the window is only partly observed or exposure rows
overlap).

## Examples

``` r
exposure <- data.frame(
  person_id = 1,
  exposure_start_date = as.Date(c("2016-01-01", "2016-02-01")),
  exposure_end_date = as.Date(c("2016-01-31", "2016-02-29")),
  value_as_number = c(10, 20)
)
windows <- data.frame(
  person_id = 1,
  window_start = as.Date("2016-01-16"),
  window_end = as.Date("2016-02-10")
)
dayWeightedExposure(exposure, windows)
#>   window_id person_id window_start window_end window_days weighted_mean
#> 1         1         1   2016-01-16 2016-02-10          26      13.84615
#>   naive_mean n_rows days_covered coverage
#> 1         15      2           26        1
```
