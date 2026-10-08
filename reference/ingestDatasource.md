# Ingest a dataset registered in the Gaia catalog

Runs `backbone.ingest_datasource()`: loads the dataset's JSON-LD
metadata, downloads the source data and loads it into PostGIS, then
cleans the geometry and adds the local projection.

## Usage

``` r
ingestDatasource(connection, tableId, shell = "/bin/sh")
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- tableId:

  Catalog identifier of the dataset, for example
  `"us_2014_2019_monthly_pm25_by_county_cdc"`.

- shell:

  Shell used by the database to run the dataset's ETL scripts.

## Value

Invisibly, a data frame with one row per ingestion step (`step`,
`status`, `message`). An error is raised if a step failed.

## Examples

``` r
if (FALSE) { # \dontrun{
ingestDatasource(connection, "us_2023_county_tl")
ingestDatasource(connection, "us_2014_2019_monthly_pm25_by_county_cdc")
} # }
```
