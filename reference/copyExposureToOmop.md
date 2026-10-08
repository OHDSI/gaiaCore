# Copy derived exposure into an OMOP CDM

Inserts the rows assigned to a person from `working.external_exposure`
into the CDM's `EXTERNAL_EXPOSURE` table, which the OHDSI tools then
query.

## Usage

``` r
copyExposureToOmop(
  connection,
  cdmSchema = "omopgis",
  sourceValue = NULL,
  conceptId = NULL
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- cdmSchema:

  Schema of the CDM (for example `"omopgis"`).

- sourceValue:

  Copy only rows with this `exposure_source_value`, or all if `NULL`.

- conceptId:

  Copy only rows of these exposure concepts, or all if `NULL`.

## Value

The number of rows inserted.
