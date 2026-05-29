# Create a Google Gemini chat constructor with parameter tracking

Creates a chat constructor function for Google's Gemini models. Uses
ellmer's automatic credential discovery via GEMINI_API_KEY environment
variable. Supports text, images, PDFs, and audio files.

## Usage

``` r
choose_gemini(
  model = "gemini-2.5-flash",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Gemini model name. Options include:

  - "gemini-2.5-flash" (fast, efficient)

  - "gemini-2.5-pro" (more capable, slower)

  - "gemini-2.0-flash-lite" (lightweight, free tier)

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
Sys.setenv(GEMINI_API_KEY = "your-api-key")

# Use Gemini Flash for speed
chat <- choose_gemini(model = "gemini-2.5-flash")
} # }
```
