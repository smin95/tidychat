# Create a DeepSeek chat constructor with parameter tracking

Creates a chat constructor function for DeepSeek models via official API
or OpenRouter. Requires DEEPSEEK_API_KEY or OPENROUTER_API_KEY
environment variable.

## Usage

``` r
choose_deepseek(
  model = "deepseek-chat",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Model name. Options include: **Official DeepSeek API:**

  - "deepseek-chat" (DeepSeek-V3)

  - "deepseek-reasoner" (DeepSeek-R1 with reasoning) **OpenRouter:**

  - "deepseek/deepseek-chat" (DeepSeek-V3)

  - "deepseek/deepseek-r1" (DeepSeek-R1)

- base_url:

  Base URL for the API. Defaults to:

  - "https://api.deepseek.com/v1" for official API

  - "https://openrouter.ai/api/v1" for OpenRouter (auto-detected)

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
# Using official DeepSeek API
Sys.setenv(DEEPSEEK_API_KEY = "your-deepseek-api-key")
chat <- choose_deepseek(model = "deepseek-chat")

# Using OpenRouter
Sys.setenv(OPENROUTER_API_KEY = "your-openrouter-key")
chat <- choose_deepseek(model = "deepseek/deepseek-chat")
} # }
```
