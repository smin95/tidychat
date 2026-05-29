# Create an Anthropic Claude chat constructor with parameter tracking

Creates a chat constructor function for Anthropic's Claude models.
Requires ANTHROPIC_API_KEY environment variable to be set.

## Usage

``` r
choose_anthropic(
  model = "claude-sonnet-4-20250514",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Anthropic model name. Options include:

  - "claude-3-5-sonnet-20241022" (latest Sonnet, best balance)

  - "claude-3-opus-20240229" (most capable)

  - "claude-3-haiku-20240307" (fastest, cheapest)

  - "claude-sonnet-4-20250514" (newest)

- base_url:

  Optional custom base URL

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
Sys.setenv(ANTHROPIC_API_KEY = "your-api-key")

# Use Claude Haiku for fast, cheap annotation
chat <- choose_anthropic(model = "claude-3-haiku-20240307")
} # }
```
