#' Annotate text or images using LLMs with multiple draws
#'
#' Annotates each row in a data frame using an LLM, supporting multiple
#' independent draws per item for uncertainty quantification.
#'
#' @param data Data frame with content to annotate
#' @param col Name of new annotation column (unquoted)
#' @param input Column containing content to analyze (unquoted, optional)
#' @param input_type Type of input: "text", "image", "pdf", "markdown", "html"
#'        (default: "text")
#' @param id Optional unique ID column. If NULL, creates id from row_number()
#' @param prompt_task Fixed prompt for all rows (ignored if prompt_col provided)
#' @param prompt_col Column name containing per-row prompts (unquoted, optional)
#' @param extract_type Default extraction type: "category", "integer", "number",
#'        "text", "boolean", or "array" (default: "text")
#' @param categories Default categories (for category extraction)
#' @param extract_type_col Column with per-row extraction type (unquoted, optional)
#' @param categories_col Column with per-row categories (unquoted, optional, list column)
#' @param batch_size Number of items per API call (default: 10)
#' @param n_draws Number of independent draws per item (default: 1)
#' @param delay_seconds Seconds between batches (default: 2)
#' @param chat Chat constructor from choose_ollama(), choose_gemini(), etc.
#' @param model_params Optional list of additional model parameters
#' @param track_params Whether to store individual parameter columns (default: TRUE)
#' @param use_structured Use ellmer's structured extraction? (default: FALSE)
#' @param show_progress Show progress messages? (default: TRUE)
#'
#' @return A data frame with columns: id, draw_id, annotation column,
#'         plus metadata (model_name, provider, prompt, params_hash, and individual
#'         parameter columns like temperature, max_tokens, top_p, etc.)
#'
#' @examples
#' \dontrun{
#' # Basic sentiment annotation (category)
#' library(dplyr)
#'
#' reviews <- data.frame(
#'   review_id = 1:3,
#'   text = c("Great product!", "Terrible service", "It was okay")
#' )
#'
#' chat <- choose_ollama(model = "llama3.2:3b")
#'
#' results <- reviews |>
#'   llm_annotate(
#'     col = sentiment,
#'     input = text,
#'     id = review_id,
#'     prompt_task = "Classify sentiment as positive, negative, or neutral",
#'     extract_type = "category",
#'     categories = c("positive", "negative", "neutral"),
#'     chat = chat,
#'     n_draws = 3
#'   )
#'
#' # Integer extraction (ratings)
#' results <- reviews |>
#'   llm_annotate(
#'     col = rating,
#'     input = text,
#'     prompt_task = "Rate this product from 1 to 5 stars",
#'     extract_type = "integer",
#'     chat = chat
#'   )
#'
#' # Boolean extraction
#' results <- reviews |>
#'   llm_annotate(
#'     col = would_recommend,
#'     input = text,
#'     prompt_task = "Would the user recommend this product? Answer TRUE or FALSE",
#'     extract_type = "boolean",
#'     chat = chat
#'   )
#' }
#'
#' @export
llm_annotate <- function(data, col, input = NULL, input_type = "text",
                         id = NULL,
                         prompt_task = NULL, prompt_col = NULL,
                         extract_type = c("category", "integer", "number", "text", "boolean", "array"),
                         categories = NULL,
                         extract_type_col = NULL,
                         categories_col = NULL,
                         batch_size = 10,
                         n_draws = 1,
                         delay_seconds = 2,
                         chat = NULL,
                         model_params = list(),
                         track_params = TRUE,
                         use_structured = FALSE,
                         show_progress = TRUE) {
  extract_type_default <- match.arg(extract_type)

  if(is.null(chat)) {
    stop("chat is required. Use choose_ollama(), choose_gemini(), etc.")
  }

  col_name <- rlang::as_name(rlang::enquo(col))

  # Handle optional input
  input_col_name <- NULL
  if(!is.null(rlang::enquo(input))) {
    if(!rlang::quo_is_null(rlang::enquo(input))) {
      input_col_name <- rlang::as_name(rlang::enquo(input))
      if(!input_col_name %in% colnames(data)) {
        stop(sprintf("Input column '%s' not found in data", input_col_name))
      }
    }
  }

  prompt_col_name <- if (!missing(prompt_col)) {
    rlang::as_name(rlang::enquo(prompt_col))
  } else {
    NULL
  }

  extract_type_col_name <- if (!missing(extract_type_col)) {
    rlang::as_name(rlang::enquo(extract_type_col))
  } else {
    NULL
  }

  categories_col_name <- if (!missing(categories_col)) {
    rlang::as_name(rlang::enquo(categories_col))
  } else {
    NULL
  }

  if(is.null(prompt_task) && is.null(prompt_col_name)) {
    stop("Either prompt_task or prompt_col must be provided")
  }

  id_quo <- rlang::enquo(id)

  chat_instance <- chat()
  model_name <- chat_instance$model %||% "unknown"
  provider_name <- chat_instance$provider %||% "unknown"
  chat_params <- chat_instance$params %||% list()

  all_params <- utils::modifyList(chat_params, model_params)

  # Create id column
  if(rlang::quo_is_null(id_quo)) {
    data <- data |> dplyr::mutate(id = dplyr::row_number())
  } else {
    id_col_name <- rlang::as_name(id_quo)
    if(!id_col_name %in% colnames(data)) {
      stop(sprintf("ID column '%s' not found in data", id_col_name))
    }
    data <- data |> dplyr::rename(id = dplyr::all_of(id_col_name))
  }

  data <- data |> dplyr::mutate(id = as.integer(id))

  has_native_files <- provider_name %in% c("google", "openai", "anthropic")

  if(!is.null(input_col_name)) {
    data <- data |>
      dplyr::mutate(.__temp_content = purrr::map(!!rlang::sym(input_col_name), function(x) {
        if(is.na(x) || is.null(x)) return(NULL)

        if(input_type == "text") {
          return(as.character(x))
        } else if(input_type == "image") {
          if(is.character(x) && file.exists(x)) {
            return(ellmer::content_image_file(x))
          }
          return(NULL)
        } else if(input_type == "pdf") {
          if(is.character(x) && nchar(trimws(x)) > 0) {
            if(has_native_files) {
              if(grepl("^https?://", x, ignore.case = TRUE)) {
                tmp <- tempfile(fileext = ".pdf")
                tryCatch({
                  download.file(x, tmp, mode = "wb", quiet = TRUE)
                  return(ellmer::content_pdf_file(tmp))
                }, error = function(e) {
                  if(show_progress) cli::cli_alert_warning("Failed to download PDF: {e$message}")
                  return(NULL)
                })
              } else if(file.exists(x)) {
                return(ellmer::content_pdf_file(x))
              }
            } else {
              if(grepl("^https?://", x, ignore.case = TRUE)) {
                tmp <- tempfile(fileext = ".pdf")
                tryCatch({
                  download.file(x, tmp, mode = "wb", quiet = TRUE)
                  text <- extract_pdf_text(tmp)
                  unlink(tmp)
                  return(text)
                }, error = function(e) {
                  if(show_progress) cli::cli_alert_warning("Failed to download PDF: {e$message}")
                  return(NULL)
                })
              } else if(file.exists(x)) {
                return(extract_pdf_text(x))
              }
            }
          }
          return(NULL)
        } else if(input_type == "markdown") {
          if(is.character(x) && file.exists(x)) {
            return(ellmer::contents_markdown(x))
          }
          return(NULL)
        } else if(input_type == "html") {
          if(is.character(x) && file.exists(x)) {
            return(ellmer::contents_html(x))
          }
          return(NULL)
        }
        return(NULL)
      }))

    content_col_name <- ".__temp_content"
  } else {
    content_col_name <- NULL
  }

  use_per_row_prompts <- !is.null(prompt_col_name)

  if(use_per_row_prompts) {
    data <- data |>
      dplyr::mutate(.row_prompt = as.character(data[[prompt_col_name]]))
    full_prompt_text <- NULL
  } else {
    full_prompt_text <- prompt_task
  }

  use_per_row_extract <- !is.null(extract_type_col_name)
  if(use_per_row_extract) {
    data <- data |>
      dplyr::mutate(
        .row_extract_type = dplyr::case_when(
          is.na(data[[extract_type_col_name]]) ~ extract_type_default,
          TRUE ~ as.character(data[[extract_type_col_name]])
        )
      )
  } else {
    data <- data |>
      dplyr::mutate(.row_extract_type = extract_type_default)
  }

  use_per_row_categories <- !is.null(categories_col_name)
  if(use_per_row_categories) {
    data <- data |>
      dplyr::mutate(
        .row_categories = dplyr::case_when(
          is.na(data[[categories_col_name]]) ~ list(categories),
          TRUE ~ data[[categories_col_name]]
        )
      )
  } else {
    data <- data |>
      dplyr::mutate(.row_categories = list(categories))
  }

  params_hash <- if(track_params) {
    if(length(all_params) > 0) {
      stable_hash(jsonlite::toJSON(all_params))
    } else {
      stable_hash("default_params")
    }
  } else {
    NA_character_
  }

  if(show_progress) {
    if(use_per_row_prompts) {
      cli::cli_h1("tidyprompt: annotating {nrow(data)} items x {n_draws} draws (per-row prompts)")
      if(!is.null(prompt_col_name)) cli::cli_alert_info("Using prompts from column: {prompt_col_name}")
    } else {
      cli::cli_h1("tidyprompt: annotating {nrow(data)} items x {n_draws} draws")
    }
    cli::cli_alert_info("Model: {model_name} ({provider_name})")
    if(!is.null(input_col_name)) {
      cli::cli_alert_info("Input column: {input_col_name} (type: {input_type})")
    } else {
      cli::cli_alert_info("No input column provided (using prompts only)")
    }
    if(use_per_row_extract) cli::cli_alert_info("Extract types from column: {extract_type_col_name} (fallback: {extract_type_default})")
    if(use_per_row_categories && !is.null(categories_col_name)) cli::cli_alert_info("Categories from column: {categories_col_name}")
    if(length(all_params) > 0) {
      param_str <- paste(names(all_params), unlist(all_params), sep = "=", collapse = ", ")
      cli::cli_alert_info("Parameters: {param_str}")
    }
  }

  type_spec <- NULL
  if(use_structured && requireNamespace("ellmer", quietly = TRUE)) {
    # Create appropriate type specification based on extract_type
    if(extract_type_default == "category") {
      type_spec <- create_category_type(categories, "The extracted category")
    } else if(extract_type_default == "integer") {
      type_spec <- create_integer_type("The extracted integer value")
    } else if(extract_type_default == "number") {
      type_spec <- create_numeric_type("The extracted numeric value")
    } else if(extract_type_default == "text") {
      type_spec <- create_text_type("The extracted text")
    } else if(extract_type_default == "boolean") {
      type_spec <- create_boolean_type("The extracted boolean value")
    } else if(extract_type_default == "array") {
      type_spec <- create_array_type("The extracted array of values")
    } else {
      type_spec <- create_text_type("The extracted text")
    }
  }

  all_draws <- vector("list", n_draws)

  for(draw in seq_len(n_draws)) {
    if(show_progress) cli::cli_h2("Draw {draw}/{n_draws}")

    if(draw > 1 && show_progress) {
      cli::cli_alert_info("Waiting 5 seconds before next draw...")
      Sys.sleep(5)
    }

    if(use_per_row_prompts) {
      id_value_map <- process_single_draw_with_prompts(
        data = data,
        text_col = NULL,
        content_col = content_col_name,
        prompt_col = ".row_prompt",
        extract_type_col = ".row_extract_type",
        categories_col = ".row_categories",
        batch_size = batch_size,
        chat_constructor = chat,
        delay_seconds = delay_seconds,
        model_params = all_params,
        use_structured = use_structured,
        show_progress = show_progress
      )
    } else {
      id_value_map <- process_single_draw(
        data = data,
        text_col = NULL,
        content_col = content_col_name,
        prompt_task = prompt_task,
        extract_type = extract_type_default,
        categories = categories,
        batch_size = batch_size,
        chat_constructor = chat,
        delay_seconds = delay_seconds,
        model_params = all_params,
        use_structured = use_structured,
        type_spec = type_spec,
        show_progress = show_progress
      )
    }

    draw_df <- data |>
      dplyr::left_join(id_value_map, by = "id") |>
      dplyr::mutate(
        draw_id = as.integer(draw),
        !!col_name := value,
        model_name = model_name,
        provider = provider_name,
        prompt = if(use_per_row_prompts) .row_prompt else full_prompt_text,
        params_hash = params_hash,
        query_time = Sys.time()
      ) |>
      dplyr::select(-value)

    draw_df <- draw_df |>
      dplyr::select(-dplyr::any_of(c(".row_prompt", ".row_extract_type", ".row_categories", ".__temp_content")))

    all_draws[[draw]] <- draw_df
  }

  result <- dplyr::bind_rows(all_draws)

  # Add parameter columns if tracking is enabled
  if(track_params && length(all_params) > 0) {
    for(param_name in names(all_params)) {
      param_value <- all_params[[param_name]]
      if(is.numeric(param_value)) {
        result <- result |> dplyr::mutate(!!param_name := param_value)
      } else if(is.logical(param_value)) {
        result <- result |> dplyr::mutate(!!param_name := param_value)
      } else {
        result <- result |> dplyr::mutate(!!param_name := as.character(param_value))
      }
    }
  }

  return(result)
}
