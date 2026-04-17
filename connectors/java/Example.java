import java.util.*;

public class Example {
    public static void main(String[] args) {
        try {
            // Get API URL from command line or use default
            String apiUrl = args.length > 0 ? args[0] : "http://gaiacore-api:3000";

            // Initialize client
            GaiaCoreClient client = new GaiaCoreClient(apiUrl);

            System.out.println("=== gaiaCore Java Client Example ===\n");

            // Get data sources
            System.out.println("Data Sources:");
            try {
                List<Map<String, Object>> sources = client.getDataSources();
                for (int i = 0; i < Math.min(3, sources.size()); i++) {
                    System.out.println("  - " + sources.get(i).get("dataset_name"));
                }
            } catch (Exception e) {
                System.out.println("  Error fetching data sources: " + e.getMessage());
            }

            // Get locations
            System.out.println("\nLocations:");
            try {
                List<Map<String, Object>> locations = client.getLocations(null, null, 3);
                for (int i = 0; i < Math.min(3, locations.size()); i++) {
                    Map<String, Object> loc = locations.get(i);
                    String city = (String) loc.getOrDefault("city", "N/A");
                    String state = (String) loc.getOrDefault("state", "N/A");
                    System.out.println("  - " + city + ", " + state);
                }
            } catch (Exception e) {
                System.out.println("  Error fetching locations: " + e.getMessage());
            }

            System.out.println("\nClient ready for use!");

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
