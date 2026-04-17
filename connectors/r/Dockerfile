FROM r-base:4.3.2

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('httr', 'jsonlite', 'R6'), repos='https://cloud.r-project.org/')"

# Copy client library
COPY gaiacore_client.R .

# Create example script
COPY <<'EOF' example.R
#!/usr/bin/env Rscript
# Example usage of gaiaCore R client

source("gaiacore_client.R")

# Get API URL from command line or use default
args <- commandArgs(trailingOnly = TRUE)
api_url <- if (length(args) > 0) args[1] else "http://host.docker.internal:3000"

# Initialize client
client <- GaiaCoreClient$new(api_url)

cat("=== gaiaCore R Client Example ===\n\n")

# Get data sources
cat("Data Sources:\n")
sources <- client$get_data_sources()
for (i in seq_len(min(3, length(sources)))) {
  cat(sprintf("  - %s\n", sources[[i]]$dataset_name))
}

# Get locations
cat("\nLocations:\n")
locations <- client$get_locations(limit = 3)
for (i in seq_len(min(3, length(locations)))) {
  loc <- locations[[i]]
  cat(sprintf("  - %s, %s\n",
              ifelse(is.null(loc$city), "N/A", loc$city),
              ifelse(is.null(loc$state), "N/A", loc$state)))
}

cat("\nClient ready for use!\n")
EOF

RUN chmod +x example.R

CMD ["Rscript", "example.R"]
