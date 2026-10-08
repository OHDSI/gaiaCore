#' Connection details for a Gaia database
#'
#' Connects directly to gaiaDB (PostgreSQL with PostGIS) with DatabaseConnector.
#'
#' @param server Server and database as `host/database`. From the host use `localhost/gaiacore` and the published port.
#' @param port Port of the PostgreSQL server.
#' @param user Database user.
#' @param password Password. Defaults to the environment variable `GAIA_POSTGRES_PASSWORD`.
#' @param pathToDriver Folder with the PostgreSQL JDBC driver. Defaults to `DATABASECONNECTOR_JAR_FOLDER`.
#'
#' @return A `connectionDetails` object for [connectGaia()].
#' @examples
#' \dontrun{
#' connection <- connectGaia(createGaiaConnectionDetails(password = "secret"))
#' disconnectGaia(connection)
#' }
#' @export
createGaiaConnectionDetails <- function(server = "gaia-db/gaiacore",
                                        port = 5432,
                                        user = "postgres",
                                        password = Sys.getenv("GAIA_POSTGRES_PASSWORD"),
                                        pathToDriver = Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")) {
  checkmate::assertString(server)
  checkmate::assertInt(port)
  checkmate::assertString(user)
  checkmate::assertString(password)
  checkmate::assertString(pathToDriver)
  arguments <- list(dbms = "postgresql", server = server, port = port, user = user, password = password)
  if (nzchar(pathToDriver)) {
    arguments$pathToDriver <- pathToDriver
  }
  do.call(DatabaseConnector::createConnectionDetails, arguments)
}

#' Connect to a Gaia database
#'
#' @param connectionDetails Output of [createGaiaConnectionDetails()].
#' @return A DatabaseConnector connection.
#' @export
connectGaia <- function(connectionDetails) {
  DatabaseConnector::connect(connectionDetails)
}

#' Disconnect from a Gaia database
#'
#' @param connection A connection from [connectGaia()].
#' @export
disconnectGaia <- function(connection) {
  DatabaseConnector::disconnect(connection)
}
