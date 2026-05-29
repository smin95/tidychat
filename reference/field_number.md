# Create a number field specification

Defines a numeric field for structured extraction with llm_extract().
The LLM will be constrained to return a numeric value (can include
decimals).

## Usage

``` r
field_number(description, required = TRUE)
```

## Arguments

- description:

  Character string describing what number to extract. Be specific about
  the meaning and possible range. Example: "Effect size (Cohen's d) from
  the statistical analysis"

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
# Define an effect size field
effect_size_field <- field_number(
  description = "Cohen's d effect size for the primary outcome"
)

# Use in llm_extract
fields <- list(
  effect_size = effect_size_field,
  p_value = field_number(
    description = "P-value for the main statistical test",
    required = FALSE
  )
)
} # }
```
