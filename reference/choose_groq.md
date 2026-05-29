# Create a Groq chat constructor with parameter tracking

Creates a chat constructor function for Groq's ultra-fast inference.
Requires GROQ_API_KEY environment variable to be set.

## Usage

``` r
choose_groq(
  model = "mixtral-8x7b-32768",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Groq model name. Options include:

  - "mixtral-8x7b-32768" (Mixtral, good balance)

  - "llama3-70b-8192" (Llama 3 70B, powerful)

  - "llama3-8b-8192" (Llama 3 8B, fast)

  - "gemma2-9b-it" (Google Gemma)

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
Sys.setenv(GROQ_API_KEY = "your-groq-api-key")

# Use Llama 3 70B for high-quality extraction
chat <- choose_groq(model = "llama3-70b-8192")
} # }
```
