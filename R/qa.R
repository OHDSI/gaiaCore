#' Quality checks on the derived exposure rows
#'
#' Counts the rows of `working.external_exposure` that break basic expectations of a clean exposure table.
#'
#' @param connection A connection from [connectGaia()].
#' @param sourceValue Check only rows with this `exposure_source_value`, or all if `NULL`.
#' @param conceptId Check only rows of these exposure concepts, or all if `NULL`.
#' @param valueRange Plausible range of `value_as_number`.
#' @param expectedUnit Expected `dose_unit_source_value` (for example `"ug/m3"`), or `NULL` to skip that check.
#'
#' @return A data frame with `check`, `rows_flagged` and `description`; the attribute `ok` is `TRUE` when nothing is flagged.
#'   Checks: `duplicate_rows`, `outside_residence`, `missing_value`, `implausible_value`, `unit_mismatch` (only with `expectedUnit`) and `unassigned_person`.
#' @examples
#' \dontrun{
#' checkExposure(connection, valueRange = c(0, 200), expectedUnit = "ug/m3")
#' }
#' @export
checkExposure <- function(connection, sourceValue = NULL, conceptId = NULL, valueRange = c(0, Inf), expectedUnit = NULL) {
  checkmate::assertNumeric(valueRange, len = 2, any.missing = FALSE)
  checkmate::assertString(expectedUnit, null.ok = TRUE)
  filter <- .filterClause(sourceValue, conceptId, alias = "e")
  where <- if (length(filter)) paste("AND", paste(filter, collapse = " AND ")) else ""
  count <- function(sql) as.numeric(.query(connection, paste("SELECT count(*) AS n FROM (", sql, ") x"))$n)
  base <- sprintf("FROM working.external_exposure e WHERE true %s", where)
  rules <- list(
    list("duplicate_rows", "groups of identical person, location, concept, source and interval",
         sprintf("SELECT e.person_id FROM working.external_exposure e WHERE true %s GROUP BY e.person_id, e.location_id, e.exposure_concept_id, e.exposure_source_value, e.exposure_start_date, e.exposure_end_date HAVING count(*) > 1", where)),
    list("outside_residence", "interval not inside a residence interval of the person at that location",
         sprintf("SELECT 1 %s AND e.person_id > 0 AND NOT EXISTS (SELECT 1 FROM working.location_history lh WHERE lh.entity_id = e.person_id AND lh.location_id = e.location_id AND e.exposure_start_date >= lh.start_date AND e.exposure_end_date <= lh.end_date)", base)),
    list("missing_value", "value_as_number is NULL", sprintf("SELECT 1 %s AND e.value_as_number IS NULL", base)),
    list("implausible_value", sprintf("value_as_number outside [%s, %s]", valueRange[1], valueRange[2]),
         sprintf("SELECT 1 %s AND (e.value_as_number < %s OR e.value_as_number > %s)", base,
                 .sqlNumber(valueRange[1]), if (is.finite(valueRange[2])) .sqlNumber(valueRange[2]) else "1e300")),
    list("unassigned_person", "person_id is 0 (location not linked to a person)", sprintf("SELECT 1 %s AND e.person_id = 0", base))
  )
  if (!is.null(expectedUnit)) {
    rules <- append(rules, list(list("unit_mismatch", sprintf("dose_unit_source_value differs from '%s'", expectedUnit),
      sprintf("SELECT 1 %s AND e.dose_unit_source_value IS NOT NULL AND e.dose_unit_source_value <> %s", base, .sqlString(expectedUnit)))), after = 3)
  }
  result <- data.frame(
    check = vapply(rules, `[[`, "", 1),
    rows_flagged = vapply(rules, function(r) count(r[[3]]), numeric(1)),
    description = vapply(rules, `[[`, "", 2),
    stringsAsFactors = FALSE
  )
  attr(result, "ok") <- all(result$rows_flagged == 0)
  result
}

#' Quality checks on staged exposure rows
#'
#' Checks candidate exposure rows before they are loaded, against the exposure already derived and the loaded residence history.
#'
#' @param connection A connection from [connectGaia()].
#' @param staged A data frame with `person_id`, `exposure_start_date`, `exposure_end_date` and `value_as_number`, and optionally
#'   `location_id`, `exposure_concept_id` and `dose_unit_source_value`. Columns that are missing are not checked.
#' @param valueRange Plausible range of `value_as_number`.
#' @param expectedUnit Expected `dose_unit_source_value`, or `NULL` to skip that check.
#'
#' @return `staged` with logical columns `duplicate_row` (the same person, location, concept and interval is already in
#'   `working.external_exposure`), `outside_residence` (the interval does not overlap any residence interval of the person),
#'   `missing_value`, `implausible_value`, `unit_mismatch` and `reject` (any check failed).
#' @examples
#' \dontrun{
#' checkStagedExposure(connection, staged, valueRange = c(0, 200), expectedUnit = "micrograms/cubic meter")
#' }
#' @export
checkStagedExposure <- function(connection, staged, valueRange = c(0, Inf), expectedUnit = NULL) {
  checkmate::assertDataFrame(staged, min.rows = 1)
  checkmate::assertNames(names(staged), must.include = c("person_id", "exposure_start_date", "exposure_end_date", "value_as_number"),
                         .var.name = "staged")
  checkmate::assertNumeric(valueRange, len = 2, any.missing = FALSE)
  checkmate::assertString(expectedUnit, null.ok = TRUE)
  persons <- paste(unique(as.integer(staged$person_id)), collapse = ", ")
  existing <- .query(connection, sprintf(paste(
    "SELECT person_id, location_id, exposure_concept_id, exposure_start_date, exposure_end_date",
    "FROM working.external_exposure WHERE person_id IN (%s)"), persons))
  history <- .query(connection, sprintf(
    "SELECT entity_id, start_date, end_date FROM working.location_history WHERE entity_id IN (%s)", persons))
  .flagStaged(staged, existing, history, valueRange, expectedUnit)
}

.flagStaged <- function(staged, existing, history, valueRange, expectedUnit) {
  key <- function(d) {
    column <- function(name) if (name %in% names(d)) as.character(d[[name]]) else ""
    paste(d$person_id, column("location_id"), column("exposure_concept_id"),
          as.Date(d$exposure_start_date), as.Date(d$exposure_end_date))
  }
  staged$duplicate_row <- key(staged) %in% key(existing)
  start <- as.Date(staged$exposure_start_date)
  end <- as.Date(staged$exposure_end_date)
  staged$outside_residence <- vapply(seq_len(nrow(staged)), function(i) {
    own <- history$entity_id == staged$person_id[i]
    !any(own & start[i] <= as.Date(history$end_date) & end[i] >= as.Date(history$start_date))
  }, logical(1))
  staged$missing_value <- is.na(staged$value_as_number)
  staged$implausible_value <- !is.na(staged$value_as_number) &
    (staged$value_as_number < valueRange[1] | staged$value_as_number > valueRange[2])
  staged$unit_mismatch <- if (!is.null(expectedUnit) && "dose_unit_source_value" %in% names(staged)) {
    !is.na(staged$dose_unit_source_value) & staged$dose_unit_source_value != expectedUnit
  } else {
    FALSE
  }
  staged$reject <- with(staged, duplicate_row | outside_residence | missing_value | implausible_value | unit_mismatch)
  staged
}
