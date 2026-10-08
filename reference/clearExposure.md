# Remove derived exposure rows

Remove derived exposure rows

## Usage

``` r
clearExposure(connection, variableName = NULL)
```

## Arguments

- connection:

  A connection from
  [`connectGaia()`](https://ohdsi.github.io/gaiaCore/reference/connectGaia.md).

- variableName:

  Remove only the rows of this variable (by name), or all rows if
  `NULL`.

## Value

Invisibly, the number of rows deleted.
