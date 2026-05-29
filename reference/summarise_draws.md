# Summarise multiple draws from LLM annotations

Provides summary statistics across multiple draws for each annotated
item, including agreement, entropy, and frequency distributions. Helps
identify cases where the LLM produced inconsistent responses across
draws.

## Usage

``` r
summarise_draws(
  data,
  ...,
  all = FALSE,
  agreement_threshold = 0.7,
  na_rm = TRUE
)

summarize_draws(
  data,
  ...,
  all = FALSE,
  agreement_threshold = 0.7,
  na_rm = TRUE
)
```

## Arguments

- data:

  Data frame from
  [`llm_annotate`](https://smin95.github.io/tidychat/reference/llm_annotate.md)
  or
  [`llm_extract`](https://smin95.github.io/tidychat/reference/llm_extract.md)

- ...:

  Unquoted names of annotation columns to summarise

- all:

  If TRUE, summarise all non-metadata columns (default: FALSE)

- agreement_threshold:

  Agreement threshold below which to flag as uncertain (default: 0.7).
  Lower values mean more tolerance for disagreement.

- na_rm:

  Remove NA values before calculating summaries? (default: TRUE)

## Value

A tibble with columns:

- column:

  Name of the annotation column summarised

- n_draws:

  Total number of draws

- n_valid:

  Number of valid (non-NA) responses

- majority:

  Most common value (or mean for numeric data)

- agreement:

  Proportion of draws matching the majority (0-1)

- entropy:

  Normalised Shannon entropy (0-1, higher = more uncertain)

- uncertain:

  TRUE if agreement \< agreement_threshold

- distribution:

  Frequency distribution of responses as a string

## See also

[`llm_annotate`](https://smin95.github.io/tidychat/reference/llm_annotate.md)
for generating multiple draws,
[`llm_extract`](https://smin95.github.io/tidychat/reference/llm_extract.md)
for structured extraction

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Basic usage
results <- reviews |>
  llm_annotate(
    col = sentiment,
    input = text,
    chat = chat,
    n_draws = 5
  )

# Summarise draws
results |> summarise_draws(sentiment)

# For llm_extract results (multiple columns)
results |> summarise_draws(sentiment, rating, would_recommend)

# Find uncertain items (agreement < 0.7)
results |>
  summarise_draws(sentiment) |>
  filter(uncertain == TRUE)

# With grouping (e.g., by temperature or prompt framing)
results |>
  group_by(temperature, framing) |>
  summarise_draws(distress_rating)

# Summarise all non-metadata columns
results |> summarise_draws(all = TRUE)

# Custom agreement threshold (more strict)
results |> summarise_draws(sentiment, agreement_threshold = 0.8)
} # }
```
