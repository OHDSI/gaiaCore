# Validate the loaded locations

Runs Gaia's location statistics and validation checks (missing geometry,
invalid coordinates, history rows without a location, invalid date
ranges).

## Usage

``` r
validateLocations(connection, stopOnFailure = FALSE)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- stopOnFailure:

  If `TRUE`, raise an error when a check fails.

## Value

A list with `statistics` (metric, value) and `checks` (check_name,
status, details).
