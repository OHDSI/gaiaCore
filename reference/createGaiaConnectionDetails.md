# Connection details for a Gaia database

Connects directly to gaiaDB (PostgreSQL with PostGIS) with
DatabaseConnector.

## Usage

``` r
createGaiaConnectionDetails(
  server = "gaia-db/gaiacore",
  port = 5432,
  user = "postgres",
  password = Sys.getenv("GAIA_POSTGRES_PASSWORD"),
  pathToDriver = Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
)
```

## Arguments

- server:

  Server and database as `host/database`. From the host use
  `localhost/gaiacore` and the published port.

- port:

  Port of the PostgreSQL server.

- user:

  Database user.

- password:

  Password. Defaults to the environment variable
  `GAIA_POSTGRES_PASSWORD`.

- pathToDriver:

  Folder with the PostgreSQL JDBC driver. Defaults to
  `DATABASECONNECTOR_JAR_FOLDER`.

## Value

A `connectionDetails` object for
[`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

## Examples

``` r
if (FALSE) { # \dontrun{
connection <- connectGaia(createGaiaConnectionDetails(password = "secret"))
disconnectGaia(connection)
} # }
```
