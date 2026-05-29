# Generate structured synthetic data

Creates synthetic data from scratch using an LLM, with structured output
defined by field specifications. Perfect for generating vignettes,
survey responses, stimulus materials, or test data.

## Usage

``` r
llm_generate(n, fields, prompt_template = NULL, chat = NULL, n_draws = 1, ...)
```

## Arguments

- n:

  Number of items to generate

- fields:

  Named list of field specifications from field\_\*() functions

- prompt_template:

  Template prompt (can include placeholders like {row})

- chat:

  Chat constructor

- n_draws:

  Number of independent draws per item (default: 1)

- ...:

  Additional arguments passed to llm_extract

## Value

A data frame with columns: id, draw_id, and each field from fields

## Examples

``` r
if (FALSE) { # \dontrun{
schema <- list(
  age = field_integer("Patient age (20-80)"),
  diagnosis = field_category("Diagnosis", c("depression", "GAD", "PTSD")),
  vignette = field_text("The therapy vignette (2-3 sentences)")
)

# Generate 10 synthetic therapy vignettes
synthetic_data <- llm_generate(
  n = 10,
  fields = schema,
  prompt_template = "Generate a therapy vignette.",
  chat = chat
)
} # }
```
