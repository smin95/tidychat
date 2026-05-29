# Create a category field specification

Defines a categorical field for structured extraction with
llm_extract(). The LLM will be constrained to return one of the
specified categories.

## Usage

``` r
field_category(description, categories, required = TRUE)
```

## Arguments

- description:

  Character string describing what to extract. This guides the LLM on
  what information to look for. Be specific and clear. Example: "The
  primary emotion expressed in the text"

- categories:

  Character vector of allowed category values. The LLM will only return
  values from this list. Example: c("happy", "sad", "neutral")

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
# Define a sentiment field
sentiment_field <- field_category(
  description = "Overall sentiment of the review",
  categories = c("positive", "negative", "neutral")
)

# Use in llm_extract
fields <- list(
  sentiment = sentiment_field,
  would_recommend = field_category(
    description = "Would the user recommend this product?",
    categories = c("yes", "no", "maybe")
  )
)
} # }
```
