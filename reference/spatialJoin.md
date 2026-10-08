# Derive exposures with Gaia's spatial-temporal join

Runs `working.spatial_join_from_catalog()`: joins every loaded location
interval to the geometries of one variable in space (the spatial
operator) and in time (the variable's periods), and writes one
`working.external_exposure` row per person, location, exposure concept
and interval overlap.

## Usage

``` r
spatialJoin(
  connection,
  variableName,
  tableId = NULL,
  spatialOperator = "ST_Within",
  bufferMeters = 0,
  exposureTypeConceptId = 0
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- variableName:

  Variable to join (a `variable_name` of
  [`listVariables()`](https://ohdsi.github.io/gaiaCore/reference/listVariables.md)).

- tableId:

  Catalog identifier of the dataset the variable belongs to. Needed when
  the same variable name exists in several datasets.

- spatialOperator:

  PostGIS predicate relating the location to the geometry: `"ST_Within"`
  (point in polygon, the default), `"ST_Intersects"`, `"ST_Overlaps"` or
  `"ST_Touches"`. The operator is stored verbatim in
  `exposure_relationship_source_value` and mapped to an OMOP GIS
  geometry relationship concept.

- bufferMeters:

  Buffer around the geometry, in metres, or 0.

- exposureTypeConceptId:

  Concept of the kind of data source (an "Exposure Type Concept", for
  example 2052499878, Air Quality Database), stored in
  `exposure_type_concept_id`. Gaia cannot infer it. 0 if unknown.

## Value

The number of exposure rows created.

## Examples

``` r
if (FALSE) { # \dontrun{
spatialJoin(connection, "pm25_mean_pred", "us_2014_2019_monthly_pm25_by_county_cdc",
            exposureTypeConceptId = 2052499878)
} # }
```
