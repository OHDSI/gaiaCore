# Derive exposures for every variable of a dataset

Runs `working.spatial_join_all_from_catalog()`.

## Usage

``` r
spatialJoinAll(
  connection,
  tableId,
  spatialOperator = "ST_Within",
  bufferMeters = 0,
  exposureTypeConceptId = 0
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

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

A data frame with the number of rows created per variable.
