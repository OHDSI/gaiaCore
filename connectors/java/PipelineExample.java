import java.util.*;

public class PipelineExample {
    public static void main(String[] args) {
        try {
            // Get API URL and metadata URL from command line or use defaults
            String apiUrl = args.length > 0 ? args[0] : "http://gaiacore-api:3000";
            String metadataUrl = args.length > 1 ? args[1] :
                "https://raw.githubusercontent.com/linkml/linkml/main/tests/test_notebooks/data_dictionary/data_model_examples/data_dictionaries/global_pm25_concentration_1998_2016.json";

            GaiaCoreClient client = new GaiaCoreClient(apiUrl);

            System.out.println("=== gaiaCore End-to-End Pipeline ===\n");

            // Step 1: Load JSON-LD metadata
            System.out.println("Step 1: Loading JSON-LD metadata from URL...");
            try {
                List<Map<String, Object>> result = client.fetchAndLoadJsonld(metadataUrl);
                System.out.println("  ✓ Loaded dataset: " + result.get(0).get("dataset_name"));
                System.out.println("  ✓ Dataset UUID: " + result.get(0).get("data_source_uuid"));
            } catch (Exception e) {
                System.out.println("  ✗ Error: " + e.getMessage());
                System.exit(1);
            }

            // Step 2: Load location data
            System.out.println("\nStep 2: Loading location data...");
            try {
                client.loadLocationData("/csv/LOCATION.csv", "/csv/LOCATION_HISTORY.csv");
                System.out.println("  ✓ Location data loaded successfully");
            } catch (Exception e) {
                System.out.println("  ✗ Error: " + e.getMessage());
                System.exit(1);
            }

            // Step 3: Quick ingest data source
            System.out.println("\nStep 3: Ingesting data source...");
            String datasetName = "Annual PM2.5 Concentrations for Countries and Urban Areas, v1 (1998 – 2016)";
            try {
                List<Map<String, Object>> steps = client.quickIngestDatasource(datasetName, null);
                for (Map<String, Object> step : steps) {
                    String statusIcon = "success".equals(step.get("status")) ? "✓" : "✗";
                    System.out.println("  " + statusIcon + " " + step.get("step") + ": " + step.get("status"));
                    if (step.containsKey("message") && step.get("message") != null) {
                        System.out.println("    " + step.get("message"));
                    }
                }
            } catch (Exception e) {
                System.out.println("  ✗ Error: " + e.getMessage());
                System.exit(1);
            }

            // Step 4: Calculate exposures via spatial join
            System.out.println("\nStep 4: Calculating exposures...");
            try {
                Map<String, Object> result = client.spatialJoinExposure("avpmu_2015", "public.annual_pm2_5_concentrations");
                System.out.println("  ✓ Spatial join completed");
                System.out.println("  ✓ Result: " + result);
            } catch (Exception e) {
                System.out.println("  ✗ Error: " + e.getMessage());
                System.exit(1);
            }

            System.out.println("\n=== Pipeline Complete ===");

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
