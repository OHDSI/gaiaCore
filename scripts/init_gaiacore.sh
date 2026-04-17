#!/bin/sh
# gaiaCore Initialization Script
# This script loads test data from CLIENT-SIDE filesystem to the gaiaDB service
# Run from gaiaCore repository root directory

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-gaiacore}"
DB_USER="${DB_USER:-postgres}"
API_URL="${API_URL:-http://localhost:3000}"

# Paths to test data (relative to repository root)
LOCATION_CSV="./test/omop/LOCATION.csv"
LOCATION_HISTORY_CSV="./test/omop/LOCATION_HISTORY.csv"
JSONLD_FILE="./test/data_source/meta_json-ld_global_pm25_concentration_1998_2016.json"

echo "=================================================="
echo "gaiaCore Client-Side Data Loader"
echo "=================================================="
echo "Database: $DB_HOST:$DB_PORT/$DB_NAME"
echo "API: $API_URL"
echo ""

# Wait for PostgreSQL to be ready
echo "Waiting for database to be ready..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" 2>/dev/null; do
  echo "  Still waiting for PostgreSQL at $DB_HOST:$DB_PORT..."
  sleep 2
done
echo "PostgreSQL is ready"
echo ""

# Check for required files
if [ ! -f "$LOCATION_CSV" ]; then
    echo "ERROR: LOCATION.csv not found at $LOCATION_CSV"
    echo "Make sure you run this script from the gaiaCore repository root"
    exit 1
fi

if [ ! -f "$LOCATION_HISTORY_CSV" ]; then
    echo "ERROR: LOCATION_HISTORY.csv not found at $LOCATION_HISTORY_CSV"
    exit 1
fi

# Load LOCATION data using client-side COPY
echo "Loading LOCATION data from client filesystem..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
    -- Create temp table for client-side data load
    CREATE TEMP TABLE IF NOT EXISTS temp_location (
        location_id INTEGER,
        address_1 TEXT,
        address_2 TEXT,
        city TEXT,
        state TEXT,
        zip TEXT,
        county TEXT,
        location_source_value TEXT,
        country_concept_id INTEGER,
        country_source_value TEXT,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION
    );

    -- Use \copy to load from CLIENT filesystem
    \copy temp_location FROM '$LOCATION_CSV' WITH (FORMAT csv, HEADER true, DELIMITER ',')

    -- Insert into working.location table
    INSERT INTO working.location (
        address_1, address_2, city, state, zip, county,
        location_source_value, country_concept_id, country_source_value,
        latitude, longitude, geom
    )
    SELECT
        address_1, address_2, city, state, zip, county,
        location_source_value, country_concept_id, country_source_value,
        latitude, longitude,
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) as geom
    FROM temp_location
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL
    ON CONFLICT DO NOTHING;

    DROP TABLE temp_location;
EOF

echo "LOCATION data loaded"
echo ""

# Load LOCATION_HISTORY data using client-side COPY
echo "Loading LOCATION_HISTORY data from client filesystem..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
    -- Create temp table for client-side data load
    CREATE TEMP TABLE IF NOT EXISTS temp_location_history (
        location_history_id INTEGER,
        location_id INTEGER,
        relationship_type_concept_id INTEGER,
        domain_id INTEGER,
        entity_id INTEGER,
        start_date DATE,
        end_date DATE
    );

    -- Use \copy to load from CLIENT filesystem
    \copy temp_location_history FROM '$LOCATION_HISTORY_CSV' WITH (FORMAT csv, HEADER true, DELIMITER ',')

    -- Insert into working.location_history table
    INSERT INTO working.location_history (
        location_id, relationship_type_concept_id, domain_id,
        entity_id, start_date, end_date
    )
    SELECT
        location_id, relationship_type_concept_id, domain_id,
        entity_id, start_date, end_date
    FROM temp_location_history
    ON CONFLICT DO NOTHING;

    DROP TABLE temp_location_history;

    -- Show location statistics
    SELECT
        'Locations loaded' as metric,
        COUNT(*) as count
    FROM working.location
    UNION ALL
    SELECT
        'Location histories loaded' as metric,
        COUNT(*) as count
    FROM working.location_history;
EOF

echo "LOCATION_HISTORY data loaded"
echo ""

# Load JSON-LD metadata if file exists
if [ -f "$JSONLD_FILE" ]; then
    echo "Loading JSON-LD metadata from client filesystem..."

    # Read JSON content and escape it for SQL
    JSON_CONTENT=$(cat "$JSONLD_FILE" | sed "s/'/''/g")

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
        -- Load JSON-LD metadata from client-provided content
        DO \$\$
        DECLARE
            v_json_content TEXT := '$JSON_CONTENT';
            v_result JSONB;
        BEGIN
            -- Call the JSON-LD ingestion function with client-provided content
            SELECT backbone.ingest_jsonld_metadata(v_json_content::JSONB) INTO v_result;

            RAISE NOTICE 'JSON-LD ingestion result: %', v_result;
        END \$\$;

        -- Show loaded data sources
        SELECT dataset_id, dataset_name, date_published
        FROM backbone.data_source
        ORDER BY date_published DESC
        LIMIT 10;

        -- Show loaded variables
        SELECT vs.variable_name, vs.unit_text, ds.dataset_name
        FROM backbone.variable_source vs
        JOIN backbone.data_source ds ON vs.data_source_uuid = ds.data_source_uuid
        ORDER BY ds.dataset_name, vs.variable_name
        LIMIT 20;
EOF

    echo "JSON-LD metadata loaded"
else
    echo "ℹ JSON-LD metadata file not found at $JSONLD_FILE, skipping..."
fi
echo ""

echo "=================================================="
echo "Data Loading Complete!"
echo ""
echo "Database Connection:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""
echo "PostgREST API: $API_URL"
echo ""
echo "Available API endpoints:"
echo ""
echo "Backbone schema (metadata - no header needed):"
echo "  curl $API_URL/data_source"
echo "  curl $API_URL/variable_source"
echo ""
echo "Working schema (requires 'Accept-Profile: working' header):"
echo "  curl -H 'Accept-Profile: working' $API_URL/location"
echo "  curl -H 'Accept-Profile: working' $API_URL/location_history"
echo "  curl -H 'Accept-Profile: working' $API_URL/external_exposure"
echo ""
echo "RPC function calls:"
echo "  curl -X POST $API_URL/rpc/quick_ingest_datasource \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"dataset_name\": \"My Dataset\"}'"
echo ""
echo "OpenAPI documentation:"
echo "  curl $API_URL/"
echo ""
echo "For detailed API usage, see: POSTGREST_API_GUIDE.md"
echo ""
echo "To connect directly via psql:"
echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo "=================================================="
