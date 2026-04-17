#!/bin/sh
# Example usage of gaiaCore Bash client

source /app/gaiacore_client.sh

# Get API URL from command line or use default
API_URL="${1:-http://gaiacore-api:3000}"

# Initialize client
gaiacore_init "$API_URL"

echo "=== gaiaCore Bash Client Example ==="
echo

# Get data sources
echo "Data Sources:"
gaiacore_get_data_sources | jq -r '.[] | "  - \(.dataset_name)"' | head -3

# Get locations
echo
echo "Locations:"
gaiacore_get_locations "" "" 3 | jq -r '.[] | "  - \(.city // "N/A"), \(.state // "N/A")"'

echo
echo "Client ready for use!"
