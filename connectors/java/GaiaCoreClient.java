/**
 * gaiaCore Java Client
 * ====================
 * Java client library for interacting with the gaiaCore PostgREST API.
 *
 * Example usage:
 *     GaiaCoreClient client = new GaiaCoreClient("http://gaiacore-api:3000");
 *     List<Map<String, Object>> sources = client.getDataSources();
 *     List<Map<String, Object>> locations = client.getLocations("FRESNO", null, 10);
 */

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.*;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

public class GaiaCoreClient {
    private final String baseUrl;
    private final HttpClient httpClient;
    private final Gson gson;

    /**
     * Initialize the gaiaCore client
     * @param baseUrl Base URL of the PostgREST API
     */
    public GaiaCoreClient(String baseUrl) {
        this.baseUrl = baseUrl.replaceAll("/$", "");
        this.httpClient = HttpClient.newHttpClient();
        this.gson = new Gson();
    }

    /**
     * Make a GET request to the API
     */
    private List<Map<String, Object>> request(String endpoint, String schema, Map<String, String> params)
            throws IOException, InterruptedException {
        StringBuilder url = new StringBuilder(baseUrl + "/" + endpoint);

        if (params != null && !params.isEmpty()) {
            url.append("?");
            params.forEach((key, value) ->
                url.append(key).append("=").append(value).append("&")
            );
            url.setLength(url.length() - 1); // Remove trailing &
        }

        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(url.toString()))
                .GET();

        if ("working".equals(schema)) {
            requestBuilder.header("Accept-Profile", "working");
        }

        HttpRequest request = requestBuilder.build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() >= 400) {
            throw new IOException("API request failed: " + response.body());
        }

        return gson.fromJson(response.body(), new TypeToken<List<Map<String, Object>>>(){}.getType());
    }

    /**
     * Call a PostgreSQL function via RPC
     */
    private Object rpc(String functionName, Map<String, Object> params, String schema)
            throws IOException, InterruptedException {
        String url = baseUrl + "/rpc/" + functionName;
        String jsonBody = gson.toJson(params);

        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody));

        if ("working".equals(schema)) {
            requestBuilder.header("Content-Profile", "working");
            requestBuilder.header("Accept-Profile", "working");
        }

        HttpRequest request = requestBuilder.build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() >= 400) {
            throw new IOException("RPC call failed: " + response.body());
        }

        return gson.fromJson(response.body(), Object.class);
    }

    // ========== Data Source Methods ==========

    /**
     * Get all data sources
     */
    public List<Map<String, Object>> getDataSources() throws IOException, InterruptedException {
        return request("data_source", "backbone", null);
    }

    /**
     * Get a specific data source by UUID
     */
    public Map<String, Object> getDataSource(String uuid) throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        params.put("data_source_uuid", "eq." + uuid);
        List<Map<String, Object>> result = request("data_source", "backbone", params);
        return result.isEmpty() ? null : result.get(0);
    }

    /**
     * List all downloadable data sources
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> listDownloadableDatasources() throws IOException, InterruptedException {
        return (List<Map<String, Object>>) rpc("list_downloadable_datasources", new HashMap<>(), "backbone");
    }

    // ========== Variable Source Methods ==========

    /**
     * Get variable definitions
     */
    public List<Map<String, Object>> getVariables(String dataSourceUuid)
            throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        if (dataSourceUuid != null) {
            params.put("data_source_uuid", "eq." + dataSourceUuid);
        }
        return request("variable_source", "backbone", params);
    }

    // ========== Location Methods ==========

    /**
     * Get location data
     */
    public List<Map<String, Object>> getLocations(String city, String state, Integer limit)
            throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        params.put("limit", String.valueOf(limit != null ? limit : 100));
        if (city != null) params.put("city", "eq." + city);
        if (state != null) params.put("state", "eq." + state);

        return request("location", "working", params);
    }

    /**
     * Get a specific location by ID
     */
    public Map<String, Object> getLocation(int locationId) throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        params.put("location_id", "eq." + locationId);
        List<Map<String, Object>> result = request("location", "working", params);
        return result.isEmpty() ? null : result.get(0);
    }

    /**
     * Get location history records
     */
    public List<Map<String, Object>> getLocationHistory(Integer locationId, Integer personId)
            throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        if (locationId != null) params.put("location_id", "eq." + locationId);
        if (personId != null) params.put("entity_id", "eq." + personId);

        return request("location_history", "working", params);
    }

    // ========== External Exposure Methods ==========

    /**
     * Get external exposure data
     */
    public List<Map<String, Object>> getExposures(Integer personId, Integer locationId, Integer limit)
            throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();
        params.put("limit", String.valueOf(limit != null ? limit : 100));
        if (personId != null) params.put("person_id", "eq." + personId);
        if (locationId != null) params.put("location_id", "eq." + locationId);

        return request("external_exposure", "working", params);
    }

    // ========== Data Ingestion Methods ==========

    /**
     * Fetch JSON-LD metadata from URL and load it
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> fetchAndLoadJsonld(String url) throws IOException, InterruptedException {
        Map<String, Object> params = new HashMap<>();
        params.put("url", url);
        return (List<Map<String, Object>>) rpc("fetch_and_load_jsonld", params, "backbone");
    }

    /**
     * Quickly ingest a data source by name
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> quickIngestDatasource(String datasetName, String downloadUrl)
            throws IOException, InterruptedException {
        Map<String, Object> params = new HashMap<>();
        params.put("p_dataset_name", datasetName);
        if (downloadUrl != null) {
            params.put("p_download_url", downloadUrl);
        }

        return (List<Map<String, Object>>) rpc("quick_ingest_datasource", params, "backbone");
    }

    /**
     * Load location and location history data from CSV files
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> loadLocationData(String locationFile, String locationHistoryFile)
            throws IOException, InterruptedException {
        Map<String, Object> params = new HashMap<>();
        params.put("p_location_file", locationFile);
        params.put("p_location_history_file", locationHistoryFile);

        return (Map<String, Object>) rpc("load_location_data", params, "working");
    }

    /**
     * Calculate exposures via spatial join
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> spatialJoinExposure(String variableSourceId, String externalTable)
            throws IOException, InterruptedException {
        Map<String, Object> params = new HashMap<>();
        params.put("p_variable_source_id", variableSourceId);
        params.put("p_external_table", externalTable);

        return (Map<String, Object>) rpc("spatial_join_exposure", params, "working");
    }

    // ========== Advanced Query Methods ==========

    /**
     * Advanced query with full PostgREST capabilities
     */
    public List<Map<String, Object>> query(String table, String schema, String select,
                                          Map<String, String> filters, String order,
                                          Integer limit, Integer offset)
            throws IOException, InterruptedException {
        Map<String, String> params = new HashMap<>();

        if (select != null) params.put("select", select);
        if (filters != null) {
            filters.forEach((key, value) -> params.put(key, "eq." + value));
        }
        if (order != null) params.put("order", order);
        if (limit != null) params.put("limit", String.valueOf(limit));
        if (offset != null) params.put("offset", String.valueOf(offset));

        return request(table, schema, params);
    }

    // ========== Example Usage ==========

    public static void main(String[] args) {
        try {
            // Initialize client
            GaiaCoreClient client = new GaiaCoreClient("http://localhost:3000");

            System.out.println("=== Data Sources ===");
            List<Map<String, Object>> sources = client.getDataSources();
            for (Map<String, Object> source : sources) {
                System.out.println("- " + source.get("dataset_name"));
            }

            System.out.println("\n=== Locations in FRESNO ===");
            List<Map<String, Object>> locations = client.getLocations("FRESNO", null, 5);
            for (Map<String, Object> loc : locations) {
                System.out.println("- " + loc.get("address_1") + ", " +
                                 loc.get("city") + ", " + loc.get("state"));
            }

            System.out.println("\n=== External Exposures ===");
            List<Map<String, Object>> exposures = client.getExposures(null, null, 5);
            for (Map<String, Object> exp : exposures) {
                System.out.println("- Person " + exp.get("person_id") + ": " +
                                 exp.get("value_as_number"));
            }

            System.out.println("\n=== Advanced Query ===");
            Map<String, String> filters = new HashMap<>();
            filters.put("state", "CA");
            List<Map<String, Object>> results = client.query(
                "location", "working",
                "location_id,city,state,latitude,longitude",
                filters, "city.asc", 10, null
            );
            for (Map<String, Object> result : results) {
                System.out.println("- " + result.get("city") + ": (" +
                                 result.get("latitude") + ", " + result.get("longitude") + ")");
            }

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
