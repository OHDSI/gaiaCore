# Fetch derived exposure rows

Fetch derived exposure rows

## Usage

``` r
getExposure(connection, sourceValue = NULL, conceptId = NULL, limit = NULL)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- sourceValue:

  Only rows with this `exposure_source_value` (the `variable_source_id`
  of the variable).

- conceptId:

  Only rows of these exposure concepts.

- limit:

  Maximum number of rows, or `NULL`.

## Value

A data frame of `working.external_exposure` rows.
