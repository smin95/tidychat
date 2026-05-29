#' Create an Ollama chat constructor with parameter tracking
#'
#' Creates a chat constructor function for locally running Ollama models.
#' Ollama runs models locally on your machine, requiring no API key.
#'
#' @param model Ollama model name (e.g., "llama3.2:3b", "mistral:latest", "deepseek-coder:6.7b")
#' @param base_url Ollama API URL (default: "http://localhost:11434")
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 500)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
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
                          temperature = 0.3, max_tokens = 500, seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }
  if (is.null(base_url)) {
    base_url <- Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
  }
  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

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
#' Uses ellmer's automatic credential discovery via GEMINI_API_KEY environment variable.
#' Supports text, images, PDFs, and audio files.
#'
#' @param model Gemini model name. Options include:
#'   - "gemini-2.5-flash" (fast, efficient)
#'   - "gemini-2.5-pro" (more capable, slower)
#'   - "gemini-2.0-flash-lite" (lightweight, free tier)
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
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
#' }
#'
#' @export
choose_gemini <- function(model = "gemini-2.5-flash",
                          base_url = NULL,
                          temperature = 0.3,
                          max_tokens = 2048,
                          seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_google_gemini(
        model = model,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_google_gemini(
        model = model,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }

    list(
      model = model,
      provider = "google",
      params = params,
      base_url = base_url,
      chat = function(prompt, images = NULL, audio = NULL) {
        # Build content list starting with prompt
        content_parts <- list(prompt)

        # Add images if provided
        if (!is.null(images)) {
          if (is.list(images)) {
            content_parts <- c(content_parts, images)
          } else {
            content_parts <- c(content_parts, list(images))
          }
        }

        # Add audio if provided (already processed by google_upload)
        if (!is.null(audio)) {
          if (is.list(audio)) {
            content_parts <- c(content_parts, audio)
          } else {
            content_parts <- c(content_parts, list(audio))
          }
        }

        # Call with all content parts
        do.call(inner$chat, content_parts)
      },
      chat_structured = function(prompt, type, images = NULL, audio = NULL) {
        # Build content list
        content_parts <- list(prompt)

        # Add images if provided
        if (!is.null(images)) {
          if (is.list(images)) {
            content_parts <- c(content_parts, images)
          } else {
            content_parts <- c(content_parts, list(images))
          }
        }

        # Add audio if provided
        if (!is.null(audio)) {
          if (is.list(audio)) {
            content_parts <- c(content_parts, audio)
          } else {
            content_parts <- c(content_parts, list(audio))
          }
        }

        # Call structured with content parts
        do.call(inner$chat_structured, c(content_parts, list(type = type)))
      }
    )
  }
}

#' Create an OpenAI chat constructor with parameter tracking
#'
#' Creates a chat constructor function for OpenAI models (GPT-4, GPT-3.5, etc.).
#' Requires OPENAI_API_KEY environment variable to be set.
#'
#' @param model OpenAI model name. Options include:
#'   - "gpt-4o" (latest multimodal model)
#'   - "gpt-4o-mini" (faster, cheaper)
#'   - "gpt-4-turbo" (powerful)
#'   - "gpt-3.5-turbo" (legacy, cheapest)
#' @param base_url Optional custom base URL (e.g., for Azure OpenAI)
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(OPENAI_API_KEY = "your-api-key")
#'
#' # Use GPT-4o Mini for cost-effective annotation
#' chat <- choose_openai(model = "gpt-4o-mini", temperature = 0.2)
#' }
#'
#' @export
choose_openai <- function(model = "gpt-4o-mini",
                          base_url = NULL,
                          temperature = 0.3,
                          max_tokens = 2048,
                          seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_openai(
        model = model,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_openai(
        model = model,
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
#' Requires ANTHROPIC_API_KEY environment variable to be set.
#'
#' @param model Anthropic model name. Options include:
#'   - "claude-3-5-sonnet-20241022" (latest Sonnet, best balance)
#'   - "claude-3-opus-20240229" (most capable)
#'   - "claude-3-haiku-20240307" (fastest, cheapest)
#'   - "claude-sonnet-4-20250514" (newest)
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(ANTHROPIC_API_KEY = "your-api-key")
#'
#' # Use Claude Haiku for fast, cheap annotation
#' chat <- choose_anthropic(model = "claude-3-haiku-20240307")
#' }
#'
#' @export
choose_anthropic <- function(model = "claude-sonnet-4-20250514",
                             base_url = NULL,
                             temperature = 0.3,
                             max_tokens = 2048,
                             seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)
  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_anthropic(
        model = model,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_anthropic(
        model = model,
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
#' Requires GROQ_API_KEY environment variable to be set.
#'
#' @param model Groq model name. Options include:
#'   - "mixtral-8x7b-32768" (Mixtral, good balance)
#'   - "llama3-70b-8192" (Llama 3 70B, powerful)
#'   - "llama3-8b-8192" (Llama 3 8B, fast)
#'   - "gemma2-9b-it" (Google Gemma)
#' @param base_url Optional custom base URL
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(GROQ_API_KEY = "your-groq-api-key")
#'
#' # Use Llama 3 70B for high-quality extraction
#' chat <- choose_groq(model = "llama3-70b-8192")
#' }
#'
#' @export
choose_groq <- function(model = "mixtral-8x7b-32768",
                        base_url = NULL,
                        temperature = 0.3,
                        max_tokens = 2048,
                        seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_groq(
        model = model,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_groq(
        model = model,
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
#' or OpenRouter. Requires DEEPSEEK_API_KEY or OPENROUTER_API_KEY environment variable.
#'
#' @param model Model name. Options include:
#'   **Official DeepSeek API:**
#'   - "deepseek-chat" (DeepSeek-V3)
#'   - "deepseek-reasoner" (DeepSeek-R1 with reasoning)
#'   **OpenRouter:**
#'   - "deepseek/deepseek-chat" (DeepSeek-V3)
#'   - "deepseek/deepseek-r1" (DeepSeek-R1)
#' @param base_url Base URL for the API. Defaults to:
#'   - "https://api.deepseek.com/v1" for official API
#'   - "https://openrouter.ai/api/v1" for OpenRouter (auto-detected)
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Using official DeepSeek API
#' Sys.setenv(DEEPSEEK_API_KEY = "your-deepseek-api-key")
#' chat <- choose_deepseek(model = "deepseek-chat")
#'
#' # Using OpenRouter
#' Sys.setenv(OPENROUTER_API_KEY = "your-openrouter-key")
#' chat <- choose_deepseek(model = "deepseek/deepseek-chat")
#' }
#'
#' @export
choose_deepseek <- function(model = "deepseek-chat",
                            base_url = NULL,
                            temperature = 0.3,
                            max_tokens = 2048,
                            seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  # Set default base_url based on model naming convention
  if (is.null(base_url)) {
    if (grepl("/", model, fixed = TRUE)) {
      base_url <- "https://openrouter.ai/api/v1"
    } else {
      base_url <- "https://api.deepseek.com/v1"
    }
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    # DeepSeek uses OpenAI-compatible API
    inner <- ellmer::chat_openai(
      model = model,
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
#' Requires AZURE_OPENAI_API_KEY environment variable to be set.
#'
#' @param deployment_name Your Azure OpenAI deployment name
#' @param endpoint Azure OpenAI endpoint URL
#' @param api_version Azure API version (default: "2024-02-15-preview")
#' @param temperature Sampling temperature (0-1, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(AZURE_OPENAI_API_KEY = "your-azure-key")
#'
#' # Configure Azure OpenAI
#' chat <- choose_azure_openai(
#'   deployment_name = "gpt-4-deployment",
#'   endpoint = "https://your-resource.openai.azure.com/"
#' )
#' }
#'
#' @export
choose_azure_openai <- function(deployment_name, endpoint,
                                api_version = "2024-02-15-preview",
                                temperature = 0.3,
                                max_tokens = 2048,
                                seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  function() {
    inner <- ellmer::chat_azure_openai(
      deployment_id = deployment_name,
      endpoint = endpoint,
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



#' Create an OpenRouter chat constructor with parameter tracking
#'
#' Creates a chat constructor function for models hosted on OpenRouter.
#' Requires OPENROUTER_API_KEY environment variable to be set.
#'
#' @param model OpenRouter model name. Examples:
#'   - "openai/gpt-4o" (OpenAI)
#'   - "anthropic/claude-3.5-sonnet" (Anthropic)
#'   - "google/gemini-2.0-flash-exp" (Google)
#'   - "meta-llama/llama-3.1-405b-instruct" (Meta)
#' @param app_name Optional app name for OpenRouter headers
#' @param app_url Optional app URL for OpenRouter headers
#' @param temperature Sampling temperature (0-1, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @examples
#' \dontrun{
#' Sys.setenv(OPENROUTER_API_KEY = "your-key")
#' chat <- choose_openrouter(model = "openai/gpt-4o-mini")
#' }
#'
#' @export
choose_openrouter <- function(model = "openai/gpt-4o-mini",
                              app_name = NULL, app_url = NULL,
                              temperature = 0.3,
                              max_tokens = 2048,
                              seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  # Build custom headers
  api_headers <- character()
  if (!is.null(app_name)) {
    api_headers <- c(api_headers, c("X-Title" = app_name))
  }
  if (!is.null(app_url)) {
    api_headers <- c(api_headers, c("X-Url" = app_url))
  }

  function() {
    inner <- ellmer::chat_openrouter(
      model = model,
      api_headers = api_headers,
      params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
      ...
    )

    list(
      model = model,
      provider = "openrouter",
      params = params,
      app_name = app_name,
      app_url = app_url,
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
            inner$chat_structured(prompt, type = type, images = images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}

#' Create a Hugging Face chat constructor with parameter tracking
#'
#' Creates a chat constructor function for models hosted on Hugging Face
#' Serverless Inference API. Hugging Face offers thousands of open-source
#' models with a generous free tier.
#'
#' Requires HUGGINGFACE_API_KEY environment variable to be set.
#'
#' @param model Hugging Face model name. Examples:
#'   - "meta-llama/Llama-3.1-8B-Instruct" (default)
#'   - "mistralai/Mistral-7B-Instruct-v0.3"
#'   - "Qwen/Qwen2.5-7B-Instruct"
#'   - "google/gemma-2-2b-it"
#'   - "microsoft/Phi-3-mini-4k-instruct"
#'   - "meta-llama/Llama-3.2-3B-Instruct"
#' @param base_url Optional custom base URL (default: uses ellmer's default)
#' @param temperature Sampling temperature (0-1, higher = more random, default: 0.3)
#' @param max_tokens Maximum tokens to generate (default: 2048)
#' @param seed Optional random seed for reproducible outputs (if supported by provider)
#' @param ... Additional parameters passed to ellmer
#'
#' @return A chat constructor function that returns a list with chat methods
#'
#' @note Some models do not support system prompts or other features.
#'       Check model documentation for compatibility.
#' @note Hugging Face credentials require a Bearer token header format.
#'
#' @examples
#' \dontrun{
#' # Set API key in environment
#' Sys.setenv(HUGGINGFACE_API_KEY = "your-huggingface-token")
#'
#' # Use Llama 3.1 8B
#' chat <- choose_huggingface(model = "meta-llama/Llama-3.1-8B-Instruct")
#'
#' # Use smaller model for faster inference
#' chat <- choose_huggingface(model = "google/gemma-2-2b-it", temperature = 0.1)
#'
#' # Annotate with Hugging Face
#' results <- data %>%
#'   llm_annotate(
#'     col = sentiment,
#'     input = text,
#'     chat = chat,
#'     prompt_task = "Classify sentiment",
#'     categories = c("positive", "negative", "neutral")
#'   )
#' }
#'
#' @export
choose_huggingface <- function(model = "meta-llama/Llama-3.1-8B-Instruct",
                               base_url = NULL,
                               temperature = 0.3,
                               max_tokens = 2048,
                               seed = NULL, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  api_key <- Sys.getenv("HUGGINGFACE_API_KEY")
  if (api_key == "") {
    stop("Hugging Face API key not found. Set HUGGINGFACE_API_KEY environment variable.\n",
         "Get your token at: https://huggingface.co/settings/tokens")
  }

  params <- list(temperature = temperature, max_tokens = max_tokens, ...)

  if (!is.null(seed)) {
    params$seed <- seed
  }

  # Hugging Face expects credentials as a FUNCTION that returns headers
  # Note: Different from OpenAI/Anthropic which expect just the API key string
  creds <- function() list(authorization = paste("Bearer", api_key))

  function() {
    if (!is.null(base_url)) {
      inner <- ellmer::chat_huggingface(
        model = model,
        credentials = creds,
        base_url = base_url,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    } else {
      inner <- ellmer::chat_huggingface(
        model = model,
        credentials = creds,
        params = ellmer::params(temperature = temperature, max_tokens = max_tokens, ...),
        ...
      )
    }

    list(
      model = model,
      provider = "huggingface",
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
        # Note: Not all Hugging Face models support structured output
        if (!is.null(images)) {
          if (is.list(images)) {
            do.call(inner$chat_structured, c(list(prompt, type = type), images))
          } else {
            inner$chat_structured(prompt, type = type, images = images)
          }
        } else {
          inner$chat_structured(prompt, type = type)
        }
      }
    )
  }
}
