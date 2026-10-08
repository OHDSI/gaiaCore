# Changelog

## gaiaCore 0.1.0

- gaiaCore is now an R package. It connects to gaiaDB directly with
  DatabaseConnector and wraps the Gaia pipeline (catalog ingestion,
  location loading, the spatial-temporal join, quality checks, copy into
  an OMOP CDM).
- Analytics:
  [`dayWeightedExposure()`](https://ohdsi.github.io/gaiaCore/reference/dayWeightedExposure.md)
  and
  [`fitExposureEffect()`](https://ohdsi.github.io/gaiaCore/reference/fitExposureEffect.md)
  (jackknife, clustered and mixed-model intervals).
- A Docker image (`ohdsi/gaia-core`) with HADES, gaiaCore and the
  extension packages.
- The Python, Java, Julia, Bash and PostgREST-based R connectors moved
  to the `connectors` branch (tag `connectors-v1`).
