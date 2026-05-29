# Create an array field specification

Defines an array/list field for structured extraction with
llm_extract(). Useful when extracting multiple items of the same type.

## Usage

``` r
field_array(description, item_type, required = TRUE)
```

## Arguments

- description:

  Character string describing what to extract as a list.

- item_type:

  The type specification for each item in the array. Can be created with
  field_text(), field_integer(), etc.

- required:

  Logical. If TRUE (default), the field must be present.

## Value

A list containing field metadata and ellmer type specification.

## See also

[`llm_extract`](https://smin95.github.io/tidychat/reference/llm_extract.md)
for using field specifications

## Examples

``` r
if (FALSE) { # \dontrun{
# Define an array of themes
themes_field <- field_array(
  description = "Main themes identified in the qualitative analysis",
  item_type = field_text("A single theme or category")
)
} # }
```
