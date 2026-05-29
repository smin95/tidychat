# 4. Choosing LLM Providers and Configuring Models

This section shows how to extract structured data from research
abstracts using
[`llm_extract()`](https://smin95.github.io/tidychat/reference/llm_extract.md).
This is particularly useful for systematic reviews and meta-analyses
where researchers need to quickly code hundreds of abstracts.

## Introduction

Before you can annotate text or extract structured data, you need to
create a chat constructor that tells `tidychat` which LLM provider and
model to use, along with key parameters like `temperature`, `top_p`, and
`max_tokens`. This section explains the available providers, how to
configure them, and how to choose the right settings for your use.

## API Key Security: A Critical Node

Never hard-code API keys in your scripts. Always use environment
variables to store sensitive credentials.

``` r

# Set in your R session (temporary)
Sys.setenv(GEMINI_API_KEY = "your-api-key-here")
```

## Why Multiple Providers?

Different research tasks have different requirements:

``` r

knitr::kable(
  data.frame(
    Provider = c("Ollama", "Groq", "Gemini", "OpenAI", "Anthropic", "DeepSeek", "Azure OpenAI"),
    Best_For = c("Local, private, free", "Fast inference, free tier", "Multimodal, free tier",
                 "State-of-the-art quality", "Safety, long context", "Cost-effective, reasoning",
                 "Enterprise, compliance"),
    Cost = c("Free", "Free / Paid", "Free / Paid", "Paid", "Paid", "Paid (free credits)", "Paid"),
    API_Key_Required = c("No", "Yes", "Yes", "Yes", "Yes", "Yes", "Yes")
  ),
  caption = "Overview of LLM providers supported by tidychat",
  align = c("l", "l", "l", "c")
)
```

| Provider     | Best_For                  | Cost                | API_Key_Required |
|:-------------|:--------------------------|:--------------------|:----------------:|
| Ollama       | Local, private, free      | Free                |        No        |
| Groq         | Fast inference, free tier | Free / Paid         |       Yes        |
| Gemini       | Multimodal, free tier     | Free / Paid         |       Yes        |
| OpenAI       | State-of-the-art quality  | Paid                |       Yes        |
| Anthropic    | Safety, long context      | Paid                |       Yes        |
| DeepSeek     | Cost-effective, reasoning | Paid (free credits) |       Yes        |
| Azure OpenAI | Enterprise, compliance    | Paid                |       Yes        |

Overview of LLM providers supported by tidychat {.table}

## Local Models with Ollama (No API Key Required)

Ollama runs LLMs locally on your machine, making it ideal for
prototyping, private data, and situations where you cannot send data to
cloud APIs.

### Installation

First, install Ollama from ollama.ai, then pull a model in bash:

``` bash
ollama pull llama3
```

### Basic Usage

``` r

library(tidychat)

# Create a chat constructor with default settings
chat <- choose_ollama(model = "llama3")

# With custom parameters
chat <- choose_ollama(
  model = "llama3.2:3b",
  temperature = 0.3,
  max_tokens = 500
)
```

## OpenRouter: Access 200+ Community Models Through One API

OpenRouter provides a unified API to access hundreds of open-source and
proprietary models from a single endpoint. This is perfect for:

- Comparing multiple models without managing multiple API keys
- Accessing fine-tuned community models not available elsewhere
- Using free tier models for development and testing
- Falling back to alternative providers if one fails

### Setting Up OpenRouter

1.  Create an account at openrouter.ai

2.  Get your API key from the dashboard

3.  Set the environment variable:

``` r

# In your R session
Sys.setenv(OPENROUTER_API_KEY = "sk-or-v1-xxxxx")
```

### Using OpenRouter with tidychat

``` r

library(tidychat)

# Use a free tier model (great for testing)
chat <- choose_openrouter(
  model = "meta-llama/llama-3.2-3b-instruct:free",
  temperature = 0.3
)
```

## Key Parameters for All Providers

``` r

knitr::kable(
  data.frame(
    Parameter = c("temperature", "top_p", "max_tokens", "seed"),
    Description = c(
      "Controls randomness. Lower = more deterministic, higher = more creative",
      "Nucleus sampling. Considers only the most probable tokens whose cumulative probability exceeds p",
      "Maximum length of generated response",
      "Random seed for reproducibility (Ollama only)"
    ),
    Typical_Range = c("0-1", "0-1", "50-4096", "integer"),
    When_to_Use = c(
      "Use 0 for reproducible coding tasks; 0.5-1 for exploring variability",
      "Lower (0.5) = more focused; higher (0.95) = more diverse",
      "Set higher for long-form extraction, lower for classification",
      "Set to a fixed value for deterministic results"
    )
  ),
  caption = "Key parameters for LLM configuration in tidychat",
  align = c("l", "l", "c", "l")
)
```

| Parameter | Description | Typical_Range | When_to_Use |
|:---|:---|:--:|:---|
| temperature | Controls randomness. Lower = more deterministic, higher = more creative | 0-1 | Use 0 for reproducible coding tasks; 0.5-1 for exploring variability |
| top_p | Nucleus sampling. Considers only the most probable tokens whose cumulative probability exceeds p | 0-1 | Lower (0.5) = more focused; higher (0.95) = more diverse |
| max_tokens | Maximum length of generated response | 50-4096 | Set higher for long-form extraction, lower for classification |
| seed | Random seed for reproducibility (Ollama only) | integer | Set to a fixed value for deterministic results |

Key parameters for LLM configuration in tidychat {.table}

### Understanding Temperature

Temperature is the single most important parameter for research
applications:

``` r

# Deterministic - perfect for reproducible coding but biased
chat_deterministic <- choose_ollama(model = "llama3", temperature = 0)

# Balanced - default for most tasks
chat_balanced <- choose_ollama(model = "llama3", temperature = 0.3)

# Creative - useful for exploration or generating variability
chat_creative <- choose_ollama(model = "llama3", temperature = 0.8)
```

Practical guidance: - temperature = 0: Every draw produces the same
result. Use for deterministic coding tasks. - temperature = 0.3-0.5:
Moderate variability. Default for most research. - temperature =
0.7-1.0: High variability. Use when you want to measure uncertainty
across draws.

## Cloud Providers (API Keys Required)

### Google Gemini

Gemini offers a generous free tier and strong multimodal capabilities,
including native PDF support.

``` r

Sys.setenv(GEMINI_API_KEY = "YOUR API KEY")

# Use Flash model for speed (free tier)
chat <- choose_gemini(model = "gemini-2.5-flash")

# Use Pro for complex tasks
chat <- choose_gemini(model = "gemini-2.5-pro", temperature = 0.1)
```

Get an API key: Visit Google AI Studio → Get API key → Free tier
available.

### OpenAI

OpenAI’s GPT models are state-of-the-art but require payment.

``` r

Sys.setenv(OPENAI_API_KEY = "YOUR API KEY")
# Use GPT-4o Mini for cost-effective annotation
chat <- choose_openai(model = "gpt-4o-mini", temperature = 0.3)

# Use GPT-4o for complex extraction
chat <- choose_openai(model = "gpt-4o", max_tokens = 4096)
```

Get an API key: Visit OpenAI Platform → Create API key → Requires
billing.

### Anthropic Claude

Claude models excel at safety and long-context understanding.

``` r

Sys.setenv(ANTHROPIC_API_KEY = "YOUR API KEY")
 
# Use Haiku for fast, cheap annotation
chat <- choose_anthropic(model = "claude-3-haiku-20240307")

# Use Sonnet for balanced performance
chat <- choose_anthropic(model = "claude-3-5-sonnet-20241022")
```

Get an API key: Visit Anthropic Console → Create API key → Requires
billing.

### Groq

Groq offers a generous free tier.

``` r

Sys.setenv(GROQ_API_KEY = "YOUR API KEY")

chat <- choose_groq(model = "llama3-70b-8192", temperature = 0)

# Use Mixtral for speed/cost balance
chat <- choose_groq(model = "mixtral-8x7b-32768")
```

Get an API key: Visit Groq Console → Create API key → Free tier
available.

### DeepSeek

DeepSeek offers competitive pricing and strong performance.

``` r

Sys.setenv(DEEPSEEK_API_KEY = "YOUR API KEY")

chat <- choose_deepseek(model = "deepseek-chat")

# Or via OpenRouter (alternative access)
Sys.setenv(OPENROUTER_API_KEY = "your-openrouter-key")
chat <- choose_deepseek(
  model = "deepseek/deepseek-chat",
  base_url = "https://openrouter.ai/api/v1",
  api_key =  "your-api-key"
)
```
