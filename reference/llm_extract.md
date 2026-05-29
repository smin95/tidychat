# Extract multiple structured fields from text, images, PDFs, or audio

Extracts multiple structured fields from each row using an LLM with
type-safe field specifications. Supports multiple draws per item.
Multimodal extractions (images, audio, PDF) only work with specific
providers, such as Gemini.

## Usage

``` r
llm_extract(
  data,
  fields,
  input = NULL,
  input_type = "text",
  id = NULL,
  prompt_task,
  batch_size = 10,
  n_draws = 1,
  delay_seconds = 2,
  chat = NULL,
  model_params = list(),
  track_params = TRUE,
  show_progress = TRUE
)
```

## Arguments

- data:

  Data frame with content to analyze

- fields:

  Named list of field specifications from field\_\*() functions

- input:

  Column containing content to analyze (unquoted, optional)

- input_type:

  Type of input: "text", "image", "pdf", "audio", "markdown", "html"

- id:

  Optional unique ID column. If NULL, creates id from row_number()

- prompt_task:

  Task description for the LLM

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

  Whether to store model parameters as columns (default: TRUE)

- show_progress:

  Show progress messages? (default: TRUE)

## Value

A data frame with columns: id, draw_id, each field from fields, plus
metadata (model_name, provider, prompt, params_hash, and parameter
columns)

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Define extraction schema
extraction_fields <- list(
  sentiment = field_category("Sentiment", c("positive", "negative", "neutral")),
  rating = field_integer("Rating from 1 to 5"),
  would_recommend = field_boolean("Whether user would recommend")
)

# Sample data
reviews <- data.frame(
  review_id = 1:2,
  text = c(
    "Great battery life but screen is dim. I'd recommend it though - 4/5",
    "Terrible product, completely broken. Would not recommend. 1/5"
  )
)

chat <- choose_gemini(model = "gemini-2.0-flash-lite")

results <- reviews |>
  llm_extract(
    fields = extraction_fields,
    input = text,
    id = review_id,
    prompt_task = "Analyze this product review",
    chat = chat,
    n_draws = 3
  )

# Extract from audio files
audio_files <- data.frame(
  id = 1:2,
  path = c("meeting.mp3", "interview.wav")
)

audio_results <- audio_files |>
  llm_extract(
    fields = list(
      summary = field_text("Summary of the conversation"),
      speakers = field_integer("Number of speakers")
    ),
    input = path,
    input_type = "audio",
    prompt_task = "Analyze this audio recording",
    chat = choose_gemini()
  )
} # }
```
