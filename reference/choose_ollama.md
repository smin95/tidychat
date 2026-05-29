# Create an Ollama chat constructor with parameter tracking

Creates a chat constructor function for locally running Ollama models.
Ollama runs models locally on your machine, requiring no API key.

## Usage

``` r
choose_ollama(
  model = "mistral:latest",
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 500,
  seed = NULL,
  ...
)
```

## Arguments

- model:

  Ollama model name (e.g., "llama3.2:3b", "mistral:latest",
  "deepseek-coder:6.7b")

- base_url:

  Ollama API URL (default: "http://localhost:11434")

- temperature:

  Sampling temperature (0-1, higher = more random, default: 0.3)

- max_tokens:

  Maximum tokens to generate (default: 500)

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
# Basic usage with local Ollama
chat <- choose_ollama(model = "llama3")

# Use with annotation
results <- data %>%
  llm_annotate(
    .col = sentiment,
    .input = text,
    .chat = chat,
    .prompt_task = "Classify sentiment",
    .categories = c("positive", "negative")
  )

# Check available models
list_ollama_models()

# Check if Ollama is running
ollama_running()
} # }
```
