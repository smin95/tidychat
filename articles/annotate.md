# 1. Annotating Texts with LLM

This section demonstrates the core functionality of `tidychat`:
annotating text with multiple draws and quantifying uncertainty. We’ll
analyze therapy session notes and identify which cases need human
review.

## Setup

First, load the package and create a chat constructor. We’ll use Ollama
with a small free model:

``` r

library(tidychat)
library(tidyr)
library(dplyr)

# Initialize Ollama (make sure Ollama is running locally)
# Run: ollama pull llama3.2:3b
chat <- choose_ollama(model = "llama3", temperature = 0.3, seed = 123)
```

## Prepare Data

We have five therapy session notes to analyze:

``` r

therapy_notes <- data.frame(
  client_id = 1:5,
  session_note = c(
    "Client reported significant progress this week. Has been using coping 
     strategies consistently and feeling more in control of anxiety symptoms.",
    
    "Client expressed frustration with lack of progress. Feels stuck and 
     unmotivated despite practicing techniques.",
    
    "Mixed session. Some good moments discussing family dynamics, but client 
     seemed distracted and fatigued throughout.",
    
    "Breakthrough session! Client connected childhood experiences to current 
     relationship patterns for the first time. Emotional but hopeful.",
    
    "Routine check-in. Client is stable but notes feeling 'blah' about everything. 
     No significant changes positive or negative."
  ),
  stringsAsFactors = FALSE
)
```

## Annotate with Multiple Draws

We’ll classify each note as positive, negative, or neutral, taking 5
independent draws per client. Multiple draws allow us to measure how
confident the LLM is in each classification.

The key arguments to
[`llm_annotate()`](https://smin95.github.io/tidychat/reference/llm_annotate.md)
are:

- **`col`**: The name of the new column that will contain the
  annotations (`sentiment` in this example)
- **`input`**: The column containing the text to be analyzed
  (`session_note`)
- **`id`**: An optional unique identifier column; if not provided, a
  `.id` column is automatically created
- **`prompt_task`**: The instruction given to the LLM describing what to
  extract
- **`extract_type`**: The type of output expected – here “category”
  tells the LLM to choose from predefined options
- **`categories`**: The allowed values for categorical extraction, which
  the LLM is constrained to return
- **`chat`**: The chat constructor function that defines which model and
  parameters to use
- **`n_draws`**: The number of independent draws (repeated judgments)
  per item – the core feature for uncertainty quantification

``` r

results <- therapy_notes %>%
  llm_annotate(
    col = sentiment,
    input = session_note,
    id = client_id,
    prompt_task = "Classify the sentiment of this therapy note as positive, 
                    negative, or neutral. Return only one word.",
    extract_type = "category",
    categories = c("positive", "negative", "neutral"),
    chat = chat,
    n_draws = 5,
    show_progress = TRUE
  )

head(results)
```

    #>   id
    #> 1  1
    #> 2  2
    #> 3  3
    #> 4  4
    #> 5  5
    #> 6  1
    #>                                                                                                                                            session_note
    #> 1 Client reported significant progress this week. Has been using coping \n     strategies consistently and feeling more in control of anxiety symptoms.
    #> 2                                 Client expressed frustration with lack of progress. Feels stuck and \n     unmotivated despite practicing techniques.
    #> 3                             Mixed session. Some good moments discussing family dynamics, but client \n     seemed distracted and fatigued throughout.
    #> 4       Breakthrough session! Client connected childhood experiences to current \n     relationship patterns for the first time. Emotional but hopeful.
    #> 5                     Routine check-in. Client is stable but notes feeling 'blah' about everything. \n     No significant changes positive or negative.
    #> 6 Client reported significant progress this week. Has been using coping \n     strategies consistently and feeling more in control of anxiety symptoms.
    #>   draw_id sentiment model_name provider
    #> 1       1  positive     llama3   ollama
    #> 2       1  negative     llama3   ollama
    #> 3       1  negative     llama3   ollama
    #> 4       1  positive     llama3   ollama
    #> 5       1   neutral     llama3   ollama
    #> 6       2  positive     llama3   ollama
    #>                                                                                                                       prompt
    #> 1 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #> 2 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #> 3 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #> 4 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #> 5 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #> 6 Classify the sentiment of this therapy note as positive, \n                    negative, or neutral. Return only one word.
    #>   params_hash          query_time temperature max_tokens seed
    #> 1    0128e27a 2026-05-29 08:39:31         0.3        500  123
    #> 2    0128e27a 2026-05-29 08:39:31         0.3        500  123
    #> 3    0128e27a 2026-05-29 08:39:31         0.3        500  123
    #> 4    0128e27a 2026-05-29 08:39:31         0.3        500  123
    #> 5    0128e27a 2026-05-29 08:39:31         0.3        500  123
    #> 6    0128e27a 2026-05-29 08:39:59         0.3        500  123

The output of
[`llm_annotate()`](https://smin95.github.io/tidychat/reference/llm_annotate.md)
is a tidy data frame where each row represents a single draw from the
LLM. The key columns include: `item_id` (the original identifier),
`draw_id` (the draw number, from 1 to `.n_draws`), the annotation column
(named after `col`, in this case `sentiment`), plus metadata columns
`model_name`, `provider`, `prompt`, `params_hash`, and individual
parameter columns (`temperature`, `max_tokens`, `seed`). This
long-format structure is designed to work with `dplyr` functions such as
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) and
others.

## Quantify Uncertainty (or Agreement)

We can then use
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
to quantify uncertainty across the 5 draws. The function requires you to
specify which column(s) to analyze - here we pass sentiment as the
column to summarize. It collapses the multiple draws per item into a
single row of summary statistics, grouped by the identifiers we provided
(`id` and `session_note`).

``` r

uncertainty <- results %>%
  group_by(id, session_note) %>%
  summarise_draws(sentiment)

print(uncertainty)
#> # A tibble: 5 × 10
#>   column    id session_note n_draws n_valid majority agreement entropy uncertain
#>   <chr>  <int> <chr>          <int>   <int> <chr>        <dbl>   <dbl> <lgl>    
#> 1 senti…     1 "Client rep…       5       5 positive       1     0     FALSE    
#> 2 senti…     2 "Client exp…       5       5 negative       1     0     FALSE    
#> 3 senti…     3 "Mixed sess…       5       5 neutral        0.6   0.971 TRUE     
#> 4 senti…     4 "Breakthrou…       5       5 positive       1     0     FALSE    
#> 5 senti…     5 "Routine ch…       5       5 neutral        1     0     FALSE    
#> # ℹ 1 more variable: distribution <chr>
```

The output of
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
is a tidy summary table where each row corresponds to one original item
(identified by the `id` and `session_note` columns), collapsing the 5
draws per item into summary statistics. The majority column shows the
most frequent `sentiment` across draws, `agreement` reports the
proportion of draws matching that majority (1.0 = perfect agreement),
`entropy` quantifies uncertainty (0 = no uncertainty), and
`distribution` shows the complete frequency distribution across all
draws (e.g., “positive (5)” indicates all 5 draws were positive).

## Flag Cases for Human Review

Here, we establish so that cases with agreement below 70% (the default
threshold) should be reviewed by a human.

``` r

needs_review <- uncertainty %>%
  filter(uncertain == TRUE) %>%
  select(id, majority, agreement, entropy, distribution)

print(needs_review)
#> # A tibble: 1 × 5
#>      id majority agreement entropy distribution             
#>   <int> <chr>        <dbl>   <dbl> <chr>                    
#> 1     3 neutral        0.6   0.971 neutral (3), negative (2)
```

There is one row with agreement of 0.6.

## Summary

`tidychat`’s multi-draw approach provides a principled way to quantify
LLM uncertainty. By taking multiple independent judgments and measuring
agreement, users can make informed decisions about which automated
annotations to trust.
