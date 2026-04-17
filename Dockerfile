FROM postgis/postgis:16-3.4-alpine

# Install required packages
RUN apk add --no-cache \
    libintl \
    gdal \
    gdal-tools \
    gdal-driver-pg \
    postgresql-contrib \
    curl \
    ca-certificates \
    git \
    build-base \
    postgresql-dev \
    bc \
    make \
    g++ \
    clang15 \
    llvm15

# Install plsh (PostgreSQL shell procedural language)
RUN cd /tmp && \
    git clone https://github.com/petere/plsh.git && \
    cd plsh && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/plsh

# Create directories
RUN mkdir -p /csv /app /sql /data

# Install PostgREST
ENV POSTGREST_VERSION=12.0.2
RUN curl -L -o /tmp/postgrest.tar.xz \
    "https://github.com/PostgREST/postgrest/releases/download/v${POSTGREST_VERSION}/postgrest-v${POSTGREST_VERSION}-linux-static-x64.tar.xz" && \
    tar -xJf /tmp/postgrest.tar.xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/postgrest && \
    rm /tmp/postgrest.tar.xz

# Copy SQL initialization scripts
COPY sql/*.sql /docker-entrypoint-initdb.d/

# Copy PostgREST configuration
COPY postgrest.conf /etc/postgrest/postgrest.conf

# Copy helper scripts
COPY scripts/init_gaiacore.sh /docker-entrypoint-initdb.d/99_init_gaiacore.sh

# Expose PostgreSQL and PostgREST ports
EXPOSE 5432 3000

# Default environment variables
ENV POSTGRES_DB=gaiacore
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV PGRST_DB_URI=postgresql://postgres:postgres@localhost:5432/gaiacore
ENV PGRST_DB_SCHEMA=backbone,working
ENV PGRST_DB_ANON_ROLE=postgres
ENV PGRST_SERVER_PORT=3000


