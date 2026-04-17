FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy client library
COPY gaiacore_client.py .

# Create example script
COPY <<'EOF' example.py
#!/usr/bin/env python3
"""Example usage of gaiaCore Python client."""

from gaiacore_client import GaiaCoreClient
import sys

def main():
    # Initialize client (use host.docker.internal for Docker networking)
    api_url = sys.argv[1] if len(sys.argv) > 1 else "http://gaiacore-api:3000"
    client = GaiaCoreClient(api_url)

    print("=== gaiaCore Python Client Example ===\n")

    # Get data sources
    print("Data Sources:")
    sources = client.get_data_sources()
    for source in sources[:3]:
        print(f"  - {source['dataset_name']}")

    # Get locations
    print("\nLocations:")
    locations = client.get_locations(limit=3)
    for loc in locations:
        print(f"  - {loc.get('city', 'N/A')}, {loc.get('state', 'N/A')}")

    print("\nClient ready for use!")

if __name__ == "__main__":
    main()
EOF

RUN chmod +x example.py

CMD ["python", "example.py"]
