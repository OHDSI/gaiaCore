"""
gaiaCore Python Client
======================
Python client library for interacting with the gaiaCore PostgREST API.

Example usage:
    from gaiacore_client import GaiaCoreClient

    client = GaiaCoreClient("http://localhost:3000")

    # Query location data
    locations = client.get_locations(city="FRESNO", limit=10)

    # Query data sources
    sources = client.get_data_sources()
"""

import requests
from typing import Optional, Dict, List, Any
from urllib.parse import urljoin, urlencode


class GaiaCoreClient:
    """Client for interacting with gaiaCore PostgREST API."""

    def __init__(self, base_url: str = "http://localhost:3000"):
        """
        Initialize the gaiaCore client.

        Args:
            base_url: Base URL of the PostgREST API
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()

    def _request(self, endpoint: str, schema: str = "backbone",
                 params: Optional[Dict] = None) -> Any:
        """
        Make a request to the API.

        Args:
            endpoint: API endpoint
            schema: Schema profile (backbone or working)
            params: Query parameters

        Returns:
            JSON response data
        """
        url = urljoin(self.base_url, endpoint)
        headers = {}

        if schema == "working":
            headers["Accept-Profile"] = "working"

        response = self.session.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()

    def _rpc(self, function_name: str, params: Dict, schema: str = "backbone") -> Any:
        """
        Call a PostgreSQL function via RPC.

        Args:
            function_name: Name of the function
            params: Function parameters
            schema: Schema profile

        Returns:
            Function result
        """
        url = urljoin(self.base_url, f"rpc/{function_name}")
        headers = {"Content-Type": "application/json"}

        if schema == "working":
            headers["Content-Profile"] = "working"
            headers["Accept-Profile"] = "working"

        response = self.session.post(url, json=params, headers=headers)
        response.raise_for_status()
        return response.json()

    # ========== Data Source Methods ==========

    def get_data_sources(self, **filters) -> List[Dict]:
        """
        Get all data sources.

        Args:
            **filters: Filter criteria (e.g., dataset_name="PM2.5")

        Returns:
            List of data source records
        """
        params = {f"{k}": f"eq.{v}" for k, v in filters.items()}
        return self._request("data_source", params=params)

    def get_data_source(self, uuid: str) -> Dict:
        """Get a specific data source by UUID."""
        return self._request(f"data_source?data_source_uuid=eq.{uuid}")[0]

    def list_downloadable_datasources(self) -> List[Dict]:
        """List all downloadable data sources with their URLs."""
        return self._rpc("list_downloadable_datasources", {})

    # ========== Variable Source Methods ==========

    def get_variables(self, data_source_uuid: Optional[str] = None) -> List[Dict]:
        """
        Get variable definitions.

        Args:
            data_source_uuid: Filter by data source UUID

        Returns:
            List of variable records
        """
        params = {}
        if data_source_uuid:
            params["data_source_uuid"] = f"eq.{data_source_uuid}"
        return self._request("variable_source", params=params)

    # ========== Location Methods ==========

    def get_locations(self, city: Optional[str] = None,
                     state: Optional[str] = None,
                     limit: int = 100) -> List[Dict]:
        """
        Get location data.

        Args:
            city: Filter by city name
            state: Filter by state
            limit: Maximum number of results

        Returns:
            List of location records
        """
        params = {"limit": limit}
        if city:
            params["city"] = f"eq.{city}"
        if state:
            params["state"] = f"eq.{state}"

        return self._request("location", schema="working", params=params)

    def get_location(self, location_id: int) -> Dict:
        """Get a specific location by ID."""
        result = self._request(
            f"location?location_id=eq.{location_id}",
            schema="working"
        )
        return result[0] if result else None

    def get_location_history(self, location_id: Optional[int] = None,
                            person_id: Optional[int] = None) -> List[Dict]:
        """
        Get location history records.

        Args:
            location_id: Filter by location ID
            person_id: Filter by person/entity ID

        Returns:
            List of location history records
        """
        params = {}
        if location_id:
            params["location_id"] = f"eq.{location_id}"
        if person_id:
            params["entity_id"] = f"eq.{person_id}"

        return self._request("location_history", schema="working", params=params)

    # ========== External Exposure Methods ==========

    def get_exposures(self, person_id: Optional[int] = None,
                     location_id: Optional[int] = None,
                     limit: int = 100) -> List[Dict]:
        """
        Get external exposure data.

        Args:
            person_id: Filter by person ID
            location_id: Filter by location ID
            limit: Maximum number of results

        Returns:
            List of exposure records
        """
        params = {"limit": limit}
        if person_id:
            params["person_id"] = f"eq.{person_id}"
        if location_id:
            params["location_id"] = f"eq.{location_id}"

        return self._request("external_exposure", schema="working", params=params)

    # ========== Data Ingestion Methods ==========

    def fetch_and_load_jsonld(self, url: str) -> Dict:
        """
        Fetch JSON-LD metadata from URL and load it.

        Args:
            url: URL of the JSON-LD file

        Returns:
            Ingestion result with data_source_uuid, dataset_name, variables_loaded
        """
        return self._rpc("fetch_and_load_jsonld", {"url": url})

    def quick_ingest_datasource(self, dataset_name: str,
                                download_url: Optional[str] = None) -> List[Dict]:
        """
        Quickly ingest a data source by name.

        Args:
            dataset_name: Name of the dataset
            download_url: Optional override download URL

        Returns:
            Step-by-step ingestion progress
        """
        params = {"p_dataset_name": dataset_name}
        if download_url:
            params["p_download_url"] = download_url

        return self._rpc("quick_ingest_datasource", params)

    # ========== Advanced Query Methods ==========

    def query(self, table: str, schema: str = "backbone",
             select: Optional[str] = None,
             filters: Optional[Dict] = None,
             order: Optional[str] = None,
             limit: Optional[int] = None,
             offset: Optional[int] = None) -> List[Dict]:
        """
        Advanced query method with full PostgREST capabilities.

        Args:
            table: Table name
            schema: Schema (backbone or working)
            select: Columns to select (e.g., "id,name,city")
            filters: Filter dictionary (e.g., {"city": "FRESNO", "state": "CA"})
            order: Order by clause (e.g., "name.asc" or "value.desc")
            limit: Maximum results
            offset: Offset for pagination

        Returns:
            Query results
        """
        params = {}

        if select:
            params["select"] = select
        if filters:
            for key, value in filters.items():
                params[key] = f"eq.{value}"
        if order:
            params["order"] = order
        if limit:
            params["limit"] = limit
        if offset:
            params["offset"] = offset

        return self._request(table, schema=schema, params=params)

    # ========== End-to-End Pipeline Methods ==========

    def load_location_data(self, location_csv: str, location_history_csv: str) -> Dict:
        """
        Load LOCATION and LOCATION_HISTORY CSV files.

        Args:
            location_csv: Path to LOCATION CSV file
            location_history_csv: Path to LOCATION_HISTORY CSV file

        Returns:
            Load result
        """
        return self._rpc("load_location_data", {
            "p_location_file": location_csv,
            "p_location_history_file": location_history_csv
        }, schema="working")

    def spatial_join_exposure(self, variable_source_id: str,
                              external_table: str) -> Dict:
        """
        Perform spatial join to calculate exposures.

        Args:
            variable_source_id: Variable source ID (e.g., 'avpmu_2015')
            external_table: External data table name (schema.table)

        Returns:
            Spatial join result
        """
        return self._rpc("spatial_join_exposure", {
            "p_variable_source_id": variable_source_id,
            "p_external_table": external_table
        }, schema="working")

    def run_full_pipeline(self, metadata_url: str,
                         location_csv: str = "/csv/LOCATION.csv",
                         location_history_csv: str = "/csv/LOCATION_HISTORY.csv",
                         variable_source_id: Optional[str] = None,
                         verbose: bool = True) -> Dict:
        """
        Run the complete end-to-end pipeline:
        1. Fetch and load JSON-LD metadata from URL
        2. Load location data from CSVs
        3. Ingest the external data source
        4. Perform spatial join to calculate exposures

        Args:
            metadata_url: URL of JSON-LD metadata file
            location_csv: Path to LOCATION CSV
            location_history_csv: Path to LOCATION_HISTORY CSV
            variable_source_id: Variable to calculate exposure for (optional)
            verbose: Print progress messages

        Returns:
            Pipeline results dictionary
        """
        results = {
            "metadata": None,
            "locations": None,
            "ingestion": None,
            "spatial_join": None,
            "errors": []
        }

        try:
            # Step 1: Load metadata
            if verbose:
                print("Step 1: Loading JSON-LD metadata from URL...")
            results["metadata"] = self.fetch_and_load_jsonld(metadata_url)
            if verbose:
                print(f"  ✓ Loaded: {results['metadata'][0]['dataset_name']}")
                print(f"  ✓ Variables: {results['metadata'][0]['variables_loaded']}")

        except Exception as e:
            results["errors"].append(f"Metadata loading failed: {str(e)}")
            if verbose:
                print(f"  ✗ Error: {str(e)}")
            return results

        try:
            # Step 2: Load location data
            if verbose:
                print("\nStep 2: Loading location data...")
            results["locations"] = self.load_location_data(location_csv, location_history_csv)
            if verbose:
                print(f"  ✓ Locations loaded")

        except Exception as e:
            results["errors"].append(f"Location loading failed: {str(e)}")
            if verbose:
                print(f"  ✗ Error: {str(e)}")

        try:
            # Step 3: Ingest data source
            if verbose:
                print("\nStep 3: Ingesting data source...")
            dataset_name = results["metadata"][0]["dataset_name"]
            results["ingestion"] = self.quick_ingest_datasource(dataset_name)

            if verbose:
                for step in results["ingestion"]:
                    status_symbol = "✓" if step["status"] == "success" else "⚠" if step["status"] == "warning" else "✗"
                    print(f"  {status_symbol} {step['step']}: {step['status']}")

        except Exception as e:
            results["errors"].append(f"Data ingestion failed: {str(e)}")
            if verbose:
                print(f"  ✗ Error: {str(e)}")
            return results

        try:
            # Step 4: Spatial join (if variable specified)
            if variable_source_id:
                if verbose:
                    print("\nStep 4: Calculating exposures via spatial join...")

                # Get the ingested table name from metadata
                data_source = self.get_data_sources(dataset_name=dataset_name)[0]
                ingested_table = data_source.get("etl_metadata", {}).get("ingested_table", {})
                schema = ingested_table.get("schema", "public")
                table = ingested_table.get("table")

                if table:
                    external_table = f"{schema}.{table}"
                    results["spatial_join"] = self.spatial_join_exposure(
                        variable_source_id,
                        external_table
                    )
                    if verbose:
                        print(f"  ✓ Spatial join complete")
                else:
                    results["errors"].append("Could not determine ingested table name")
                    if verbose:
                        print(f"  ✗ Could not determine ingested table name")

        except Exception as e:
            results["errors"].append(f"Spatial join failed: {str(e)}")
            if verbose:
                print(f"  ✗ Error: {str(e)}")

        if verbose:
            print("\n" + "="*50)
            if not results["errors"]:
                print("Pipeline completed successfully!")
            else:
                print(f"Pipeline completed with {len(results['errors'])} error(s)")
            print("="*50)

        return results


# Example usage
if __name__ == "__main__":
    # Initialize client
    client = GaiaCoreClient("http://localhost:3000")

    # Example 1: Get all data sources
    print("=== Data Sources ===")
    sources = client.get_data_sources()
    for source in sources:
        print(f"- {source['dataset_name']}")

    # Example 2: Query locations
    print("\n=== Locations in FRESNO ===")
    locations = client.get_locations(city="FRESNO", limit=5)
    for loc in locations:
        print(f"- {loc['address_1']}, {loc['city']}, {loc['state']}")

    # Example 3: Get exposures
    print("\n=== External Exposures ===")
    exposures = client.get_exposures(limit=5)
    for exp in exposures:
        print(f"- Person {exp.get('person_id')}: {exp.get('value_as_number')}")

    # Example 4: Advanced query
    print("\n=== Advanced Query ===")
    results = client.query(
        "location",
        schema="working",
        select="location_id,city,state,latitude,longitude",
        filters={"state": "CA"},
        order="city.asc",
        limit=10
    )
    for result in results:
        print(f"- {result['city']}: ({result['latitude']}, {result['longitude']})")
