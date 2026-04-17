# gaiaCore R Client
# ====================
# R client library for interacting with the gaiaCore PostgREST API.
#
# Example usage:
#   source("gaiacore_client.R")
#   client <- GaiaCoreClient$new("http://gaiacore-api:3000")
#   locations <- client$get_locations(city = "FRESNO", limit = 10)

library(httr)
library(jsonlite)

#' gaiaCore API Client
#'
#' @description R6 class for interacting with gaiaCore PostgREST API
#' @export
GaiaCoreClient <- R6::R6Class(
  "GaiaCoreClient",

  public = list(
    #' @field base_url Base URL of the PostgREST API
    base_url = NULL,

    #' @description Initialize the gaiaCore client
    #' @param base_url Base URL of the PostgREST API
    initialize = function(base_url = "http://gaiacore-api:3000") {
      self$base_url <- sub("/$", "", base_url)
    },

    #' @description Make a GET request to the API
    #' @param endpoint API endpoint
    #' @param schema Schema profile (backbone or working)
    #' @param params Query parameters
    request = function(endpoint, schema = "backbone", params = list()) {
      url <- paste0(self$base_url, "/", endpoint)
      headers <- c()

      if (schema == "working") {
        headers <- add_headers(`Accept-Profile` = "working")
      }

      response <- GET(url, query = params, headers)

      if (http_error(response)) {
        stop(sprintf("API request failed: %s", content(response, "text")))
      }

      content(response, "parsed")
    },

    #' @description Call a PostgreSQL function via RPC
    #' @param function_name Name of the function
    #' @param params Function parameters
    #' @param schema Schema profile
    rpc = function(function_name, params = list(), schema = "backbone") {
      url <- paste0(self$base_url, "/rpc/", function_name)
      headers <- add_headers(`Content-Type` = "application/json")

      if (schema == "working") {
        headers <- add_headers(
          `Content-Profile` = "working",
          `Accept-Profile` = "working"
        )
      }

      response <- POST(url, body = params, encode = "json", headers)

      if (http_error(response)) {
        stop(sprintf("RPC call failed: %s", content(response, "text")))
      }

      content(response, "parsed")
    },

    # ========== Data Source Methods ==========

    #' @description Get all data sources
    #' @param ... Filter criteria
    get_data_sources = function(...) {
      filters <- list(...)
      params <- lapply(names(filters), function(k) {
        paste0("eq.", filters[[k]])
      })
      names(params) <- names(filters)

      self$request("data_source", params = params)
    },

    #' @description Get a specific data source by UUID
    #' @param uuid Data source UUID
    get_data_source = function(uuid) {
      result <- self$request(
        sprintf("data_source?data_source_uuid=eq.%s", uuid)
      )
      if (length(result) > 0) result[[1]] else NULL
    },

    #' @description List all downloadable data sources
    list_downloadable_datasources = function() {
      self$rpc("list_downloadable_datasources", list())
    },

    # ========== Variable Source Methods ==========

    #' @description Get variable definitions
    #' @param data_source_uuid Filter by data source UUID
    get_variables = function(data_source_uuid = NULL) {
      params <- list()
      if (!is.null(data_source_uuid)) {
        params$data_source_uuid <- paste0("eq.", data_source_uuid)
      }
      self$request("variable_source", params = params)
    },

    # ========== Location Methods ==========

    #' @description Get location data
    #' @param city Filter by city name
    #' @param state Filter by state
    #' @param limit Maximum number of results
    get_locations = function(city = NULL, state = NULL, limit = 100) {
      params <- list(limit = limit)
      if (!is.null(city)) params$city <- paste0("eq.", city)
      if (!is.null(state)) params$state <- paste0("eq.", state)

      self$request("location", schema = "working", params = params)
    },

    #' @description Get a specific location by ID
    #' @param location_id Location ID
    get_location = function(location_id) {
      result <- self$request(
        sprintf("location?location_id=eq.%d", location_id),
        schema = "working"
      )
      if (length(result) > 0) result[[1]] else NULL
    },

    #' @description Get location history records
    #' @param location_id Filter by location ID
    #' @param person_id Filter by person/entity ID
    get_location_history = function(location_id = NULL, person_id = NULL) {
      params <- list()
      if (!is.null(location_id)) {
        params$location_id <- paste0("eq.", location_id)
      }
      if (!is.null(person_id)) {
        params$entity_id <- paste0("eq.", person_id)
      }

      self$request("location_history", schema = "working", params = params)
    },

    # ========== External Exposure Methods ==========

    #' @description Get external exposure data
    #' @param person_id Filter by person ID
    #' @param location_id Filter by location ID
    #' @param limit Maximum number of results
    get_exposures = function(person_id = NULL, location_id = NULL, limit = 100) {
      params <- list(limit = limit)
      if (!is.null(person_id)) {
        params$person_id <- paste0("eq.", person_id)
      }
      if (!is.null(location_id)) {
        params$location_id <- paste0("eq.", location_id)
      }

      self$request("external_exposure", schema = "working", params = params)
    },

    # ========== Data Ingestion Methods ==========

    #' @description Fetch JSON-LD metadata from URL and load it
    #' @param url URL of the JSON-LD file
    fetch_and_load_jsonld = function(url) {
      self$rpc("fetch_and_load_jsonld", list(url = url))
    },

    #' @description Quickly ingest a data source by name
    #' @param dataset_name Name of the dataset
    #' @param download_url Optional override download URL
    quick_ingest_datasource = function(dataset_name, download_url = NULL) {
      params <- list(p_dataset_name = dataset_name)
      if (!is.null(download_url)) {
        params$p_download_url <- download_url
      }

      self$rpc("quick_ingest_datasource", params)
    },

    # ========== Advanced Query Methods ==========

    #' @description Advanced query with full PostgREST capabilities
    #' @param table Table name
    #' @param schema Schema (backbone or working)
    #' @param select Columns to select
    #' @param filters Filter list
    #' @param order Order by clause
    #' @param limit Maximum results
    #' @param offset Offset for pagination
    query = function(table, schema = "backbone", select = NULL,
                    filters = NULL, order = NULL, limit = NULL, offset = NULL) {
      params <- list()

      if (!is.null(select)) params$select <- select
      if (!is.null(filters)) {
        for (key in names(filters)) {
          params[[key]] <- paste0("eq.", filters[[key]])
        }
      }
      if (!is.null(order)) params$order <- order
      if (!is.null(limit)) params$limit <- limit
      if (!is.null(offset)) params$offset <- offset

      self$request(table, schema = schema, params = params)
    },

    #' @description Convert results to data frame
    #' @param results List of results from API
    to_dataframe = function(results) {
      if (length(results) == 0) {
        return(data.frame())
      }
      do.call(rbind, lapply(results, as.data.frame, stringsAsFactors = FALSE))
    }
  )
)

# Example usage
if (interactive()) {
  # Initialize client
  client <- GaiaCoreClient$new("http://gaiacore-api:3000")

  # Example 1: Get all data sources
  cat("=== Data Sources ===\n")
  sources <- client$get_data_sources()
  for (source in sources) {
    cat(sprintf("- %s\n", source$dataset_name))
  }

  # Example 2: Query locations
  cat("\n=== Locations in FRESNO ===\n")
  locations <- client$get_locations(city = "FRESNO", limit = 5)
  for (loc in locations) {
    cat(sprintf("- %s, %s, %s\n", loc$address_1, loc$city, loc$state))
  }

  # Example 3: Get exposures as data frame
  cat("\n=== External Exposures ===\n")
  exposures <- client$get_exposures(limit = 5)
  df <- client$to_dataframe(exposures)
  print(head(df))

  # Example 4: Advanced query
  cat("\n=== Advanced Query ===\n")
  results <- client$query(
    "location",
    schema = "working",
    select = "location_id,city,state,latitude,longitude",
    filters = list(state = "CA"),
    order = "city.asc",
    limit = 10
  )
  df <- client$to_dataframe(results)
  print(df)
}
