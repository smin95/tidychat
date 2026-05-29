# Create an integer field specification

Defines an integer field for structured extraction with llm_extract().
The LLM will be constrained to return an integer value.

## Usage

``` r
field_integer(description, required = TRUE)
```

## Arguments

- description:

  Character string describing what integer to extract. Be specific about
  the range or meaning. Example: "Rating from 1 to 5 stars"

- required:

  Logical. If TRUE (default), the field must be present in the
  extraction. If FALSE, the field is optional.

## Value

A list containing field metadata and ellmer type specification for
structured extraction.

## See also

[`llm_extract`](https://smin95.github.io/tidychat/reference/llm_extract.md)
for using field specifications

## Examples

``` r
if (FALSE) { # \dontrun{
# Define a rating field
rating_field <- field_integer(
  description = "Number of stars given in the review (1-5)"
)

# Use in llm_extract
fields <- list(
  rating = rating_field,
  session_count = field_integer(
    description = "Number of therapy sessions attended",
    required = FALSE
  )
)
} # }
```
