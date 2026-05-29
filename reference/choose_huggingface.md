# Create a Hugging Face chat constructor with parameter tracking

Creates a chat constructor function for models hosted on Hugging Face
Serverless Inference API. Hugging Face offers thousands of open-source
models with a generous free tier.

## Usage

``` r
choose_huggingface(
  model = "meta-llama/Llama-3.1-8B-Instruct",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 2048,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Hugging Face model name. Examples:

  - "meta-llama/Llama-3.1-8B-Instruct" (default)

  - "mistralai/Mistral-7B-Instruct-v0.3"

  - "Qwen/Qwen2.5-7B-Instruct"

  - "google/gemma-2-2b-it"

  - "microsoft/Phi-3-mini-4k-instruct"

  - "meta-llama/Llama-3.2-3B-Instruct"

- base_url:

  Optional custom base URL (default: uses ellmer's default)

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

## Details

Requires HUGGINGFACE_API_KEY environment variable to be set.

## Note

Some models do not support system prompts or other features. Check model
documentation for compatibility.

Hugging Face credentials require a Bearer token header format.

## Examples

``` r
if (FALSE) { # \dontrun{
# Set API key in environment
Sys.setenv(HUGGINGFACE_API_KEY = "your-huggingface-token")

# Use Llama 3.1 8B
chat <- choose_huggingface(model = "meta-llama/Llama-3.1-8B-Instruct")

# Use smaller model for faster inference
chat <- choose_huggingface(model = "google/gemma-2-2b-it", temperature = 0.1)

# Annotate with Hugging Face
results <- data %>%
  llm_annotate(
    col = sentiment,
    input = text,
    chat = chat,
    prompt_task = "Classify sentiment",
    categories = c("positive", "negative", "neutral")
  )
} # }
```
