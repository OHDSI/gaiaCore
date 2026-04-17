# gaiaCore End-to-End Pipeline Guide

## Overview

All gaiaCore connectors support running the complete end-to-end pipeline:

1. **Load JSON-LD Metadata** - Fetch and ingest dataset metadata from URL
2. **Load Location Data** - Import LOCATION and LOCATION_HISTORY CSV files
3. **Ingest Data Source** - Download and load external data automatically
4. **Calculate Exposures** - Perform spatial join to link locations with exposures

## Running the Pipeline

### Using Docker Compose Profiles

```bash
# Start gaiaCore core services
docker-compose up -d gaiacore-db gaiacore-api

# Run pipeline with the python connector
docker-compose --profile python up connector-python

# Run pipeline with the connector of your choice
docker-compose --profile {some connector} up connector-{some connector}


```

## Pipeline Methods

> Note - the methods in this section assume you're running the processes from inside a Docker container on the gaiacore-network
> If you are instead running the processes locally, you'll need to change the url from `http://gaiacore-api:3000` to something
> like `http://localhost:3000`

### Python

```python
from gaiacore_client import GaiaCoreClient

client = GaiaCoreClient("http://gaiacore-api:3000")

# Full automated pipeline
results = client.run_full_pipeline(
    metadata_url="https://example.com/metadata.json",
    location_csv="/csv/LOCATION.csv",
    location_history_csv="/csv/LOCATION_HISTORY.csv",
    variable_source_id="avpmu_2015",
    verbose=True
)

# Or step-by-step
metadata = client.fetch_and_load_jsonld(metadata_url)
locations = client.load_location_data(location_csv, location_history_csv)
ingestion = client.quick_ingest_datasource(dataset_name)
spatial_join = client.spatial_join_exposure(variable_id, external_table)
```

### R

```r
source("gaiacore_client.R")
client <- GaiaCoreClient$new("http://gaiacore-api:3000")

# Step-by-step pipeline
metadata <- client$fetch_and_load_jsonld(metadata_url)
locations <- client$load_location_data(location_csv, location_history_csv)
ingestion <- client$quick_ingest_datasource(dataset_name)
spatial_join <- client$spatial_join_exposure(variable_id, external_table)
```

### Bash

```bash
source gaiacore_client.sh
gaiacore_init "http://gaiacore-api:3000"

# Step-by-step pipeline
gaiacore_fetch_and_load_jsonld "$METADATA_URL"
gaiacore_rpc "load_location_data" '{"p_location_file":"/csv/LOCATION.csv","p_location_history_file":"/csv/LOCATION_HISTORY.csv"}' "working"
gaiacore_quick_ingest_datasource "$DATASET_NAME"
gaiacore_rpc "spatial_join_exposure" '{"p_variable_source_id":"avpmu_2015","p_external_table":"public.pm25"}' "working"
```

### Julia

```julia
include("GaiaCoreClient.jl")
using .GaiaCore

client = GaiaCoreClient("http://gaiacore-api:3000")

# Step-by-step pipeline
metadata = fetch_and_load_jsonld(client, metadata_url)
locations = load_location_data(client, location_csv, location_history_csv)
ingestion = quick_ingest_datasource(client, dataset_name)
spatial_join = spatial_join_exposure(client, variable_id, external_table)
```

### Java

```java
GaiaCoreClient client = new GaiaCoreClient("http://gaiacore-api:3000");

// Step-by-step pipeline
Map<String, Object> metadata = client.fetchAndLoadJsonld(metadataUrl);
Map<String, Object> locations = client.loadLocationData(locationCsv, locationHistoryCsv);
List<Map<String, Object>> ingestion = client.quickIngestDatasource(datasetName, null);
Map<String, Object> spatialJoin = client.spatialJoinExposure(variableId, externalTable);
```

## Pipeline Steps Explained

### Step 1: Load JSON-LD Metadata

Fetches dataset metadata from a URL and loads it into the `backbone.data_source` and `backbone.variable_source` tables.

**Input:**
- URL to JSON-LD metadata file

**Output:**
- `data_source_uuid` - UUID of the created data source
- `dataset_name` - Name of the dataset
- `variables_loaded` - Number of variables extracted

**Example:**
```python
result = client.fetch_and_load_jsonld(
    "https://example.com/metadata/pm25_dataset.json"
)
print(f"Loaded {result['dataset_name']} with {result['variables_loaded']} variables")
```

### Step 2: Load Location Data

Imports LOCATION and LOCATION_HISTORY CSV files into the `working.location` and `working.location_history` tables.

**Input:**
- Path to LOCATION.csv
- Path to LOCATION_HISTORY.csv

**Output:**
- Success/failure status
- Number of records loaded

**Example:**
```python
result = client.load_location_data(
    "/csv/LOCATION.csv",
    "/csv/LOCATION_HISTORY.csv"
)
```

### Step 3: Ingest Data Source

Automatically downloads, extracts, and loads the external data source into PostgreSQL.

**Input:**
- Dataset name (from metadata)

**Output:**
- Step-by-step progress
- Final table location (schema.table)

**Example:**
```python
steps = client.quick_ingest_datasource("PM2.5 Dataset")
for step in steps:
    print(f"{step['step']}: {step['status']}")
```

### Step 4: Calculate Exposures

Performs a spatial join between locations and the external data source to calculate exposure values.

**Input:**
- Variable source ID (e.g., "avpmu_2015")
- External table name (e.g., "public.pm25_table")

**Output:**
- Records inserted into `working.external_exposure`

**Example:**
```python
result = client.spatial_join_exposure(
    "avpmu_2015",
    "public.annual_pm2_5_concentrations"
)
```

## Customizing the Pipeline

### Custom Metadata URL

```bash
# Python
python pipeline_example.py http://localhost:3000 https://myserver.com/metadata.json

# Bash
./pipeline_example.sh http://localhost:3000 https://myserver.com/metadata.json
```

### Skip Spatial Join

Omit the `variable_source_id` parameter to skip the spatial join step:

```python
results = client.run_full_pipeline(
    metadata_url=url,
    location_csv="/csv/LOCATION.csv",
    location_history_csv="/csv/LOCATION_HISTORY.csv",
    variable_source_id=None,  # Skip spatial join
    verbose=True
)
```

### Custom CSV Paths

```python
results = client.run_full_pipeline(
    metadata_url=url,
    location_csv="/data/custom_locations.csv",
    location_history_csv="/data/custom_history.csv",
    variable_source_id="pm25_2016"
)
```

## Error Handling

All pipeline methods include error handling and will return detailed error information:

```python
results = client.run_full_pipeline(metadata_url=url)

if results["errors"]:
    print("Pipeline encountered errors:")
    for error in results["errors"]:
        print(f"  - {error}")
else:
    print("Pipeline completed successfully!")
```

## Querying Results

After running the pipeline, query the exposure results:

```python
# Get exposure results
exposures = client.get_exposures(limit=100)

# Get specific person's exposures
person_exposures = client.get_exposures(person_id=123)

# Get exposures at a location
location_exposures = client.get_exposures(location_id=456)

# Join with location data
results = client.query(
    "external_exposure",
    schema="working",
    select="*,location(*)",
    limit=50
)
```

## Docker Compose Integration

The main `docker-compose.yml` includes all connectors with profile-based activation:

```yaml
services:
  connector-python:
    profiles: ["connectors", "python"]
    # ...

  connector-r:
    profiles: ["connectors", "r"]
    # ...
```

**Usage:**
```bash
# Run specific connector
docker-compose --profile python up

# Run all connectors
docker-compose --profile connectors up

# Run core + one connector
docker-compose up -d gaiacore-db gaiacore-api
docker-compose --profile python up connector-python
```

## Performance Considerations

- **Metadata loading**: Fast (< 1 second)
- **Location loading**: Depends on CSV size (typically < 10 seconds)
- **Data ingestion**: Depends on data source size (can take minutes for large datasets)
- **Spatial join**: Depends on number of locations and spatial complexity (typically < 1 minute)

## Troubleshooting

### Pipeline Stuck on Ingestion

Large data sources can take several minutes to download and process. Check the progress:

```python
# Enable verbose mode
results = client.run_full_pipeline(metadata_url=url, verbose=True)
```

### Metadata URL Not Found

Ensure the URL is publicly accessible:

```bash
curl -I https://example.com/metadata.json
```

### CSV Files Not Found

Verify the CSV files are mounted in the correct Docker volume:

```yaml
volumes:
  - ./test/omop:/csv  # LOCATION.csv should be here
```

### Spatial Join Fails

Check that the ingested table has a geometry column:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'your_table_name'
AND column_name LIKE '%geom%';
```

## Advanced Usage

### Custom Pipeline Logic

```python
# Run specific steps only
client = GaiaCoreClient("http://localhost:3000")

# Load metadata
metadata = client.fetch_and_load_jsonld(url)
dataset_uuid = metadata[0]["data_source_uuid"]

# Load locations
client.load_location_data("/csv/LOCATION.csv", "/csv/LOCATION_HISTORY.csv")

# Skip ingestion, run spatial join on existing data
client.spatial_join_exposure("pm25_2015", "public.existing_table")
```

### Batch Processing

```python
# Process multiple datasets
metadata_urls = [
    "https://example.com/dataset1.json",
    "https://example.com/dataset2.json",
    "https://example.com/dataset3.json"
]

for url in metadata_urls:
    print(f"\nProcessing: {url}")
    results = client.run_full_pipeline(url)
    if not results["errors"]:
        print(f"  ✓ Success")
    else:
        print(f"  ✗ Failed: {results['errors']}")
```

## Further Reading

- [PostgREST API Guide](../POSTGREST_API_GUIDE.md)
