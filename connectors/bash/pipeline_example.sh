#!/bin/bash
# gaiaCore End-to-End Pipeline Example (Bash)
# ============================================
# Demonstrates the complete workflow from metadata ingestion to exposure calculation.

source /app/gaiacore_client.sh

# Configuration
API_URL="${1:-http://:3000}"
METADATA_URL="${2:-https://raw.githubusercontent.com/OHDSI/gaiaCore/main/test/data_source/meta_json-ld_global_pm25_concentration_1998_2016.json}"

echo "============================================================"
echo "gaiaCore End-to-End Pipeline (Bash)"
echo "============================================================"
echo "API URL: $API_URL"
echo "Metadata URL: $METADATA_URL"
echo "============================================================"
echo

# Initialize client
gaiacore_init "$API_URL"

# Step 1: Load JSON-LD metadata from URL
echo "Step 1: Loading JSON-LD metadata from URL..."
METADATA_RESULT=$(gaiacore_fetch_and_load_jsonld "$METADATA_URL")

if [ $? -eq 0 ]; then
    DATASET_NAME=$(echo "$METADATA_RESULT" | jq -r '.[0].dataset_name' 2>/dev/null || echo "$METADATA_RESULT" | jq -r '.dataset_name')
    VARIABLES_LOADED=$(echo "$METADATA_RESULT" | jq -r '.[0].variables_loaded' 2>/dev/null || echo "$METADATA_RESULT" | jq -r '.variables_loaded')
    echo "  ✓ Loaded: $DATASET_NAME"
    echo "  ✓ Variables: $VARIABLES_LOADED"
else
    echo "  ✗ Failed to load metadata"
    exit 1
fi

# Step 2: Load location data
echo
echo "Step 2: Loading location data..."
LOCATION_RESULT=$(_gaiacore_rpc "load_location_data" '{"p_location_file":"/csv/LOCATION.csv","p_location_history_file":"/csv/LOCATION_HISTORY.csv"}' "working")

if [ $? -eq 0 ]; then
    echo "  ✓ Locations loaded"
else
    echo "  ✗ Failed to load locations"
fi

# Step 3: Ingest data source
echo
echo "Step 3: Ingesting data source..."
INGEST_RESULT=$(gaiacore_quick_ingest_datasource "$DATASET_NAME")

if [ $? -eq 0 ]; then
    echo "$INGEST_RESULT" | jq -r '.[] | "  \(if .status == "success" then "✓" elif .status == "warning" then "⚠" else "✗" end) \(.step): \(.status)"'
else
    echo "  ✗ Failed to ingest data source"
    exit 1
fi

# Step 4: Spatial join (optional)
VARIABLE_ID="avpmu_2015"

echo
echo "Step 4: Calculating exposures via spatial join..."

# Get ingested table name from metadata
DATA_SOURCE=$(gaiacore_get_data_sources | jq --arg name "$DATASET_NAME" '.[] | select(.dataset_name == $name)' | head -1)
SCHEMA=$(echo "$DATA_SOURCE" | jq -r '.etl_metadata.ingested_table.schema // "public"')
TABLE=$(echo "$DATA_SOURCE" | jq -r '.etl_metadata.ingested_table.table // empty')

if [ -n "$TABLE" ]; then
    EXTERNAL_TABLE="${SCHEMA}.${TABLE}"
    SPATIAL_JOIN_RESULT=$(_gaiacore_rpc "spatial_join_exposure" "{\"p_variable_source_id\":\"${VARIABLE_ID}\",\"p_external_table\":\"${EXTERNAL_TABLE}\"}" "working")

    if [ $? -eq 0 ]; then
        echo "  ✓ Spatial join complete"
    else
        echo "  ✗ Spatial join failed"
    fi
else
    echo "  ✗ Could not determine ingested table name"
fi

# Display results summary
echo
echo "============================================================"
echo "SAMPLE EXPOSURE RESULTS"
echo "============================================================"
echo

EXPOSURES=$(gaiacore_get_exposures "" "" 5)
echo "$EXPOSURES" | jq -r 'to_entries | .[] | "\(.key + 1). Person \(.value.person_id // "N/A") at Location \(.value.location_id // "N/A"): \(.value.value_as_number // "N/A")"' | head -5

echo
echo "============================================================"
echo "Pipeline execution complete!"
echo "============================================================"
