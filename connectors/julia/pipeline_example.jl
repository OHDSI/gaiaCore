#!/usr/bin/env julia
# End-to-end pipeline example for gaiaCore Julia client

include("GaiaCoreClient.jl")
using .GaiaCore

# Get API URL and metadata URL from command line or use defaults
api_url = length(ARGS) > 0 ? ARGS[1] : "http://gaiacore-api:3000"
metadata_url = length(ARGS) > 1 ? ARGS[2] : "https://raw.githubusercontent.com/linkml/linkml/main/tests/test_notebooks/data_dictionary/data_model_examples/data_dictionaries/global_pm25_concentration_1998_2016.json"

client = GaiaCoreClient(api_url)

println("=== gaiaCore End-to-End Pipeline ===\n")

# Step 1: Load JSON-LD metadata
println("Step 1: Loading JSON-LD metadata from URL...")
try
    result = fetch_and_load_jsonld(client, metadata_url)
    println("  ✓ Loaded dataset: ", result[1]["dataset_name"])
    dataset_uuid = result[1]["data_source_uuid"]
    println("  ✓ Dataset UUID: ", dataset_uuid)
catch e
    println("  ✗ Error: ", e)
    exit(1)
end

# Step 2: Load location data
println("\nStep 2: Loading location data...")
try
    result = load_location_data(client, "/csv/LOCATION.csv", "/csv/LOCATION_HISTORY.csv")
    println("  ✓ Location data loaded successfully")
catch e
    println("  ✗ Error: ", e)
    exit(1)
end

# Step 3: Quick ingest data source
println("\nStep 3: Ingesting data source...")
dataset_name = "Annual PM2.5 Concentrations for Countries and Urban Areas, v1 (1998 – 2016)"
try
    steps = quick_ingest_datasource(client, dataset_name)
    for step in steps
        status_icon = step["status"] == "success" ? "✓" : "✗"
        println("  $status_icon ", step["step"], ": ", step["status"])
        if haskey(step, "message") && step["message"] != nothing
            println("    ", step["message"])
        end
    end
catch e
    println("  ✗ Error: ", e)
    exit(1)
end

# Step 4: Calculate exposures via spatial join
println("\nStep 4: Calculating exposures...")
try
    result = spatial_join_exposure(client, "avpmu_2015", "public.annual_pm2_5_concentrations")
    println("  ✓ Spatial join completed")
    println("  ✓ Result: ", result)
catch e
    println("  ✗ Error: ", e)
    exit(1)
end

println("\n=== Pipeline Complete ===")
