FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq

WORKDIR /app

# Copy all scripts
COPY gaiacore_client.sh .
COPY pipeline_example.sh .
COPY example.sh .

# Make all scripts executable
RUN chmod +x gaiacore_client.sh pipeline_example.sh example.sh

CMD ["/bin/sh", "/app/example.sh"]
