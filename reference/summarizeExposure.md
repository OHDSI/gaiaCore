# Summarise the derived exposure rows

Summarise the derived exposure rows

## Usage

``` r
summarizeExposure(connection)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

## Value

A data frame with, per exposure concept and source value, the number of
rows and persons, the period covered and the mean value.
