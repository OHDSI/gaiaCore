# Quality checks on staged exposure rows

Checks candidate exposure rows before they are loaded, against the
exposure already derived and the loaded residence history.

## Usage

``` r
checkStagedExposure(
  connection,
  staged,
  valueRange = c(0, Inf),
  expectedUnit = NULL
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- staged:

  A data frame with `person_id`, `exposure_start_date`,
  `exposure_end_date` and `value_as_number`, and optionally
  `location_id`, `exposure_concept_id` and `dose_unit_source_value`.
  Columns that are missing are not checked.

- valueRange:

  Plausible range of `value_as_number`.

- expectedUnit:

  Expected `dose_unit_source_value`, or `NULL` to skip that check.

## Value

`staged` with logical columns `duplicate_row` (the same person,
location, concept and interval is already in
`working.external_exposure`), `outside_residence` (the interval does not
overlap any residence interval of the person), `missing_value`,
`implausible_value`, `unit_mismatch` and `reject` (any check failed).

## Examples

``` r
if (FALSE) { # \dontrun{
checkStagedExposure(connection, staged, valueRange = c(0, 200), expectedUnit = "micrograms/cubic meter")
} # }
```
