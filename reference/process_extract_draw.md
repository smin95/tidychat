# Process a single extraction draw for llm_extract

Internal function that processes one draw (iteration) of structured
extraction, extracting multiple fields from each item using a type
specification. Handles batching, rate limiting, content processing, and
structured response parsing.

## Usage

``` r
process_extract_draw(
  data,
  text_col,
  content_col = NULL,
  prompt_task,
  type_spec,
  fields,
  batch_size,
  chat,
  delay_seconds,
  model_params = list(),
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

- prompt_task:

  The prompt template to use for all items

- type_spec:

  Ellmer type specification for structured extraction

- fields:

  Named list of field specifications (for progress reporting)

- batch_size:

  Number of items to process per batch

- chat:

  Chat constructor function that returns a chat object

- delay_seconds:

  Delay between batches (and items within batch) in seconds

- model_params:

  List of additional model parameters

- show_progress:

  Whether to show progress messages

## Value

A data frame with columns id and value (list column containing extracted
fields as a named list)
