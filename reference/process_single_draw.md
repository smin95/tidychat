# Process a single draw with fixed prompt

Internal function that processes one draw (iteration) of annotation
using a fixed prompt across all items. Handles batching, rate limiting,
content processing (text, images, PDFs), and response parsing.

## Usage

``` r
process_single_draw(
  data,
  text_col,
  content_col = NULL,
  prompt_task,
  extract_type,
  categories,
  batch_size,
  chat_constructor,
  delay_seconds,
  model_params = list(),
  use_structured = FALSE,
  type_spec = NULL,
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

- extract_type:

  Type of extraction: "category", "numeric", or "text"

- categories:

  Vector of allowed categories (for category extraction)

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

- type_spec:

  Type specification for structured extraction

- show_progress:

  Whether to show progress messages

## Value

A data frame with columns id and value (the extracted annotation)
