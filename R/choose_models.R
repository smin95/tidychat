#' Create an Ollama chat constructor with parameter tracking
#'
#' Creates a chat constructor function for locally running Ollama models.
#' Ollama runs models locally on your machine, requiring no API key.
#'
#' @param model Ollama model name (e.g., "llama3.2:3b", "mistral:latest", "deepseek-coder:6.7b")
#' @param base_url Ollama API URL (default: "http://localhost:11434")
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 500)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Basic usage with local Ollama
#' chat <- choose_ollama(model = "llama3")
#'
#' # Use with annotation
#' results <- data %>%
#'   llm_annotate(
#'     .col = sentiment,
#'     .input = text,
#'     .chat = chat,
#'     .prompt_task = "Classify sentiment",
#'     .categories = c("positive", "negative")
#'   )
#'
#' # Check available models
#' list_ollama_models()
#'
#' # Check if Ollama is running
#' ollama_running()
#' }
#'
#' @export
choose_ollama <- function(model = "mistral:latest", base_url = NULL,
                          temperature = 0.3, max_tokens = 500, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  if (is.null(base_url)) {
    base_url <- Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
  }
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  function() {
    inner <- ellmer::chat_ollama(
      model = model,
      base_url = base_url,
      params = ellmer::params(temperature = temperature, num_predict = max_tokens, ...)
    )
    list(
      model = model,
      provider = "ollama",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}

#' Create a Google Gemini chat constructor with parameter tracking
#'
#' Creates a chat constructor function for Google's Gemini models.
#' Requires a Gemini API key from Google AI Studio.
#'
#' @param model Gemini model name. Options include:
#'   - "gemini-2.5-flash" (fast, efficient)
#'   - "gemini-2.5-pro" (more capable, slower)
#'   - "gemini-2.0-flash-lite" (lightweight, free tier)
#' @param api_key Gemini API key. If NULL, reads from GEMINI_API_KEY env var.
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(GEMINI_API_KEY = "your-api-key")
#'
#' # Use Gemini Flash for speed
#' chat <- choose_gemini(model = "gemini-2.5-flash")
#'
#' # Or use Pro for complex tasks
#' chat <- choose_gemini(model = "gemini-2.5-pro", temperature = 0.1)
#'
#' # Annotate with Gemini
#' results <- data %>%
#'   llm_extract(
#'     .fields = extraction_fields,
#'     .input = text,
#'     .chat = chat,
#'     .n_draws = 3
#'   )
#' }
#'
#' @export
choose_gemini <- function(model = "gemini-2.5-flash", api_key = NULL,
                          base_url = NULL, temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  api_key <- api_key %||% Sys.getenv("GEMINI_API_KEY")
  if (api_key == "") stop("Gemini API key not found. Set GEMINI_API_KEY environment variable.")
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_google_gemini(
        model = model,
        api_key = api_key,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_google_gemini(
        model = model,
        api_key = api_key,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }
    list(
      model = model,
      provider = "google",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}

#' Create an OpenAI chat constructor with parameter tracking
#'
#' Creates a chat constructor function for OpenAI models (GPT-4, GPT-3.5, etc.).
#' Requires an OpenAI API key.
#'
#' @param model OpenAI model name. Options include:
#'   - "gpt-4o" (latest multimodal model)
#'   - "gpt-4o-mini" (faster, cheaper)
#'   - "gpt-4-turbo" (powerful)
#'   - "gpt-3.5-turbo" (legacy, cheapest)
#' @param api_key OpenAI API key. If NULL, reads from OPENAI_API_KEY env var.
#' @param base_url Optional custom base URL (e.g., for Azure OpenAI)
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key
#' Sys.setenv(OPENAI_API_KEY = "your-api-key")
#'
#' # Use GPT-4o Mini for cost-effective annotation
#' chat <- choose_openai(model = "gpt-4o-mini", temperature = 0.2)
#'
#' # Use GPT-4o for complex extraction
#' chat <- choose_openai(model = "gpt-4o", max_tokens = 4096)
#'
#' # Annotate with OpenAI
#' results <- data %>%
#'   llm_annotate(
#'     .col = sentiment,
#'     .input = text,
#'     .chat = chat,
#'     .n_draws = 5
#'   )
#' }
#'
#' @export
choose_openai <- function(model = "gpt-4o-mini", api_key = NULL,
                          base_url = NULL, temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  api_key <- api_key %||% Sys.getenv("OPENAI_API_KEY")
  if (api_key == "") stop("OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_openai(
        model = model,
        api_key = api_key,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_openai(
        model = model,
        api_key = api_key,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }
    list(
      model = model,
      provider = "openai",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}

#' Create an Anthropic Claude chat constructor with parameter tracking
#'
#' Creates a chat constructor function for Anthropic's Claude models.
#' Requires an Anthropic API key.
#'
#' @param model Anthropic model name. Options include:
#'   - "claude-3-5-sonnet-20241022" (latest Sonnet, best balance)
#'   - "claude-3-opus-20240229" (most capable)
#'   - "claude-3-haiku-20240307" (fastest, cheapest)
#'   - "claude-sonnet-4-20250514" (newest)
#' @param api_key Anthropic API key. If NULL, reads from ANTHROPIC_API_KEY env var.
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key
#' Sys.setenv(ANTHROPIC_API_KEY = "your-api-key")
#'
#' # Use Claude Haiku for fast, cheap annotation
#' chat <- choose_anthropic(model = "claude-3-haiku-20240307")
#'
#' # Use Claude Sonnet for balanced performance
#' chat <- choose_anthropic(model = "claude-3-5-sonnet-20241022")
#'
#' # Extract structured data with Claude
#' results <- data %>%
#'   llm_extract(
#'     .fields = fields,
#'     .input = text,
#'     .chat = chat,
#'     .n_draws = 3
#'   )
#' }
#'
#' @export
choose_anthropic <- function(model = "claude-sonnet-4-20250514", api_key = NULL,
                             base_url = NULL, temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  api_key <- api_key %||% Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") stop("Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable.")
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_anthropic(
        model = model,
        api_key = api_key,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_anthropic(
        model = model,
        api_key = api_key,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }
    list(
      model = model,
      provider = "anthropic",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}


#' Create a Groq chat constructor with parameter tracking
#'
#' Creates a chat constructor function for Groq's ultra-fast inference.
#' Groq offers high-speed LLM inference with generous free tier.
#' Requires a Groq API key.
#'
#' @param model Groq model name. Options include:
#'   - "mixtral-8x7b-32768" (Mixtral, good balance)
#'   - "llama3-70b-8192" (Llama 3 70B, powerful)
#'   - "llama3-8b-8192" (Llama 3 8B, fast)
#'   - "gemma2-9b-it" (Google Gemma)
#' @param api_key Groq API key. If NULL, reads from GROQ_API_KEY env var.
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key
#' Sys.setenv(GROQ_API_KEY = "your-groq-api-key")
#'
#' # Use Llama 3 70B for high-quality extraction
#' chat <- choose_groq(model = "llama3-70b-8192")
#'
#' # Use Mixtral for speed/cost balance
#' chat <- choose_groq(model = "mixtral-8x7b-32768", temperature = 0)
#'
#' # Batch annotate with Groq's fast inference
#' results <- data %>%
#'   llm_annotate(
#'     .col = sentiment,
#'     .input = text,
#'     .chat = chat,
#'     .n_draws = 10,
#'     .batch_size = 50
#'   )
#' }
#'
#' @export
choose_groq <- function(model = "mixtral-8x7b-32768", api_key = NULL,
                        base_url = NULL, temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  api_key <- api_key %||% Sys.getenv("GROQ_API_KEY")
  if (api_key == "") stop("Groq API key not found. Set GROQ_API_KEY environment variable.")
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_groq(
        model = model,
        api_key = api_key,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_groq(
        model = model,
        api_key = api_key,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }
    list(
      model = model,
      provider = "groq",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}

#' Create a DeepSeek chat constructor with parameter tracking
#'
#' Creates a chat constructor function for DeepSeek models via official API
#' or OpenRouter. DeepSeek offers competitive pricing with strong performance.
#'
#' @param model Model name. Options include:
#'   **Official DeepSeek API:**
#'   - "deepseek-chat" (DeepSeek-V3)
#'   - "deepseek-reasoner" (DeepSeek-R1 with reasoning)
#'   **OpenRouter:**
#'   - "deepseek/deepseek-chat" (DeepSeek-V3)
#'   - "deepseek/deepseek-r1" (DeepSeek-R1)
#' @param api_key API key for DeepSeek or OpenRouter. If NULL, reads from
#'        DEEPSEEK_API_KEY or OPENROUTER_API_KEY env var.
#' @param base_url Base URL for the API. Defaults to:
#'   - "https://api.deepseek.com/v1" for official API
#'   - "https://openrouter.ai/api/v1" for OpenRouter (auto-detected)
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Using official DeepSeek API (has free credits)
#' Sys.setenv(DEEPSEEK_API_KEY = "your-deepseek-api-key")
#' chat <- choose_deepseek(model = "deepseek-chat")
#'
#' # Using OpenRouter (alternative access)
#' Sys.setenv(OPENROUTER_API_KEY = "your-openrouter-key")
#' chat <- choose_deepseek(
#'   model = "deepseek/deepseek-chat",
#'   base_url = "https://openrouter.ai/api/v1"
#' )
#'
#' # Use reasoning model for complex tasks
#' chat <- choose_deepseek(model = "deepseek-reasoner", temperature = 0.1)
#'
#' # Extract with DeepSeek
#' results <- data %>%
#'   llm_extract(
#'     .fields = extraction_fields,
#'     .input = text,
#'     .chat = chat,
#'     .n_draws = 3
#'   )
#' }
#'
#' @export
choose_deepseek <- function(model = "deepseek-chat", api_key = NULL,
                            base_url = NULL, temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  # Set default base_url based on model naming convention
  if (is.null(base_url)) {
    # If using OpenRouter model naming (contains "/"), use OpenRouter base URL
    if (grepl("/", model, fixed = TRUE)) {
      base_url <- "https://openrouter.ai/api/v1"
    } else {
      base_url <- "https://api.deepseek.com/v1"
    }
  }

  # Get API key from environment variable if not provided
  api_key <- api_key %||% Sys.getenv("DEEPSEEK_API_KEY") %||% Sys.getenv("OPENROUTER_API_KEY")
  if (api_key == "") {
    stop("DeepSeek API key not found. Set DEEPSEEK_API_KEY or OPENROUTER_API_KEY environment variable.")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  function() {
    # DeepSeek uses OpenAI-compatible API, so we use chat_openai internally
    inner <- ellmer::chat_openai(
      model = model,
      api_key = api_key,
      base_url = base_url,
      params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
      ...
    )

    list(
      model = model,
      provider = "deepseek",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat, c(list(prompt), images))
          } else {
            inner$chat(prompt, images)
          }
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}


#' Create an Azure OpenAI chat constructor with parameter tracking
#'
#' Creates a chat constructor function for Azure OpenAI deployments.
#' Requires Azure OpenAI endpoint and API key.
#'
#' @param deployment_name Your Azure OpenAI deployment name
#' @param endpoint Azure OpenAI endpoint URL
#' @param api_key Azure API key. If NULL, reads from AZURE_OPENAI_API_KEY env var.
#' @param api_version Azure API version (default: "2024-02-15-preview")
#' @param temperature Sampling temperature (0-1, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Configure Azure OpenAI
#' chat <- choose_azure_openai(
#'   deployment_name = "gpt-4-deployment",
#'   endpoint = "https://your-resource.openai.azure.com/",
#'   api_key = "your-azure-key"
#' )
#'
#' # Annotate with Azure OpenAI
#' results <- data %>%
#'   llm_annotate(
#'     .col = sentiment,
#'     .input = text,
#'     .chat = chat,
#'     .prompt_task = "Classify sentiment",
#'     .categories = c("positive", "negative")
#'   )
#' }
#'
#' @export
choose_azure_openai <- function(deployment_name, endpoint, api_key = NULL,
                                api_version = "2024-02-15-preview",
                                temperature = 0.3, max_tokens = 2048, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  api_key <- api_key %||% Sys.getenv("AZURE_OPENAI_API_KEY")
  if (api_key == "") {
    stop("Azure OpenAI API key not found. Set AZURE_OPENAI_API_KEY environment variable.")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  function() {
    inner <- ellmer::chat_azure_openai(
      deployment_id = deployment_name,
      endpoint = endpoint,
      api_key = api_key,
      api_version = api_version,
      params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
      ...
    )

    list(
      model = deployment_name,
      provider = "azure_openai",
      params = params,
      base_url = endpoint,
      chat = function(prompt, images = NULL) {
        if (!is.null(images)) {
          inner$chat(prompt, images)
        } else {
          inner$chat(prompt)
        }
      },
      chat_structured = function(prompt, type, images = NULL) {
        if (!is.null(images)) {
          inner$chat_structured(prompt, type = type, images = images)
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}
