# Annotate text or images using LLMs with multiple draws

Annotates each row in a data frame using an LLM, supporting multiple
independent draws per item for uncertainty quantification.

## Usage

``` r
llm_annotate(
  data,
  col,
  input = NULL,
  input_type = "text",
  id = NULL,
  prompt_task = NULL,
  prompt_col = NULL,
  extract_type = c("category", "integer", "number", "text", "boolean", "array"),
  categories = NULL,
  extract_type_col = NULL,
  categories_col = NULL,
  batch_size = 10,
  n_draws = 1,
  delay_seconds = 2,
  chat = NULL,
  model_params = list(),
  track_params = TRUE,
  use_structured = FALSE,
  show_progress = TRUE
)
```

## Arguments

- data:

  Data frame with content to annotate

- col:

  Name of new annotation column (unquoted)

- input:

  Column containing content to analyze (unquoted, optional)

- input_type:

  Type of input: "text", "image", "pdf", "markdown", "html" (default:
  "text")

- id:

  Optional unique ID column. If NULL, creates id from row_number()

- prompt_task:

  Fixed prompt for all rows (ignored if prompt_col provided)

- prompt_col:

  Column name containing per-row prompts (unquoted, optional)

- extract_type:

  Default extraction type: "category", "integer", "number", "text",
  "boolean", or "array" (default: "text")

- categories:

  Default categories (for category extraction)

- extract_type_col:

  Column with per-row extraction type (unquoted, optional)

- categories_col:

  Column with per-row categories (unquoted, optional, list column)

- batch_size:

  Number of items per API call (default: 10)

- n_draws:

  Number of independent draws per item (default: 1)

- delay_seconds:

  Seconds between batches (default: 2)

- chat:

  Chat constructor from choose_ollama(), choose_gemini(), etc.

- model_params:

  Optional list of additional model parameters

- track_params:

  Whether to store individual parameter columns (default: TRUE)

- use_structured:

  Use ellmer's structured extraction? (default: FALSE)

- show_progress:

  Show progress messages? (default: TRUE)

## Value

A data frame with columns: id, draw_id, annotation column, plus metadata
(model_name, provider, prompt, params_hash, and individual parameter
columns like temperature, max_tokens, top_p, etc.)

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic sentiment annotation (category)
library(dplyr)

reviews <- data.frame(
  review_id = 1:3,
  text = c("Great product!", "Terrible service", "It was okay")
)

chat <- choose_ollama(model = "llama3.2:3b")

results <- reviews |>
  llm_annotate(
    col = sentiment,
    input = text,
    id = review_id,
    prompt_task = "Classify sentiment as positive, negative, or neutral",
    extract_type = "category",
    categories = c("positive", "negative", "neutral"),
    chat = chat,
    n_draws = 3
  )

# Integer extraction (ratings)
results <- reviews |>
  llm_annotate(
    col = rating,
    input = text,
    prompt_task = "Rate this product from 1 to 5 stars",
    extract_type = "integer",
    chat = chat
  )

# Boolean extraction
results <- reviews |>
  llm_annotate(
    col = would_recommend,
    input = text,
    prompt_task = "Would the user recommend this product? Answer TRUE or FALSE",
    extract_type = "boolean",
    chat = chat
  )
} # }
```
