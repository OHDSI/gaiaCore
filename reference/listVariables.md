# Variables registered in the attribute index

Variables registered in the attribute index

## Usage

``` r
listVariables(connection)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

## Value

A data frame with one row per variable of every ingested dataset: its
table, name, concept, unit, period and the `variable_source_id` that
becomes `exposure_source_value`.
