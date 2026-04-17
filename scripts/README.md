# gaiaCore Scripts

## init_gaiacore.sh

Client-side data loader script that loads test data from the gaiaCore repository into a gaiaDB database instance.


### Usage

#### Scenario 1: Using gaiaCore's Local docker-compose (Development)

This setup runs everything locally for development/testing:

```bash
# Start local gaiaCore database and API
docker-compose up -d

# Wait for services to be ready
sleep 10

# Load test data from host filesystem
./scripts/init_gaiacore.sh

# Or explicitly set connection params
DB_HOST=localhost DB_PORT=5432 ./scripts/init_gaiacore.sh
```

#### Scenario 2: Using gaiaDocker (Production/Full Stack)

This setup uses the gaiaDocker orchestration with separate gaiaDB service:

```bash
# Start the full GAIA stack (in gaiaDocker repository)
cd gaiaDocker
docker-compose --profile gaia up -d

# Load test data from gaiaCore repository (on host)
cd ../gaiaCore
DB_HOST=localhost DB_PORT=5433 ./scripts/init_gaiacore.sh

# Note: gaiaDocker exposes PostgreSQL on port 5433 by default
```

#### Scenario 3: Running Inside a Connector Container

If you want to run the init script from within a connector container:

```bash
# Start connector with gaiaCore mounted
docker-compose --profile python up -d connector-python

# Execute script inside container
docker exec -it gaiacore-python-connector bash -c "
  cd /app && \
  DB_HOST=gaiacore-db DB_PORT=5432 ./scripts/init_gaiacore.sh
"
```

#### Scenario 4: Remote Database

Connect to a remote gaiaDB instance:

```bash
DB_HOST=remote.example.com \
DB_PORT=5432 \
DB_NAME=gaiacore \
DB_USER=postgres \
PGPASSWORD=secret \
./scripts/init_gaiacore.sh
```

### Environment Variables

The script supports the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | Database server hostname or IP |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `gaiacore` | Database name |
| `DB_USER` | `postgres` | Database user |
| `API_URL` | `http://localhost:3000` | PostgREST API URL (for display only) |
| `PGPASSWORD` | (none) | Password for PostgreSQL connection |

### What the Script Does

1. **Waits for Database**: Uses `pg_isready` to wait for PostgreSQL to be available
2. **Validates Files**: Checks that required CSV and JSON files exist
3. **Loads Location Data**:
   - Creates temporary tables
   - Uses `\copy` to load `LOCATION.csv` from client filesystem
   - Transforms and inserts into `working.location` table
   - Creates PostGIS geometries from lat/lon
4. **Loads Location History**:
   - Uses `\copy` to load `LOCATION_HISTORY.csv`
   - Inserts into `working.location_history` table
5. **Loads JSON-LD Metadata** (if file exists):
   - Reads JSON file content
   - Escapes for SQL
   - Calls `backbone.ingest_jsonld_metadata()` function
6. **Displays Summary**: Shows connection info and available API endpoints

### Requirements

- `psql` client installed
- Network access to the database server
- Permission to read files in `./test/omop/` and `./test/data_source/`
- Database must have gaiaDB schema with backbone and working schemas

### Test Data Files

The script expects the following files (relative to gaiaCore repository root):

- `./test/omop/LOCATION.csv` - Sample location records
- `./test/omop/LOCATION_HISTORY.csv` - Sample location history records
- `./test/data_source/meta_json-ld_global_pm25_concentration_1998_2016.json` - Sample JSON-LD metadata (optional)

### Output Example

```
==================================================
gaiaCore Client-Side Data Loader
==================================================
Database: localhost:5432/gaiacore
API: http://localhost:3000

Waiting for database to be ready...
✓ PostgreSQL is ready

Loading LOCATION data from client filesystem...
✓ LOCATION data loaded

Loading LOCATION_HISTORY data from client filesystem...
✓ LOCATION_HISTORY data loaded

Loading JSON-LD metadata from client filesystem...
✓ JSON-LD metadata loaded

==================================================
Data Loading Complete!

Database Connection:
  Host: localhost
  Port: 5432
  Database: gaiacore
  User: postgres

PostgREST API: http://localhost:3000
...
==================================================
```

### Integration with Connectors

After running this script, you can use any of the gaiaCore connectors to interact with the loaded data:

```bash
# Python example
cd connectors/python
python example.py http://localhost:3000

# R example
cd connectors/r
Rscript example.R http://localhost:3000
```

See the individual connector README files for more details.
