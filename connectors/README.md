# gaiaCore API Connectors

Multi-language client libraries for interacting with the gaiaCore PostgREST API.


## Usage Examples

### Python

```python
from gaiacore_client import GaiaCoreClient

client = GaiaCoreClient("http://gaiacore-api:3000")
sources = client.get_data_sources()
locations = client.get_locations(city="FRESNO", limit=10)
exposures = client.get_exposures(person_id=123)
```

### R

```r
source("gaiacore_client.R")

client <- GaiaCoreClient$new("http://gaiacore-api:3000")
sources <- client$get_data_sources()
locations <- client$get_locations(city = "FRESNO", limit = 10)
df <- client$to_dataframe(locations)
```

### Bash

```bash
source gaiacore_client.sh

gaiacore_init "http://gaiacore-api:3000"
gaiacore_get_data_sources | jq '.'
gaiacore_get_locations "FRESNO" "" 10 | jq '.'
```

### Julia

```julia
include("GaiaCoreClient.jl")
using .GaiaCore

client = GaiaCoreClient("http://gaiacore-api:3000")
sources = get_data_sources(client)
locations = get_locations(client; city="FRESNO", limit=10)
```

### Java

```java
GaiaCoreClient client = new GaiaCoreClient("http://gaiacore-api:3000");
List<Map<String, Object>> sources = client.getDataSources();
List<Map<String, Object>> locations = client.getLocations("FRESNO", null, 10);
```

## Common Operations

All clients support these operations:

### Data Sources
- Get all data sources
- Get specific data source by UUID
- List downloadable data sources with URLs

### Variables
- Get variable definitions for a data source

### Locations
- Query locations with filters (city, state)
- Get specific location by ID
- Get location history for person/entity

### Exposures
- Query external exposure data
- Filter by person ID, location ID
- Get exposure values and dates

### Data Ingestion
- Fetch and load JSON-LD metadata from URL
- Quick ingest data source by name
- Automated download and processing

### Advanced Queries
- Full PostgREST query capabilities
- Column selection
- Filtering, ordering, pagination


## Contributing

To add a new language connector:

1. Create a new directory: `connectors/newlang/`
2. Implement the client library (see, for example, connectors/julia/GaiaCoreClient.jl)
3. Create a `Dockerfile`
5. Update this main `README.md`
6. Add to the overall `docker-compose.yml` with its own new profile

## Documentation

- [PostgREST API Guide](../POSTGREST_API_GUIDE.md) - API endpoint documentation

## License

Apache
