#!/bin/bash
# gaiaCore Bash Client
# ====================
# Shell script library for interacting with the gaiaCore PostgREST API using curl.
#
# Usage:
#   source gaiacore_client.sh
#   gaiacore_init "http://gaiacore-api:3000"
#   gaiacore_get_data_sources
#   gaiacore_get_locations "FRESNO" "CA" 10

# Configuration
GAIACORE_BASE_URL="http://gaiacore-api:3000"
GAIACORE_VERBOSE=0

# Initialize client
gaiacore_init() {
    GAIACORE_BASE_URL="${1:-http://gaiacore-api:3000}"
    GAIACORE_BASE_URL="${GAIACORE_BASE_URL%/}"
}

# Set verbose mode
gaiacore_verbose() {
    GAIACORE_VERBOSE="${1:-1}"
}

# Internal request function
_gaiacore_request() {
    local endpoint="$1"
    local schema="${2:-backbone}"
    local params="$3"
    local url="${GAIACORE_BASE_URL}/${endpoint}"

    if [ -n "$params" ]; then
        url="${url}?${params}"
    fi

    local headers=""
    if [ "$schema" = "working" ]; then
        headers="-H 'Accept-Profile: working'"
    fi

    if [ "$GAIACORE_VERBOSE" = "1" ]; then
        echo "GET $url" >&2
    fi

    eval curl -s $headers "'$url'"
}

# Internal RPC function
_gaiacore_rpc() {
    local function_name="$1"
    local params="$2"
    local schema="${3:-backbone}"
    local url="${GAIACORE_BASE_URL}/rpc/${function_name}"

    local headers="-H 'Content-Type: application/json'"
    if [ "$schema" = "working" ]; then
        headers="$headers -H 'Content-Profile: working' -H 'Accept-Profile: working'"
    fi

    if [ "$GAIACORE_VERBOSE" = "1" ]; then
        echo "POST $url" >&2
        echo "Body: $params" >&2
    fi

    eval curl -s -X POST $headers -d "'$params'" "'$url'"
}

# ========== Data Source Methods ==========

# Get all data sources
gaiacore_get_data_sources() {
    _gaiacore_request "data_source" "backbone"
}

# Get specific data source by UUID
gaiacore_get_data_source() {
    local uuid="$1"
    _gaiacore_request "data_source?data_source_uuid=eq.${uuid}" "backbone"
}

# List downloadable data sources
gaiacore_list_downloadable_datasources() {
    _gaiacore_rpc "list_downloadable_datasources" "{}"
}

# ========== Variable Source Methods ==========

# Get variables
gaiacore_get_variables() {
    local data_source_uuid="$1"
    local params=""

    if [ -n "$data_source_uuid" ]; then
        params="data_source_uuid=eq.${data_source_uuid}"
    fi

    _gaiacore_request "variable_source" "backbone" "$params"
}

# ========== Location Methods ==========

# Get locations
# Usage: gaiacore_get_locations [city] [state] [limit]
gaiacore_get_locations() {
    local city="$1"
    local state="$2"
    local limit="${3:-100}"
    local params="limit=${limit}"

    if [ -n "$city" ]; then
        params="${params}&city=eq.${city}"
    fi
    if [ -n "$state" ]; then
        params="${params}&state=eq.${state}"
    fi

    _gaiacore_request "location" "working" "$params"
}

# Get specific location by ID
gaiacore_get_location() {
    local location_id="$1"
    _gaiacore_request "location?location_id=eq.${location_id}" "working"
}

# Get location history
gaiacore_get_location_history() {
    local location_id="$1"
    local person_id="$2"
    local params=""

    if [ -n "$location_id" ]; then
        params="location_id=eq.${location_id}"
    fi
    if [ -n "$person_id" ]; then
        [ -n "$params" ] && params="${params}&"
        params="${params}entity_id=eq.${person_id}"
    fi

    _gaiacore_request "location_history" "working" "$params"
}

# ========== External Exposure Methods ==========

# Get exposures
# Usage: gaiacore_get_exposures [person_id] [location_id] [limit]
gaiacore_get_exposures() {
    local person_id="$1"
    local location_id="$2"
    local limit="${3:-100}"
    local params="limit=${limit}"

    if [ -n "$person_id" ]; then
        params="${params}&person_id=eq.${person_id}"
    fi
    if [ -n "$location_id" ]; then
        params="${params}&location_id=eq.${location_id}"
    fi

    _gaiacore_request "external_exposure" "working" "$params"
}

# ========== Data Ingestion Methods ==========

# Fetch and load JSON-LD from URL
gaiacore_fetch_and_load_jsonld() {
    local url="$1"
    local params=$(cat <<EOF
{"url": "${url}"}
EOF
)
    _gaiacore_rpc "fetch_and_load_jsonld" "$params"
}

# Quick ingest data source
gaiacore_quick_ingest_datasource() {
    local dataset_name="$1"
    local download_url="$2"

    local params
    if [ -n "$download_url" ]; then
        params=$(cat <<EOF
{"p_dataset_name": "${dataset_name}", "p_download_url": "${download_url}"}
EOF
)
    else
        params=$(cat <<EOF
{"p_dataset_name": "${dataset_name}"}
EOF
)
    fi

    _gaiacore_rpc "quick_ingest_datasource" "$params"
}

# ========== Utility Functions ==========

# Pretty print JSON output
gaiacore_pretty() {
    if command -v jq &> /dev/null; then
        jq '.'
    else
        python3 -m json.tool 2>/dev/null || cat
    fi
}

# Count results
gaiacore_count() {
    if command -v jq &> /dev/null; then
        jq 'length'
    else
        echo "Install jq for counting results" >&2
        return 1
    fi
}

# Advanced query
# Usage: gaiacore_query table schema select filters order limit offset
gaiacore_query() {
    local table="$1"
    local schema="${2:-backbone}"
    local select="$3"
    local filters="$4"
    local order="$5"
    local limit="$6"
    local offset="$7"

    local params=""

    [ -n "$select" ] && params="${params}select=${select}&"
    [ -n "$filters" ] && params="${params}${filters}&"
    [ -n "$order" ] && params="${params}order=${order}&"
    [ -n "$limit" ] && params="${params}limit=${limit}&"
    [ -n "$offset" ] && params="${params}offset=${offset}&"

    # Remove trailing &
    params="${params%&}"

    _gaiacore_request "$table" "$schema" "$params"
}

# Note: Functions are available when this file is sourced
# export -f is bash-specific and not needed for POSIX sh
