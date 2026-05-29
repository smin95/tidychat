# Create a boolean field specification

Defines a boolean (TRUE/FALSE) field for structured extraction with
llm_extract(). The LLM will be constrained to return either TRUE or
FALSE.

## Usage

``` r
field_boolean(description, required = TRUE)
```

## Arguments

- description:

  Character string describing what boolean condition to evaluate. Frame
  as a yes/no question. Example: "Does the study report significant
  treatment effects?" (returns TRUE if yes, FALSE if no)

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
# Define a boolean field for significance
significant_field <- field_boolean(
  description = "Whether the main finding was statistically significant"
)

# Use in llm_extract
fields <- list(
  is_significant = significant_field,
  uses_preregistration = field_boolean(
    description = "Does the study mention preregistration?",
    required = FALSE
  )
)
} # }
```
