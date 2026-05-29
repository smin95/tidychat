# Process a single draw with per-row prompts

Internal function that processes one draw (iteration) of annotation
where each row has its own custom prompt. Handles batching, rate
limiting, content processing, and response parsing for per-row prompts.

## Usage

``` r
process_single_draw_with_prompts(
  data,
  text_col,
  content_col = NULL,
  prompt_col,
  extract_type_col,
  categories_col,
  batch_size,
  chat_constructor,
  delay_seconds,
  model_params = list(),
  use_structured = FALSE,
  show_progress
)
```

## Arguments

- data:

  Data frame containing items to process (must have id column)

- text_col:

  Name of column containing text input (optional)

- content_col:

  Name of column containing pre-processed content objects

- prompt_col:

  Name of column containing per-row prompts

- extract_type_col:

  Name of column containing per-row extraction types

- categories_col:

  Name of column containing per-row categories (list column)

- batch_size:

  Number of items to process per batch

- chat_constructor:

  Chat constructor function that returns a chat object

- delay_seconds:

  Delay between batches (and items within batch) in seconds

- model_params:

  List of additional model parameters

- use_structured:

  Whether to use structured extraction

- show_progress:

  Whether to show progress messages

## Value

A data frame with columns id and value (the extracted annotation)
