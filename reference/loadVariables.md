# Build the geometry and attribute tables of an ingested dataset

Runs `backbone.gdsc_load_all_variables()`: creates the `working`
geometry and attribute tables of every variable registered for the
dataset, which
[`spatialJoin()`](https://ohdsi.github.io/gaiaCore/reference/spatialJoin.md)
reads.

## Usage

``` r
loadVariables(
  connection,
  tableId,
  geomLabel = "name",
  variableNodata = NULL,
  source = NULL
)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- tableId:

  Catalog identifier of an ingested dataset.

- geomLabel:

  Column of the source table used as the name of each geometry (for
  example `"name"` or `"geoid"`).

- variableNodata:

  Value that marks missing data in the source, or `NULL`.

- source:

  Free-text description of the source stored with the attributes, or
  `NULL`.

## Value

Invisibly, a data frame with one row per variable (`variable_name`,
`status`, `message`). An error is raised if a variable failed to load.
