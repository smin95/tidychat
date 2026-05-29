# 3. Generating Texts with LLM

This section demonstrates how to generate structured synthetic data
using
[`llm_generate()`](https://smin95.github.io/tidychat/reference/llm_generate.md).
This is particularly useful for creating vignettes for scale
development, simulating patient profiles for training materials,
generating stimulus materials for experiments, or pilot testing coding
schemes before real data collection.

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

## Define Generation Schema

We’ll generate realistic therapy intake vignettes for research training.
Each field is typed to ensure consistent output across generated cases.

``` r

vignette_schema <- list(
  # Patient demographics
  age = field_integer(
    description = "Patient age (25-65)"
  ),

  gender = field_category(
    description = "Patient gender",
    categories = c("male", "female", "non-binary", "prefer not to say")
  ),

  # Clinical information
  diagnosis = field_category(
    description = "Primary diagnosis",
    categories = c("major depressive disorder", "generalized anxiety disorder",
                   "social anxiety disorder", "PTSD", "panic disorder", "adjustment disorder")
  ),

  severity = field_category(
    description = "Symptom severity",
    categories = c("mild", "moderate", "severe")
  ),

  # Symptoms (array field for multiple symptoms)
  symptoms = field_array(
    description = "List of 3-5 specific symptoms mentioned",
    item_type = field_text("A specific symptom")
  ),

  # Numeric ratings
  duration_months = field_number(
    description = "Duration of symptoms in months (1-60). Vary this number.",
    required = TRUE
  ),

  # Free text vignette
  vignette = field_text(
    description = "The complete therapy intake vignette (3-4 sentences describing the patient's presentation)"
  ),

  # Boolean flags
  prior_treatment = field_boolean(
    description = "Has the patient received prior treatment?"
  )
)
```

## Generate Synthetic Data

The key arguments to `llm_generate` are:

- **`n`**: Number of synthetic items to generate
- **`fields`**: Named list of field specifications defining the
  structure of generated data
- **`prompt_template`**: Instructions to guide the LLM on what to
  generate
- **`chat`**: The chat constructor function that defines which model and
  parameters to use
- **`n_draws`**: Number of independent draws per item – useful for
  checking consistency across generations

``` r

synthetic_responses <- llm_generate(
  n = 5,
  fields = vignette_schema,
  prompt_template = "Generate a realistic therapy intake vignette for an adult patient.
                     Include age, gender, primary diagnosis, severity level,
                     3-5 specific symptoms, duration of symptoms (in months),
                     and whether they've had prior treatment.",
  chat = chat,
  n_draws = 2,  # 2 draws per vignette to check consistency
  show_progress = TRUE
)

head(synthetic_responses)
```

    #>   id draw_id model_name provider
    #> 1  1       1     llama3   ollama
    #> 2  2       1     llama3   ollama
    #> 3  3       1     llama3   ollama
    #> 4  4       1     llama3   ollama
    #> 5  5       1     llama3   ollama
    #> 6  1       2     llama3   ollama
    #>                                                                                                                                                                                                                                                                                           prompt
    #> 1 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #> 2 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #> 3 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #> 4 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #> 5 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #> 6 Generate a realistic therapy intake vignette for an adult patient.\n                     Include age, gender, primary diagnosis, severity level,\n                     3-5 specific symptoms, duration of symptoms (in months),\n                     and whether they've had prior treatment.
    #>   params_hash          query_time age gender                 diagnosis severity
    #> 1    0128e27a 2026-05-29 08:54:47  32 female major depressive disorder moderate
    #> 2    0128e27a 2026-05-29 08:54:47  32 female major depressive disorder moderate
    #> 3    0128e27a 2026-05-29 08:54:47  32 female major depressive disorder moderate
    #> 4    0128e27a 2026-05-29 08:54:47  32 female major depressive disorder moderate
    #> 5    0128e27a 2026-05-29 08:54:47  32 female major depressive disorder moderate
    #> 6    0128e27a 2026-05-29 08:59:04  32 female major depressive disorder moderate
    #>                                                                                                                                                                                                               symptoms
    #> 1                      persistent feelings of sadness and hopelessness, loss of interest in activities previously enjoyed, difficulty sleeping (insomnia), fatigue and lack of energy, recurrent thoughts of self-harm
    #> 2                                          persistent feelings of sadness and hopelessness, loss of interest in activities previously enjoyed, difficulty sleeping (insomnia), increased irritability, racing thoughts
    #> 3                      persistent feelings of sadness and hopelessness, loss of interest in activities previously enjoyed, difficulty sleeping (insomnia), fatigue and lack of energy, recurrent thoughts of self-harm
    #> 4 persistent feelings of sadness and hopelessness, loss of interest in activities previously enjoyed, difficulty concentrating and making decisions, increased sleepiness during the day, irritability and mood swings
    #> 5                                                                                                                        sadness, fatigue, loss of interest in activities, difficulty concentrating, suicidal thoughts
    #> 6                                 persistent feelings of sadness and hopelessness, loss of interest in activities she once enjoyed, difficulty sleeping (insomnia), fatigue and lack of energy, increased irritability
    #>   duration_months
    #> 1               6
    #> 2               6
    #> 3               6
    #> 4               6
    #> 5               6
    #> 6               6
    #>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   vignette
    #> 1                                                                                                                                                                                                                                                                                                        Sarah is a 32-year-old female who has been experiencing symptoms of major depressive disorder for the past six months. She reports feeling persistently sad and hopeless, with a loss of interest in activities she once enjoyed. Sarah also describes difficulty sleeping (insomnia), fatigue and lack of energy, and recurrent thoughts of self-harm. Prior to seeking therapy, Sarah had tried to manage her symptoms on her own through exercise and meditation, but has not sought professional help before.
    #> 2                                                                                                                                                                                                                                            Sarah, a 32-year-old woman, has been experiencing symptoms of major depressive disorder for the past six months. She reports feeling persistently sad and hopeless, with a loss of interest in activities she once enjoyed. Sarah also struggles with insomnia, often lying awake at night thinking about her problems. She becomes easily irritated when minor frustrations arise, and her mind races with negative thoughts. Despite her best efforts, Sarah has been unable to shake these feelings, which have started to affect her relationships and daily functioning.
    #> 3                                                                                                                                                                                                                                                                                          Sarah is a 32-year-old female who has been experiencing symptoms of major depressive disorder for the past six months. She reports feeling persistently sad and hopeless, which has led to her losing interest in activities she previously enjoyed. Sarah also experiences difficulty sleeping (insomnia) and feels fatigued and lacks energy. In addition, she has had recurrent thoughts of self-harm. Sarah is seeking therapy because she wants to learn how to manage her symptoms and improve her overall mental health.
    #> 4                                                                                                     Sarah, a 32-year-old woman, has been experiencing symptoms of major depressive disorder for approximately six months. She initially noticed changes in her mood and energy levels after the birth of her second child. Prior to this episode, Sarah had never experienced depression or any other mental health issues. Sarah's primary symptoms include persistent feelings of sadness and hopelessness, loss of interest in activities she once enjoyed, difficulty concentrating and making decisions, increased sleepiness during the day, and irritability and mood swings. She has tried self-help strategies such as meditation and exercise but has not found them to be effective in managing her symptoms.
    #> 5                                                                                                                                    Sarah is a 32-year-old female who has been experiencing symptoms of major depressive disorder for the past six months. She reports feeling sad and hopeless most days, with periods of fatigue that make it difficult to engage in activities she once enjoyed. Sarah also describes a loss of interest in things she used to find enjoyable, such as spending time with friends or watching movies. Additionally, she has difficulty concentrating and making decisions, which is affecting her work performance. In the past few weeks, Sarah has started having suicidal thoughts, which are causing her significant distress. She has not had any prior treatment for depression.
    #> 6 Sarah is a 32-year-old woman who has been experiencing symptoms of depression for the past six months. She reports feeling sad and hopeless most days, which has led to her losing interest in activities she once enjoyed, such as hiking and spending time with friends. Sarah also describes difficulty sleeping at night, often waking up multiple times and having trouble falling back asleep. She feels fatigued and lacks energy during the day, making it difficult for her to complete tasks or engage in social activities. Additionally, Sarah has become increasingly irritable, snapping at loved ones and feeling overwhelmed by even minor frustrations. Prior to this episode of depression, Sarah had not experienced any significant life changes or trauma that would have triggered these symptoms.
    #>   prior_treatment temperature max_tokens seed
    #> 1           FALSE         0.3        500  123
    #> 2           FALSE         0.3        500  123
    #> 3           FALSE         0.3        500  123
    #> 4           FALSE         0.3        500  123
    #> 5           FALSE         0.3        500  123
    #> 6           FALSE         0.3        500  123

The output of
[`llm_generate()`](https://smin95.github.io/tidychat/reference/llm_generate.md)
mirrors the structure of
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md):
a tidy data frame where each row represents a single draw from the LLM.
The key columns include: `id` (the generated case number, from 1 to n),
`draw_id` (the draw number, from 1 to `n_draws`), each generated field
named after the corresponding element in `fields` (here `age`, `gender`,
`diagnosis`, `severity`, `symptoms`, `duration_months`, `vignette`,
`prior_treatment`), plus metadata columns `model_name`, `provider`,
`prompt`, `params_hash`, and individual parameter columns
(`temperature`, `max_tokens`).

Note that symptoms is a list column because
[`field_array()`](https://smin95.github.io/tidychat/reference/field_array.md)
returns multiple values per case. This is R’s natural way of handling
nested data and works seamlessly with `purrr` for further processing
(e.g., `map_int(symptoms, length)` to count symptoms per case).

## Assess Generation Consistency

We can use
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
to evaluate how consistently the LLM generates the same information
across the 2 draws per vignette. The function requires you to specify
which columns to analyze—here we pass `age`, `gender`, `diagnosis`,
`severity`, and `prior_treatment` as arguments. By grouping by `id`
first,
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
calculates reliability metrics for each field separately across the two
draws.

``` r

reliability <- synthetic_responses %>%
  group_by(id) %>%
  summarise_draws(age, gender, diagnosis, severity, prior_treatment)

print(reliability)
#> # A tibble: 25 × 9
#>    column    id n_draws n_valid majority agreement entropy uncertain
#>    <chr>  <int>   <int>   <int> <chr>        <dbl>   <dbl> <lgl>    
#>  1 age        1       2       2 32           1           0 FALSE    
#>  2 age        2       2       2 33.5         0.500       1 TRUE     
#>  3 age        3       2       2 32           1           0 FALSE    
#>  4 age        4       2       2 32           1           0 FALSE    
#>  5 age        5       2       2 32           1           0 FALSE    
#>  6 gender     1       2       2 female       1           0 FALSE    
#>  7 gender     2       2       2 female       1           0 FALSE    
#>  8 gender     3       2       2 female       1           0 FALSE    
#>  9 gender     4       2       2 female       1           0 FALSE    
#> 10 gender     5       2       2 female       1           0 FALSE    
#> # ℹ 15 more rows
#> # ℹ 1 more variable: distribution <chr>
```

The output shows high consistency across most fields. `gender`,
`diagnosis`, `severity`, and `prior_treatment` achieved perfect
agreement (agreement = 1) across all 5 cases. The `age` field showed
perfect agreement for 4 out of 5 cases (agreement = 1), with only case 2
showing variability (agreement = 0.5) where draws reported 32 and 35.
This minimal variability is actually desirable for generation
tasks—unlike extraction where we want consistency, generation benefits
from diversity across draws to create varied synthetic cases. The
`symptoms` and `duration_months` fields are list/numeric data; we check
their consistency separately below.

## Check Numeric Consistency

For numeric fields like `duration_months`, we can calculate variability
across draws using standard `dplyr` operations:

``` r

numeric_consistency <- synthetic_responses %>%
  group_by(id) %>%
  summarise(
    duration_mean = mean(as.numeric(duration_months)),
    duration_sd = sd(as.numeric(duration_months)),
    duration_consistent = duration_sd == 0,
    .groups = "drop"
  )

print(numeric_consistency)
#> # A tibble: 5 × 4
#>      id duration_mean duration_sd duration_consistent
#>   <int>         <dbl>       <dbl> <lgl>              
#> 1     1             6           0 TRUE               
#> 2     2             6           0 TRUE               
#> 3     3             6           0 TRUE               
#> 4     4             6           0 TRUE               
#> 5     5             6           0 TRUE
```

The results show that all cases had perfect consistency (duration_sd =
0), with every draw reporting 6 months. Unlike extraction tasks where we
typically want perfect agreement, this complete consistency in
generation suggests the LLM is not producing diverse synthetic cases.
For generation tasks, some variability is often desirable—researchers
may need to adjust parameters (e.g., increase temperature) to achieve
greater diversity across draws.

## Summary

[`llm_generate()`](https://smin95.github.io/tidychat/reference/llm_generate.md)
creates structured synthetic data for research and training. By
specifying typed fields and generating multiple draws, you can create
realistic vignettes, check consistency with
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md),
and control diversity across draws (low SD = consistent profiles, high
SD = varied examples). The function integrates with the `tidyverse` for
filtering, mutating, and reshaping generated data.
