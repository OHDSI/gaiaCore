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
