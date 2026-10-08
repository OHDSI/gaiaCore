# Load person locations from data frames

Inserts locations and their residence history into the `working` schema
and builds the point geometry (EPSG:4326) from latitude and longitude.

## Usage

``` r
loadLocations(connection, location, locationHistory)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- location:

  A data frame with `location_id`, `latitude` and `longitude`, and
  optionally `address_1`, `address_2`, `city`, `state`, `zip`, `county`,
  `location_source_value`, `country_concept_id` and
  `country_source_value`.

- locationHistory:

  A data frame with `location_id`, `entity_id` (the person),
  `start_date`, `end_date`, and optionally
  `relationship_type_concept_id` (default 2052496995, OMOP GIS "Patient
  Residence") and `domain_id` (default 1147314, Person). Gaia assigns an
  exposure to a person only when `domain_id` is 1147314.

## Value

Invisibly, the number of locations and location history rows now in
`working`.
