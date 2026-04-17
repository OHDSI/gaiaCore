# gaiaCore

A collection of **connector libraries and examples** demonstrating how to interact with the GAIA geospatial exposure analysis platform via the PostgREST API.

## Overview

**gaiaCore** provides reference implementations and client libraries in multiple programming languages for working with GAIA (Geospatial Analysis of Integrated Attributes). It includes:

- **Multi-language connectors**: Python, R, Julia, Java, and Bash
- **PostgREST API documentation**: Guide for querying via HTTP
- **Example workflows**: Complete pipeline demonstrations
- **Test data**: Sample datasets for development and testing

## Architecture

The GAIA platform is split across three repositories:

| Repository | Purpose | Contents |
|------------|---------|----------|
| **[gaiaDB](https://github.com/OHDSI/gaiaDB)** | Database schema & functions | PostgreSQL schema, SQL functions, init scripts |
| **[gaiaDocker](https://github.com/OHDSI/gaiaDocker)** | Orchestration & deployment | Docker compose, PostgREST service, utilities |
| **gaiaCore** (this repo) | Connectors & examples | Client libraries, API docs, test data |

## What gaiaCore Does

gaiaCore helps you interact with a GAIA database instance (gaiaDB) through:

1. **Client Libraries**: Pre-built connectors that wrap the PostgREST API
2. **Example Scripts**: Working examples of common workflows
3. **API Documentation**: Detailed guide to using the REST endpoints
4. **Test Data**: Sample OMOP location data and JSON-LD metadata

## Quick Start

### Option 1: Use gaiaDocker (Recommended for Production)

For a complete GAIA deployment with all services:

```bash
# Clone gaiaDocker repository
git clone https://github.com/OHDSI/gaiaDocker.git
cd gaiaDocker

# Start the full GAIA stack
docker-compose --profile gaia up -d

# This starts:
# - gaia-db (PostgreSQL with PostGIS and GAIA schema)
# - gaia-postgrest (RESTful API on port 3000)
# - gaia-catalog, gaia-solr, and utility services
```

Then load test data from gaiaCore:

```bash
# Clone gaiaCore repository
cd ..
git clone https://github.com/OHDSI/gaiaCore.git
cd gaiaCore

# Load test OMOP location data
DB_HOST=localhost DB_PORT=5433 DB_NAME=gaiaDB ./scripts/init_gaiacore.sh

# Now use the connectors
cd connectors/python
python example.py http://localhost:3000
```

### Option 2: Local Development (Quick Testing)

For quick local testing without the full stack:

```bash
# Clone gaiaCore
git clone https://github.com/OHDSI/gaiaCore.git
cd gaiaCore

# Start local database and API
docker-compose up -d gaiacore-db gaiacore-api

# Load test data
./scripts/init_gaiacore.sh

# Test the API
curl http://localhost:3000/data_source
```

**Note:** The local docker-compose in gaiaCore is for development/testing only. For production, use [gaiaDocker](https://github.com/OHDSI/gaiaDocker).

## Connectors

gaiaCore includes client libraries in multiple languages:

### Python
```bash
cd connectors/python
python example.py http://localhost:3000
python pipeline_example.py http://localhost:3000
```

### R
```bash
cd connectors/r
Rscript example.R http://localhost:3000
Rscript pipeline_example.R http://localhost:3000
```

### Julia
```bash
cd connectors/julia
julia example.jl http://localhost:3000
julia pipeline_example.jl http://localhost:3000
```

### Java
```bash
cd connectors/java
mvn compile
mvn exec:java -Dexec.mainClass=Example -Dexec.args="http://localhost:3000"
```

### Bash
```bash
cd connectors/bash
./example.sh http://localhost:3000
./pipeline_example.sh http://localhost:3000
```

Each connector provides:
- **Client library**: Reusable functions for common operations
- **Example script**: Simple demonstration of basic queries
- **Pipeline example**: Complete end-to-end workflow

See [connectors/README.md](connectors/README.md) and [connectors/PIPELINE_GUIDE.md](connectors/PIPELINE_GUIDE.md) for details.

## PostgREST API Overview

The GAIA platform exposes a RESTful API via PostgREST. For complete documentation, see [POSTGREST_API_GUIDE.md](POSTGREST_API_GUIDE.md).

### Basic Queries

```bash
# List data sources (backbone schema - default)
curl http://localhost:3000/data_source

# Get variables for a data source
curl "http://localhost:3000/variable_source?data_source_uuid=eq.<uuid>"

# Query location data (working schema - requires header)
curl -H "Accept-Profile: working" http://localhost:3000/location

# Get exposure data for a person
curl -H "Accept-Profile: working" "http://localhost:3000/external_exposure?person_id=eq.1234"

# OpenAPI documentation
curl http://localhost:3000/
```

### Calling Database Functions (RPC)

```bash
# Quick ingest a dataset
curl -X POST http://localhost:3000/rpc/quick_ingest_datasource \
  -H "Content-Type: application/json" \
  -d '{"p_dataset_name": "PM2.5"}'

# List downloadable data sources
curl -X POST http://localhost:3000/rpc/list_downloadable_datasources

# Get statistics
curl -X POST http://localhost:3000/rpc/location_statistics
curl -X POST http://localhost:3000/rpc/exposure_statistics
```

**Important:** Tables in the `working` schema (location, location_history, external_exposure) require the `Accept-Profile: working` header.

## Loading Test Data

The `scripts/init_gaiacore.sh` script loads sample data from the client filesystem:

```bash
# Load to local database
./scripts/init_gaiacore.sh

# Load to gaiaDocker instance (port 5433)
DB_HOST=localhost DB_PORT=5433 DB_NAME=gaiaDB ./scripts/init_gaiacore.sh

# Load to remote database
DB_HOST=remote.example.com DB_USER=myuser PGPASSWORD=secret ./scripts/init_gaiacore.sh
```

This loads:
- **LOCATION.csv**: 20 sample geocoded addresses
- **LOCATION_HISTORY.csv**: Person-location-time relationships
- **meta_json-ld_global_pm25_concentration_1998_2016.json**: Sample JSON-LD metadata

See [scripts/README.md](scripts/README.md) for details.

## Test Data

Sample data is included in the `test/` directory:

- `test/omop/LOCATION.csv` - Sample OMOP location records
- `test/omop/LOCATION_HISTORY.csv` - Location history records
- `test/data_source/meta_json-ld_global_pm25_concentration_1998_2016.json` - JSON-LD metadata

## Database Schema & Functions

**For database schema, SQL functions, and detailed technical documentation, see:**

- **[gaiaDB Repository](https://github.com/OHDSI/gaiaDB)** - PostgreSQL schema, functions, and initialization scripts

### Key Schemas

- **backbone**: Core metadata tables (data_source, variable_source, geom_template, attr_template)
- **working**: Operational tables (location, location_history, external_exposure)
- **vocabulary**: OMOP vocabulary tables

### Key Functions

gaiaDB provides SQL functions for:
- JSON-LD metadata ingestion
- Automated data source retrieval
- Location data loading
- Spatial join operations
- Exposure calculations

See the [gaiaDB documentation](https://github.com/OHDSI/gaiaDB) for complete function reference.

## Deployment

**For production deployment with Docker Compose, see:**

- **[gaiaDocker Repository](https://github.com/OHDSI/gaiaDocker)** - Full stack orchestration

gaiaDocker provides:
- PostgreSQL with PostGIS and GAIA schema
- PostgREST API service
- Solr search index
- Data catalog interface
- Utility services (GDAL, PostGIS tools, etc.)

## Example Workflow

Here's a complete example using the Python connector:

```python
from gaiacore_client import GaiaCoreClient

# Initialize client
client = GaiaCoreClient("http://localhost:3000")

# 1. Load JSON-LD metadata
result = client.call_function(
    "load_jsonld_file",
    {"p_jsonld_content": open("metadata.json").read()}
)

# 2. Load location data
client.load_csv_to_table(
    "working.location",
    "test/omop/LOCATION.csv"
)

# 3. List downloadable data sources
sources = client.call_function("list_downloadable_datasources")
print(f"Found {len(sources)} data sources")

# 4. Ingest a dataset
result = client.call_function(
    "quick_ingest_datasource",
    {"p_dataset_name": "PM2.5"}
)

# 5. Perform spatial join
result = client.call_function(
    "spatial_join_exposure",
    {
        "p_variable_name": "avpmu_2015",
        "p_data_source_table": "public.pm25_data"
    }
)

# 6. Query exposure results
exposures = client.get_data(
    "external_exposure",
    schema="working",
    filters={"person_id": "gt.0"},
    limit=10
)

for exposure in exposures:
    print(f"Person {exposure['person_id']}: {exposure['value_as_number']}")
```

See [connectors/PIPELINE_GUIDE.md](connectors/PIPELINE_GUIDE.md) for detailed workflow examples in all languages.

## API Documentation

For complete PostgREST API reference:

- **[POSTGREST_API_GUIDE.md](POSTGREST_API_GUIDE.md)** - Detailed API usage guide
- **http://localhost:3000/** - Live OpenAPI documentation (when running)

## Development

### Running Connectors in Docker

The docker-compose.yml includes connector services you can use:

```bash
# Python connector
docker-compose --profile python up -d connector-python
docker exec -it gaiacore-python-connector python /app/example.py

# R connector
docker-compose --profile r up -d connector-r
docker exec -it gaiacore-r-connector Rscript /app/example.R

# All connectors
docker-compose --profile connectors up -d
```

### Testing Local Changes

```bash
# Rebuild database
docker-compose down -v
docker-compose build --no-cache gaiacore-db
docker-compose up -d

# Load test data
./scripts/init_gaiacore.sh

# Run connector tests
cd connectors/python
python pipeline_example.py http://localhost:3000
```

## Troubleshooting

### Port Conflicts

If port 5432 or 3000 is already in use:

```yaml
# Edit docker-compose.yml
ports:
  - "5433:5432"  # PostgreSQL
  - "3001:3000"  # PostgREST
```

### Connection Issues

```bash
# Check database is running
docker ps

# Check database health
docker exec -it gaiacore-postgres pg_isready -U postgres

# View API logs
docker-compose logs gaiacore-api
```

### Working Schema Access

Tables in the `working` schema require the `Accept-Profile` header:

```bash
# Correct
curl -H "Accept-Profile: working" http://localhost:3000/location

# Wrong (returns 404)
curl http://localhost:3000/location
```

See [POSTGREST_API_GUIDE.md](POSTGREST_API_GUIDE.md) for details.

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Add/update connectors or examples
4. Test against a gaiaDB instance
5. Submit a pull request

For database schema changes, contribute to [gaiaDB](https://github.com/OHDSI/gaiaDB).
For deployment/orchestration changes, contribute to [gaiaDocker](https://github.com/OHDSI/gaiaDocker).

## Related Projects

- **[gaiaDB](https://github.com/OHDSI/gaiaDB)** - PostgreSQL database schema and functions
- **[gaiaDocker](https://github.com/OHDSI/gaiaDocker)** - Docker orchestration and deployment
- **[gaiaCatalog](https://github.com/OHDSI/gaiaCatalog)** - Data source catalog and search
- **[OMOP CDM](https://ohdsi.github.io/CommonDataModel/)** - Observational Medical Outcomes Partnership Common Data Model

## References

- [PostgREST Documentation](https://postgrest.org/)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [LinkML](https://linkml.io/) - Linked Data Modeling Language
- [JSON-LD](https://json-ld.org/) - JSON for Linking Data
- [OMOP CDM](https://ohdsi.github.io/CommonDataModel/)

## License

See LICENSE file for details.

## Support

For issues and questions:

- **Connector/API issues**: Open an issue in this repository
- **Database/schema issues**: Open an issue in [gaiaDB](https://github.com/OHDSI/gaiaDB/issues)
- **Deployment issues**: Open an issue in [gaiaDocker](https://github.com/OHDSI/gaiaDocker/issues)
