"""
gaiaCore Julia Client
====================
Julia client library for interacting with the gaiaCore PostgREST API.

Example usage:
    using HTTP, JSON
    include("GaiaCoreClient.jl")

    client = GaiaCoreClient("http://localhost:3000")
    sources = get_data_sources(client)
    locations = get_locations(client; city="FRESNO", limit=10)
"""

module GaiaCore

using HTTP
using JSON

export GaiaCoreClient, get_data_sources, get_data_source, list_downloadable_datasources,
       get_variables, get_locations, get_location, get_location_history,
       get_exposures, fetch_and_load_jsonld, quick_ingest_datasource, query

"""
gaiaCore API Client
"""
struct GaiaCoreClient
    base_url::String

    function GaiaCoreClient(base_url::String="http://gaiacore-api:3000")
        new(rstrip(base_url, '/'))
    end
end

"""
Make a GET request to the API
"""
function request(client::GaiaCoreClient, endpoint::String;
                schema::String="backbone", params::Dict=Dict())
    url = "$(client.base_url)/$(endpoint)"
    headers = Dict{String,String}()

    if schema == "working"
        headers["Accept-Profile"] = "working"
    end

    response = HTTP.get(url; query=params, headers=headers)
    JSON.parse(String(response.body))
end

"""
Call a PostgreSQL function via RPC
"""
function rpc(client::GaiaCoreClient, function_name::String, params::Dict;
            schema::String="backbone")
    url = "$(client.base_url)/rpc/$(function_name)"
    headers = Dict("Content-Type" => "application/json")

    if schema == "working"
        headers["Content-Profile"] = "working"
        headers["Accept-Profile"] = "working"
    end

    response = HTTP.post(url, headers, JSON.json(params))
    JSON.parse(String(response.body))
end

# ========== Data Source Methods ==========

"""
Get all data sources
"""
function get_data_sources(client::GaiaCoreClient; kwargs...)
    params = Dict(string(k) => "eq.$(v)" for (k, v) in kwargs)
    request(client, "data_source"; params=params)
end

"""
Get a specific data source by UUID
"""
function get_data_source(client::GaiaCoreClient, uuid::String)
    result = request(client, "data_source"; params=Dict("data_source_uuid" => "eq.$(uuid)"))
    isempty(result) ? nothing : result[1]
end

"""
List all downloadable data sources
"""
function list_downloadable_datasources(client::GaiaCoreClient)
    rpc(client, "list_downloadable_datasources", Dict())
end

# ========== Variable Source Methods ==========

"""
Get variable definitions
"""
function get_variables(client::GaiaCoreClient; data_source_uuid::Union{String,Nothing}=nothing)
    params = Dict()
    if !isnothing(data_source_uuid)
        params["data_source_uuid"] = "eq.$(data_source_uuid)"
    end
    request(client, "variable_source"; params=params)
end

# ========== Location Methods ==========

"""
Get location data
"""
function get_locations(client::GaiaCoreClient;
                      city::Union{String,Nothing}=nothing,
                      state::Union{String,Nothing}=nothing,
                      limit::Int=100)
    params = Dict("limit" => limit)
    !isnothing(city) && (params["city"] = "eq.$(city)")
    !isnothing(state) && (params["state"] = "eq.$(state)")

    request(client, "location"; schema="working", params=params)
end

"""
Get a specific location by ID
"""
function get_location(client::GaiaCoreClient, location_id::Int)
    result = request(client, "location";
                    schema="working",
                    params=Dict("location_id" => "eq.$(location_id)"))
    isempty(result) ? nothing : result[1]
end

"""
Get location history records
"""
function get_location_history(client::GaiaCoreClient;
                              location_id::Union{Int,Nothing}=nothing,
                              person_id::Union{Int,Nothing}=nothing)
    params = Dict()
    !isnothing(location_id) && (params["location_id"] = "eq.$(location_id)")
    !isnothing(person_id) && (params["entity_id"] = "eq.$(person_id)")

    request(client, "location_history"; schema="working", params=params)
end

# ========== External Exposure Methods ==========

"""
Get external exposure data
"""
function get_exposures(client::GaiaCoreClient;
                      person_id::Union{Int,Nothing}=nothing,
                      location_id::Union{Int,Nothing}=nothing,
                      limit::Int=100)
    params = Dict("limit" => limit)
    !isnothing(person_id) && (params["person_id"] = "eq.$(person_id)")
    !isnothing(location_id) && (params["location_id"] = "eq.$(location_id)")

    request(client, "external_exposure"; schema="working", params=params)
end

# ========== Data Ingestion Methods ==========

"""
Fetch JSON-LD metadata from URL and load it
"""
function fetch_and_load_jsonld(client::GaiaCoreClient, url::String)
    rpc(client, "fetch_and_load_jsonld", Dict("url" => url))
end

"""
Quickly ingest a data source by name
"""
function quick_ingest_datasource(client::GaiaCoreClient, dataset_name::String;
                                 download_url::Union{String,Nothing}=nothing)
    params = Dict("p_dataset_name" => dataset_name)
    !isnothing(download_url) && (params["p_download_url"] = download_url)

    rpc(client, "quick_ingest_datasource", params)
end

# ========== Advanced Query Methods ==========

"""
Advanced query with full PostgREST capabilities
"""
function query(client::GaiaCoreClient, table::String;
              schema::String="backbone",
              select::Union{String,Nothing}=nothing,
              filters::Union{Dict,Nothing}=nothing,
              order::Union{String,Nothing}=nothing,
              limit::Union{Int,Nothing}=nothing,
              offset::Union{Int,Nothing}=nothing)
    params = Dict()

    !isnothing(select) && (params["select"] = select)
    if !isnothing(filters)
        for (key, value) in filters
            params[string(key)] = "eq.$(value)"
        end
    end
    !isnothing(order) && (params["order"] = order)
    !isnothing(limit) && (params["limit"] = limit)
    !isnothing(offset) && (params["offset"] = offset)

    request(client, table; schema=schema, params=params)
end

end # module

# Example usage
if abspath(PROGRAM_FILE) == @__FILE__
    using .GaiaCore

    # Initialize client
    client = GaiaCoreClient("http://localhost:3000")

    println("=== Data Sources ===")
    sources = get_data_sources(client)
    for source in sources
        println("- ", source["dataset_name"])
    end

    println("\n=== Locations in FRESNO ===")
    locations = get_locations(client; city="FRESNO", limit=5)
    for loc in locations
        println("- ", get(loc, "address_1", ""), ", ", get(loc, "city", ""), ", ", get(loc, "state", ""))
    end

    println("\n=== External Exposures ===")
    exposures = get_exposures(client; limit=5)
    for exp in exposures
        println("- Person ", get(exp, "person_id", "N/A"), ": ", get(exp, "value_as_number", "N/A"))
    end

    println("\n=== Advanced Query ===")
    results = query(client, "location";
                   schema="working",
                   select="location_id,city,state,latitude,longitude",
                   filters=Dict("state" => "CA"),
                   order="city.asc",
                   limit=10)
    for result in results
        println("- ", result["city"], ": (", result["latitude"], ", ", result["longitude"], ")")
    end
end
