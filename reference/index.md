# Package index

## Connect

- [`createGaiaConnectionDetails()`](https://ohdsi.github.io/gaiaCore/reference/createGaiaConnectionDetails.md)
  : Connection details for a Gaia database
- [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md)
  : Connect to a Gaia database
- [`disconnectGaia()`](https://ohdsi.github.io/gaiaCore/reference/disconnectGaia.md)
  : Disconnect from a Gaia database

## Catalog and ingestion

- [`ingestDatasource()`](https://ohdsi.github.io/gaiaCore/reference/ingestDatasource.md)
  : Ingest a dataset registered in the Gaia catalog
- [`loadVariables()`](https://ohdsi.github.io/gaiaCore/reference/loadVariables.md)
  : Build the geometry and attribute tables of an ingested dataset
- [`listDatasources()`](https://ohdsi.github.io/gaiaCore/reference/listDatasources.md)
  : Datasets registered in the database
- [`listVariables()`](https://ohdsi.github.io/gaiaCore/reference/listVariables.md)
  : Variables registered in the attribute index

## Locations

- [`loadLocationsFromOmop()`](https://ohdsi.github.io/gaiaCore/reference/loadLocationsFromOmop.md)
  : Load person locations from an OMOP CDM with the Gaia extension
- [`loadLocations()`](https://ohdsi.github.io/gaiaCore/reference/loadLocations.md)
  : Load person locations from data frames
- [`validateLocations()`](https://ohdsi.github.io/gaiaCore/reference/validateLocations.md)
  : Validate the loaded locations

## Exposure

- [`spatialJoin()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoin.md)
  : Derive exposures with Gaia's spatial-temporal join
- [`spatialJoinAll()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoinAll.md)
  : Derive exposures for every variable of a dataset
- [`summarizeExposure()`](https://ohdsi.github.io/gaiaCore/reference/summarizeExposure.md)
  : Summarise the derived exposure rows
- [`getExposure()`](https://ohdsi.github.io/gaiaCore/reference/getExposure.md)
  : Fetch derived exposure rows
- [`clearExposure()`](https://ohdsi.github.io/gaiaCore/reference/clearExposure.md)
  : Remove derived exposure rows
- [`copyExposureToOmop()`](https://ohdsi.github.io/gaiaCore/reference/copyExposureToOmop.md)
  : Copy derived exposure into an OMOP CDM

## Quality

- [`checkExposure()`](https://ohdsi.github.io/gaiaCore/reference/checkExposure.md)
  : Quality checks on the derived exposure rows
- [`checkStagedExposure()`](https://ohdsi.github.io/gaiaCore/reference/checkStagedExposure.md)
  : Quality checks on staged exposure rows

## Analytics

- [`dayWeightedExposure()`](https://ohdsi.github.io/gaiaCore/reference/dayWeightedExposure.md)
  : Day-weighted exposure over windows
- [`fitExposureEffect()`](https://ohdsi.github.io/gaiaCore/reference/fitExposureEffect.md)
  : Effect of an exposure on a binary outcome, with intervals that hold
  up with few clusters
