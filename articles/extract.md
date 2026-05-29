# 2. Extracting Information from Texts/PDFs/Images with LLM into Multiple Columns

This section shows how to extract structured data from research
abstracts using
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md).
This is particularly useful for systematic reviews and meta-analyses
where researchers need to quickly code hundreds of abstracts.

## Setup

First, load the package and create a chat constructor. We’ll use Ollama
with a small free model:

``` r

library(tidychat)
library(tidyr)
library(dplyr)

# Initialize Ollama (make sure Ollama is running locally)
chat <- choose_ollama(model = "llama3", temperature = 0.3, seed = 123)
```

Note: For PDF or image extraction, try using models from Gemini or other
community models from OpenRouter.

## Define Extraction Schema

We’ll extract key study characteristics from psychology abstracts. Each
field is typed to ensure consistent output.

``` r

extraction_fields <- list(
  sample_size = field_number(
    description = "Total number of participants in the study"
  ),
  
  study_design = field_category(
    description = "Study design type",
    categories = c("RCT", "quasi-experimental", "correlational", 
                   "longitudinal", "meta-analysis", "qualitative")
  ),
  
  effect_size = field_number(
    description = "Reported effect size (Cohen's d, Hedges' g, or r). 
                   Extract NA if not reported.",
    required = FALSE
  ),
  
  significant = field_category(
    description = "Were the main findings statistically significant?",
    categories = c("yes", "no", "mixed", "not reported")
  ),
  
  population = field_category(
    description = "Population studied",
    categories = c("clinical", "community", "student", "older adult", 
                   "child/adolescent", "mixed")
  )
)
```

## Prepare Abstracts

We have four sample abstracts from psychology research.

``` r

abstracts <- data.frame(
  abstract_text = c(
    "We recruited 120 undergraduate students (M_age = 19.4, 65% female) 
     to test mindfulness training on anxiety. Participants were randomized 
     to 8-week MBSR or waitlist control. Results showed significant 
     reduction in anxiety (d = 0.72, p < .001).",
    
    "In a sample of 45 adults with GAD (ages 22-65), we compared CBT to 
     supportive therapy. No significant between-group differences were 
     found (d = 0.12, p = .45).",
    
    "This meta-analysis synthesized 28 studies (N = 3,247 participants) 
     examining social media use and depression in adolescents. Overall 
     effect was small but significant (r = 0.18, 95% CI [0.12, 0.24]).",
    
    "We conducted a longitudinal study with 89 mother-child dyads (children 
     aged 3-5) to examine parenting styles and emotional development. 
     No significant effects were found (β = 0.08, p = .32)."
  ),
  stringsAsFactors = FALSE
)
```

## Extract Structured Data

We use
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md)
to extract all fields in a single API call per abstract.

``` r

results <- abstracts %>%
  llm_extract(
    fields = extraction_fields,
    input = abstract_text,
    prompt_task = "Extract key study characteristics from this abstract 
                    for a systematic review.",
    chat = chat,
    n_draws = 3,  # 3 draws for reliability check
    show_progress = TRUE
  )

head(results)
```

    #>                                                                                                                                                                                                                                                             abstract_text
    #> 1 We recruited 120 undergraduate students (M_age = 19.4, 65% female) \n     to test mindfulness training on anxiety. Participants were randomized \n     to 8-week MBSR or waitlist control. Results showed significant \n     reduction in anxiety (d = 0.72, p < .001).
    #> 2                                                                                           In a sample of 45 adults with GAD (ages 22-65), we compared CBT to \n     supportive therapy. No significant between-group differences were \n     found (d = 0.12, p = .45).
    #> 3                                                    This meta-analysis synthesized 28 studies (N = 3,247 participants) \n     examining social media use and depression in adolescents. Overall \n     effect was small but significant (r = 0.18, 95% CI [0.12, 0.24]).
    #> 4                                                            We conducted a longitudinal study with 89 mother-child dyads (children \n     aged 3-5) to examine parenting styles and emotional development. \n     No significant effects were found (β = 0.08, p = .32).
    #> 5 We recruited 120 undergraduate students (M_age = 19.4, 65% female) \n     to test mindfulness training on anxiety. Participants were randomized \n     to 8-week MBSR or waitlist control. Results showed significant \n     reduction in anxiety (d = 0.72, p < .001).
    #> 6                                                                                           In a sample of 45 adults with GAD (ages 22-65), we compared CBT to \n     supportive therapy. No significant between-group differences were \n     found (d = 0.12, p = .45).
    #>   id draw_id model_name provider
    #> 1  1       1     llama3   ollama
    #> 2  2       1     llama3   ollama
    #> 3  3       1     llama3   ollama
    #> 4  4       1     llama3   ollama
    #> 5  1       2     llama3   ollama
    #> 6  2       2     llama3   ollama
    #>                                                                                                prompt
    #> 1 Extract key study characteristics from this abstract \n                    for a systematic review.
    #> 2 Extract key study characteristics from this abstract \n                    for a systematic review.
    #> 3 Extract key study characteristics from this abstract \n                    for a systematic review.
    #> 4 Extract key study characteristics from this abstract \n                    for a systematic review.
    #> 5 Extract key study characteristics from this abstract \n                    for a systematic review.
    #> 6 Extract key study characteristics from this abstract \n                    for a systematic review.
    #>   params_hash          query_time sample_size  study_design effect_size
    #> 1    0128e27a 2026-05-29 08:47:06         120           RCT        0.72
    #> 2    0128e27a 2026-05-29 08:47:06          45           RCT        0.12
    #> 3    0128e27a 2026-05-29 08:47:06        3247 meta-analysis        0.18
    #> 4    0128e27a 2026-05-29 08:47:06          89  longitudinal        <NA>
    #> 5    0128e27a 2026-05-29 08:48:11         120           RCT        0.72
    #> 6    0128e27a 2026-05-29 08:48:11          45           RCT        0.12
    #>   significant       population temperature max_tokens seed
    #> 1         yes          student         0.3        500  123
    #> 2          no      older adult         0.3        500  123
    #> 3         yes      older adult         0.3        500  123
    #> 4          no child/adolescent         0.3        500  123
    #> 5         yes          student         0.3        500  123
    #> 6          no      older adult         0.3        500  123

The output of
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md)
is a tidy data frame where each row represents a single draw from the
LLM, with structured fields extracted as separate columns. The key
columns include: `id` (the original identifier), `draw_id` (the draw
number, from 1 to `n_draws`), each extracted field named after the
corresponding element in `fields` (here `sample_size`, `study_design`,
`effect_size`, `significant`, `population`), plus metadata columns
`model_name`, `provider`, `prompt`, `params_hash`, and individual
parameter columns (`temperature`, `max_tokens`, `seed`). This
long-format structure allows researchers to examine variability across
draws for each extracted field using standard `dplyr` verbs like
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html) and
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md).

## Assess Extraction Reliability

We can use
[`summarise_draws()`](https://smin95.github.io/tidychat/reference/summarise_draws.md)
to evaluate how consistently the LLM extracted each field across the 3
draws. Pass the field names you want to analyze as arguments - here we
pass `sample_size`, `study_design`, `significant`, and `population` to
calculate reliability metrics for each field separately.

``` r

reliability <- results %>%
  group_by(id) %>%
  summarise_draws(sample_size, study_design, significant, population)

print(reliability)
#> # A tibble: 16 × 9
#>    column          id n_draws n_valid majority       agreement entropy uncertain
#>    <chr>        <int>   <int>   <int> <chr>              <dbl>   <dbl> <lgl>    
#>  1 sample_size      1       3       3 120                    1       0 FALSE    
#>  2 sample_size      2       3       3 45                     1       0 FALSE    
#>  3 sample_size      3       3       3 3247                   1       0 FALSE    
#>  4 sample_size      4       3       3 89                     1       0 FALSE    
#>  5 study_design     1       3       3 RCT                    1       0 FALSE    
#>  6 study_design     2       3       3 RCT                    1       0 FALSE    
#>  7 study_design     3       3       3 meta-analysis          1       0 FALSE    
#>  8 study_design     4       3       3 longitudinal           1       0 FALSE    
#>  9 significant      1       3       3 yes                    1       0 FALSE    
#> 10 significant      2       3       3 no                     1       0 FALSE    
#> 11 significant      3       3       3 yes                    1       0 FALSE    
#> 12 significant      4       3       3 no                     1       0 FALSE    
#> 13 population       1       3       3 student                1       0 FALSE    
#> 14 population       2       3       3 older adult            1       0 FALSE    
#> 15 population       3       3       3 older adult            1       0 FALSE    
#> 16 population       4       3       3 child/adolesc…         1       0 FALSE    
#> # ℹ 1 more variable: distribution <chr>
```

The output shows that all fields achieved perfect reliability for every
abstract (agreement = 1, entropy = 0). For `sample_size`, all 3 draws
produced identical numbers (e.g., 120 for study 1, 45 for study 2). For
categorical fields like `study_design` and `significant`, the
`distribution` column confirms complete consistency across draws (e.g.,
“`RCT (3)`” indicates all 3 draws classified the design as RCT). This
high agreement indicates that for these clear-cut abstracts, the LLM’s
extractions are trustworthy without manual verification. However, note
the `effect_size` field was omitted because it had missing values (`NA`)
for some studies.

## View Extracted Data

Once we’ve confirmed high reliability across draws, we can collapse the
multiple draws into a single row per study for further analysis. Using
`group_by(id)` followed by
[`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html)
with [`first()`](https://dplyr.tidyverse.org/reference/nth.html), we
take the first (or any) draw’s values since all draws agreed perfectly.

``` r

extracted_data <- results %>%
  group_by(id) %>%
  summarise(
    design = first(study_design),
    n = as.numeric(first(sample_size)),
    population = first(population),
    significant = first(significant),
    .groups = "drop"
  )

print(extracted_data)
#> # A tibble: 4 × 5
#>      id design            n population       significant
#>   <int> <chr>         <dbl> <chr>            <chr>      
#> 1     1 RCT             120 student          yes        
#> 2     2 RCT              45 older adult      no         
#> 3     3 meta-analysis  3247 older adult      yes        
#> 4     4 longitudinal     89 child/adolescent no
```

This produces a clean, one-row-per-study data frame ready for
meta-analysis or research synthesis. Notice how `dplyr` verbs work
seamlessly with
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md)
output: `group_by(id)` groups the 3 draws for each study,
[`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html)
collapses them into single values using
[`first()`](https://dplyr.tidyverse.org/reference/nth.html) (since
agreement is perfect), and
[`as.numeric()`](https://rdrr.io/r/base/numeric.html) converts the
extracted character values to numbers for quantitative analysis. The
result is a standard tidy data frame that can be exported to CSV, merged
with other datasets, or used directly in statistical models—no reshaping
or manual data entry required.

## Summary

This section demonstrated how
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md)
can automate structured data extraction from research abstracts, pulling
key study characteristics like sample size, design, and significance
with perfect reliability across multiple draws. The extracted data
integrates seamlessly with tidyverse workflows, allowing researchers to
collapse draws into a clean dataset ready for meta-analysis or
systematic review using standard `dplyr` verbs.
