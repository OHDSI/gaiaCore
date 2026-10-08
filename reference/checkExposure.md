# Quality checks on the derived exposure rows

Counts the rows of `working.external_exposure` that break basic
expectations of a clean exposure table.

## Usage

``` r
checkExposure(
  connection,
  sourceValue = NULL,
  conceptId = NULL,
  valueRange = c(0, Inf),
  expectedUnit = NULL
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- sourceValue:

  Check only rows with this `exposure_source_value`, or all if `NULL`.

- conceptId:

  Check only rows of these exposure concepts, or all if `NULL`.

- valueRange:

  Plausible range of `value_as_number`.

- expectedUnit:

  Expected `dose_unit_source_value` (for example `"ug/m3"`), or `NULL`
  to skip that check.

## Value

A data frame with `check`, `rows_flagged` and `description`; the
attribute `ok` is `TRUE` when nothing is flagged. Checks:
`duplicate_rows`, `outside_residence`, `missing_value`,
`implausible_value`, `unit_mismatch` (only with `expectedUnit`) and
`unassigned_person`.

## Examples

``` r
if (FALSE) { # \dontrun{
checkExposure(connection, valueRange = c(0, 200), expectedUnit = "ug/m3")
} # }
```
