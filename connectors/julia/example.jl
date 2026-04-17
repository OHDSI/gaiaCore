#!/usr/bin/env julia
# Example usage of gaiaCore Julia client

include("GaiaCoreClient.jl")
using .GaiaCore

# Get API URL from command line or use default
api_url = length(ARGS) > 0 ? ARGS[1] : "http://gaiacore-api:3000"

# Initialize client
client = GaiaCoreClient(api_url)

println("=== gaiaCore Julia Client Example ===\n")

# Get data sources
println("Data Sources:")
try
    sources = get_data_sources(client)
    for i in 1:min(3, length(sources))
        println("  - ", sources[i]["dataset_name"])
    end
catch e
    println("  Error fetching data sources: ", e)
end

# Get locations
println("\nLocations:")
try
    locations = get_locations(client; limit=3)
    for i in 1:min(3, length(locations))
        loc = locations[i]
        city = get(loc, "city", "N/A")
        state = get(loc, "state", "N/A")
        println("  - $city, $state")
    end
catch e
    println("  Error fetching locations: ", e)
end

println("\nClient ready for use!")
