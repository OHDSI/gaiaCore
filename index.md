# gaiaCore

gaiaCore is an R package for working with a **Gaia** database. It
connects to gaiaDB (PostgreSQL with PostGIS) **directly through
[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)**, runs
the Gaia pipeline from R, and provides the analytics that turn the
result into evidence: linking place-based exposures (air pollution,
deprivation, green space, anything with a geometry and a period) to the
people in an OMOP CDM.

With gaiaCore you can

- **ingest** datasets registered in the Gaia catalog and build their
  geometry and attribute tables,
- **load person locations** and residence histories (from data frames or
  from an OMOP CDM with the Gaia extension),
- **derive exposure** by joining locations to geospatial sources in
  space and time (`EXTERNAL_EXPOSURE` rows), one variable at a time,
- **check** the derived rows (duplicates, values outside the residence
  interval, missing or implausible values, unit mismatches),
- **copy** the result into the CDM, where HADES tools such as
  CohortMethod and FeatureExtraction can use it,
- **analyse** exposure: day-weighted exposure over windows such as a
  pregnancy, and effect estimates whose confidence intervals stay valid
  with few, unbalanced geographic clusters.

All spatial processing happens inside gaiaDB; gaiaCore calls its SQL
functions, so every derived value stays traceable to the catalog entry,
the geometry and the residence interval that produced it.

## Where gaiaCore fits

| Repository | Purpose |
|----|----|
| [gaiaCatalog](https://github.com/OHDSI/gaiaCatalog) | Dataset definitions: metadata (JSON-LD) and the ETL scripts that load each dataset |
| [gaiaDB](https://github.com/OHDSI/gaiaDB) | The database: PostGIS schema and the SQL functions for ingestion and the spatial-temporal join |
| [gaiaDocker](https://github.com/OHDSI/gaiaDocker) | Docker deployment of the whole stack |
| **gaiaCore** (this package) | R interface to the database, quality checks and exposure analytics |

The Python, Java, Julia, Bash and PostgREST-based R clients that used to
live in this repository are on the
[`connectors`](https://github.com/OHDSI/gaiaCore/tree/connectors) branch
(tag `connectors-v1`).

## Installation

``` r

# install.packages("remotes")
remotes::install_github("OHDSI/gaiaCore")
```

DatabaseConnector needs Java and the PostgreSQL JDBC driver. Download
the driver once with
`DatabaseConnector::downloadJdbcDrivers("postgresql")` and point
`DATABASECONNECTOR_JAR_FOLDER` at it.

**Docker.** The image `ohdsi/gaia-core` is
[HADES](https://ohdsi.github.io/Hades/) (RStudio, CohortMethod,
FeatureExtraction, Capr) with gaiaCore,
[CaprForExtensions](https://github.com/OHDSI/CaprForExtensions),
[FeatureExtractionForExtensions](https://github.com/OHDSI/FeatureExtractionForExtensions),
the JDBC driver and the spatial packages (sf and others) installed:

``` sh
docker pull --platform linux/amd64 ohdsi/gaia-core:main
docker run -d --name gaia-core --platform linux/amd64 --network gaiadocker_default -p 8787:8787 \
  -e USER=ohdsi -e PASSWORD=<choose a password> ohdsi/gaia-core:main
```

Open <http://localhost:8787> and sign in as `ohdsi`. On the
`gaiadocker_default` network the database is reachable as `gaia-db`,
which is the package default; pass the database password to
`createGaiaConnectionDetails(password = )` or set
`GAIA_POSTGRES_PASSWORD` in `~/.Renviron`.

## Quick start

``` r

library(gaiaCore)

connection <- connectGaia(createGaiaConnectionDetails(server = "gaia-db/gaiacore"))

# 1. Ingest the datasets (boundaries first) and build their geometry and attribute tables
ingestDatasource(connection, "us_2023_county_tl")
ingestDatasource(connection, "us_2014_2019_monthly_pm25_by_county_cdc")
loadVariables(connection, "us_2014_2019_monthly_pm25_by_county_cdc", geomLabel = "name", variableNodata = -999)

# 2. Load the persons' locations and residence history, and validate them
loadLocationsFromOmop(connection, cdmSchema = "omopgis")
validateLocations(connection)

# 3. Join locations to one variable in space and time
spatialJoin(connection, "pm25_mean_pred", "us_2014_2019_monthly_pm25_by_county_cdc",
            exposureTypeConceptId = 2052499878)   # Exposure Type Concept: Air Quality Database

# 4. Check the result and copy it into the CDM
summarizeExposure(connection)
checkExposure(connection, valueRange = c(0, 200))
copyExposureToOmop(connection, cdmSchema = "omopgis")

disconnectGaia(connection)
```

Each exposure row records where it came from: `exposure_source_value` is
the `variable_source_id` of the variable (see
[`listVariables()`](https://ohdsi.github.io/gaiaCore/reference/listVariables.md)),
`exposure_relationship_source_value` the spatial operator, and
`exposure_type_concept_id` the kind of data source you passed to
[`spatialJoin()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoin.md).

### Analytics

``` r

# Mean exposure during a pregnancy: partial months at both ends count for the days they cover
exposure <- getExposure(connection, conceptId = 2052499839)
dayWeightedExposure(exposure, windows)   # windows: person_id, window_start, window_end

# Effect of exposure on an outcome, with a confidence interval that accounts for clustering by county
fitExposureEffect(outcome ~ pm25 + ses + age + female, data, exposure = "pm25", cluster = "county")
```

[`fitExposureEffect()`](https://ohdsi.github.io/gaiaCore/reference/fitExposureEffect.md)
reports the log-odds per unit of exposure with a leave-one-cluster-out
jackknife interval by default. In simulations of a tract-level benchmark
with 175 unbalanced county clusters its 95% intervals covered the true
value 95.8% of the time, against 90% for the usual clustered sandwich
interval and 74% for model-based intervals; `interval = "glmm"` fits a
mixed model instead.

## Functions

| Task | Functions |
|----|----|
| Connect | [`createGaiaConnectionDetails()`](https://ohdsi.github.io/gaiaCore/reference/createGaiaConnectionDetails.md), [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md), [`disconnectGaia()`](https://ohdsi.github.io/gaiaCore/reference/disconnectGaia.md) |
| Catalog and ingestion | [`ingestDatasource()`](https://ohdsi.github.io/gaiaCore/reference/ingestDatasource.md), [`loadVariables()`](https://ohdsi.github.io/gaiaCore/reference/loadVariables.md), [`listDatasources()`](https://ohdsi.github.io/gaiaCore/reference/listDatasources.md), [`listVariables()`](https://ohdsi.github.io/gaiaCore/reference/listVariables.md) |
| Locations | [`loadLocationsFromOmop()`](https://ohdsi.github.io/gaiaCore/reference/loadLocationsFromOmop.md), [`loadLocations()`](https://ohdsi.github.io/gaiaCore/reference/loadLocations.md), [`validateLocations()`](https://ohdsi.github.io/gaiaCore/reference/validateLocations.md) |
| Exposure | [`spatialJoin()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoin.md), [`spatialJoinAll()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoinAll.md), [`summarizeExposure()`](https://ohdsi.github.io/gaiaCore/reference/summarizeExposure.md), [`getExposure()`](https://ohdsi.github.io/gaiaCore/reference/getExposure.md), [`clearExposure()`](https://ohdsi.github.io/gaiaCore/reference/clearExposure.md), [`copyExposureToOmop()`](https://ohdsi.github.io/gaiaCore/reference/copyExposureToOmop.md) |
| Quality | [`checkExposure()`](https://ohdsi.github.io/gaiaCore/reference/checkExposure.md) |
| Analytics | [`dayWeightedExposure()`](https://ohdsi.github.io/gaiaCore/reference/dayWeightedExposure.md), [`fitExposureEffect()`](https://ohdsi.github.io/gaiaCore/reference/fitExposureEffect.md) |

## Connecting

gaiaCore opens a JDBC connection with DatabaseConnector; there is no
REST layer in between.

- From another container on the Gaia Docker network use the defaults
  (`server = "gaia-db/gaiacore"`, port 5432).
- From the host use the published port, for example
  `createGaiaConnectionDetails(server = "localhost/gaiacore", port = 5433)`.
- The password is read from the environment variable
  `GAIA_POSTGRES_PASSWORD` unless you pass it.

## Getting help

Please open an issue on the [issue
tracker](https://github.com/OHDSI/gaiaCore/issues) or ask on the [OHDSI
forums](https://forums.ohdsi.org) (GIS working group).

## License

gaiaCore is licensed under Apache License 2.0.
