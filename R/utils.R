.sqlString <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return("NULL")
  }
  paste0("'", gsub("'", "''", as.character(x), fixed = TRUE), "'")
}

.sqlNumber <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return("NULL")
  }
  format(as.numeric(x), scientific = FALSE, trim = TRUE)
}

.identifier <- function(x, what = "identifier") {
  checkmate::assertString(x, .var.name = what)
  if (!grepl("^[A-Za-z_][A-Za-z0-9_]*$", x)) {
    stop(sprintf("'%s' is not a valid schema or table name", x), call. = FALSE)
  }
  x
}

.query <- function(connection, sql) {
  result <- DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = FALSE)
  names(result) <- tolower(names(result))
  result
}

.execute <- function(connection, sql) {
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  invisible(NULL)
}

.filterClause <- function(sourceValue = NULL, conceptId = NULL, alias = "") {
  prefix <- if (nzchar(alias)) paste0(alias, ".") else ""
  clauses <- character()
  if (!is.null(sourceValue)) {
    clauses <- c(clauses, sprintf("%sexposure_source_value = %s", prefix, .sqlString(sourceValue)))
  }
  if (!is.null(conceptId)) {
    checkmate::assertIntegerish(conceptId, any.missing = FALSE, min.len = 1)
    clauses <- c(clauses, sprintf("%sexposure_concept_id IN (%s)", prefix, paste(as.integer(conceptId), collapse = ", ")))
  }
  clauses
}
