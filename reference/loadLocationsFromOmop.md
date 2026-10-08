# Load person locations from an OMOP CDM with the Gaia extension

Copies `LOCATION` and `LOCATION_HISTORY` of a CDM that carries the Gaia
extension tables into the `working` schema, which is where
[`spatialJoin()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoin.md)
looks for them, and builds the point geometry (EPSG:4326) from latitude
and longitude.

## Usage

``` r
loadLocationsFromOmop(connection, cdmSchema = "omopgis", clear = FALSE)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- cdmSchema:

  Schema of the CDM (for example `"omopgis"`).

- clear:

  If `TRUE`, first empty `working.location` and
  `working.location_history`.

## Value

Invisibly, the number of locations and location history rows now in
`working`.
