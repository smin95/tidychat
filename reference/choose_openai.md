# Create an OpenAI chat constructor with parameter tracking

Creates a chat constructor function for OpenAI models (GPT-4, GPT-3.5,
etc.). Requires OPENAI_API_KEY environment variable to be set.

## Usage

``` r
choose_openai(
  model = "gpt-4o-mini",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  OpenAI model name. Options include:

  - "gpt-4o" (latest multimodal model)

  - "gpt-4o-mini" (faster, cheaper)

  - "gpt-4-turbo" (powerful)

  - "gpt-3.5-turbo" (legacy, cheapest)

- base_url:

  Optional custom base URL (e.g., for Azure OpenAI)

- temperature:

  Sampling temperature (0-1, higher = more random, default: 0.3)

- max_tokens:

  Maximum tokens to generate (default: 2048)

- seed:

  Optional random seed for reproducible outputs (if supported by
  provider)

- ...:

  Additional parameters passed to ellmer

## Value

A chat constructor function that returns a list with chat methods

## Examples

``` r
if (FALSE) { # \dontrun{
# Set API key in environment
Sys.setenv(OPENAI_API_KEY = "your-api-key")

# Use GPT-4o Mini for cost-effective annotation
chat <- choose_openai(model = "gpt-4o-mini", temperature = 0.2)
} # }
```
