# PostgREST API Access Guide

## Quick Start

The PostgREST API is available at `http://localhost:3000`

## Accessing Tables from Different Schemas

gaiaCore uses two schemas:
- **backbone**: Metadata tables (data_source, variable_source, geom_template, attr_template)
- **working**: Operational tables (location, location_history, external_exposure)

### Schema Profile Headers

When accessing tables, you need to specify which schema using the `Accept-Profile` header:

```bash
# Access working schema tables
curl -H "Accept-Profile: working" http://localhost:3000/location
curl -H "Accept-Profile: working" http://localhost:3000/location_history
curl -H "Accept-Profile: working" http://localhost:3000/external_exposure

# Access backbone schema tables (default if no header)
curl http://localhost:3000/data_source
curl http://localhost:3000/variable_source
curl http://localhost:3000/geom_template
curl http://localhost:3000/attr_template
```

### Why Headers Are Needed

PostgREST exposes both schemas (`backbone` and `working`) as configured in `PGRST_DB_SCHEMAS`. When you don't specify a schema profile, PostgREST defaults to the first schema listed (`backbone`). To access tables in other schemas, use the `Accept-Profile` header.

## API Examples

### 1. Query Location Data

```bash
# Get all locations
curl -H "Accept-Profile: working" http://localhost:3000/location | jq '.'

# Get specific location by ID
curl -H "Accept-Profile: working" "http://localhost:3000/location?location_id=eq.1" | jq '.'

# Filter locations by city
curl -H "Accept-Profile: working" "http://localhost:3000/location?city=eq.FRESNO" | jq '.'

# Select specific columns
curl -H "Accept-Profile: working" "http://localhost:3000/location?select=location_id,address_1,city,latitude,longitude" | jq '.'

# Limit results
curl -H "Accept-Profile: working" "http://localhost:3000/location?limit=10" | jq '.'
```

### 2. Query Location History

```bash
# Get all location history
curl -H "Accept-Profile: working" http://localhost:3000/location_history | jq '.'

# Get location history for specific location
curl -H "Accept-Profile: working" "http://localhost:3000/location_history?location_id=eq.1" | jq '.'

# Join location and location_history
curl -H "Accept-Profile: working" "http://localhost:3000/location?select=*,location_history(*)" | jq '.'
```

### 3. Query External Exposure Results

```bash
# Get all exposure results
curl -H "Accept-Profile: working" http://localhost:3000/external_exposure | jq '.'

# Filter by location
curl -H "Accept-Profile: working" "http://localhost:3000/external_exposure?location_id=eq.1" | jq '.'
```

### 4. Query Metadata Tables

```bash
# Get all data sources (backbone schema - no header needed)
curl http://localhost:3000/data_source | jq '.'

# Get all variables
curl http://localhost:3000/variable_source | jq '.'

# Get specific data source with its variables
curl "http://localhost:3000/data_source?select=*,variable_source(*)" | jq '.'
```

### 5. Call PostgreSQL Functions

```bash
# Load JSON-LD metadata
curl -X POST http://localhost:3000/rpc/load_jsonld_file \
  -H "Content-Type: application/json" \
  -H "Accept-Profile: backbone" \
  -d '{"jsonld_text": "..."}'

# List downloadable data sources
curl -X POST http://localhost:3000/rpc/list_downloadable_datasources \
  -H "Accept-Profile: backbone" \
  -H "Content-Type: application/json"

# Quick ingest data source
curl -X POST http://localhost:3000/rpc/quick_ingest_datasource \
  -H "Accept-Profile: backbone" \
  -H "Content-Type: application/json" \
  -d '{"p_dataset_name": "example_dataset", "p_download_url": "https://..."}'
```

## Common Filters

PostgREST supports powerful filtering:

```bash
# Equality
?column=eq.value

# Greater than / Less than
?column=gt.value
?column=lt.value
?column=gte.value
?column=lte.value

# Pattern matching
?column=like.*pattern*
?column=ilike.*pattern*  # case insensitive

# In list
?column=in.(value1,value2,value3)

# Null checks
?column=is.null
?column=not.is.null

# Combining filters (AND)
?column1=eq.value1&column2=eq.value2

# Ordering
?order=column.asc
?order=column.desc

# Pagination
?limit=10&offset=20
```

## CORS for Web Applications

If accessing from a web browser, you may need to enable CORS. Add this to `postgrest.conf`:

```
server-cors-allowed-origins = "*"
```

Then restart the PostgREST container:
```bash
docker restart gaiacore-postgrest
```

## OpenAPI Documentation

View the auto-generated API documentation:
```bash
curl http://localhost:3000/ | jq '.'
```

Or open in your browser: http://localhost:3000/

## Common Issues

### Error: "Could not find the table 'backbone.location' in the schema cache"

**Solution**: Add the `Accept-Profile: working` header to access tables in the working schema.

### Empty Result Set

**Solutions**:
1. Check the table has data: `docker exec gaiacore-postgres psql -U postgres -d gaiacore -c "SELECT count(*) FROM working.location;"`
2. Verify your filter syntax
3. Check permissions

### 401 Unauthorized

**Solution**: Verify the `PGRST_DB_ANON_ROLE` has proper grants:
```sql
GRANT USAGE ON SCHEMA working TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA working TO postgres;
```

## Further Reading

- [PostgREST Documentation](https://postgrest.org/en/stable/)
- [PostgREST API Tutorial](https://postgrest.org/en/stable/tutorials/tut0.html)
- [Schema Isolation](https://postgrest.org/en/stable/references/schema_isolation.html)
