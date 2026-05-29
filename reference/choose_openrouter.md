# Create an OpenRouter chat constructor with parameter tracking

Creates a chat constructor function for models hosted on OpenRouter.
Requires OPENROUTER_API_KEY environment variable to be set.

## Usage

``` r
choose_openrouter(
  model = "openai/gpt-4o-mini",
  app_name = NULL,
  app_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  OpenRouter model name. Examples:

  - "openai/gpt-4o" (OpenAI)

  - "anthropic/claude-3.5-sonnet" (Anthropic)

  - "google/gemini-2.0-flash-exp" (Google)

  - "meta-llama/llama-3.1-405b-instruct" (Meta)

- app_name:

  Optional app name for OpenRouter headers

- app_url:

  Optional app URL for OpenRouter headers

- temperature:

  Sampling temperature (0-1, default: 0.3)

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
Sys.setenv(OPENROUTER_API_KEY = "your-key")
chat <- choose_openrouter(model = "openai/gpt-4o-mini")
} # }
```
