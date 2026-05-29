# Create a text field specification

Defines a free-text field for structured extraction with llm_extract().
The LLM will return a text string (not constrained to categories).

## Usage

``` r
field_text(description, required = TRUE)
```

## Arguments

- description:

  Character string describing what text to extract. Be specific about
  length and content. Example: "Summarize the main limitation mentioned
  by the authors (max 50 words)"

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
# Define a text field for extracting limitations
limitation_field <- field_text(
  description = "Main limitation or weakness reported in the study"
)

# Use in llm_extract
fields <- list(
  limitation = limitation_field,
  conclusion = field_text(
    description = "Author's main conclusion (one sentence)",
    required = FALSE
  )
)
} # }
```
