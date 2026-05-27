#' Extract multiple structured fields from text or images
#'
#' Extracts multiple structured fields from each row using an LLM with
#' type-safe field specifications. Supports multiple draws per item.
#'
#' @param data Data frame with content to analyze
#' @param fields Named list of field specifications from field_*() functions
#' @param input Column containing content to analyze (unquoted, optional)
#' @param input_type Type of input: "text", "image", "pdf", "markdown", "html"
#' @param id Optional unique ID column. If NULL, creates id from row_number()
#' @param prompt_task Task description for the LLM
#' @param batch_size Number of items per API call (default: 10)
#' @param n_draws Number of independent draws per item (default: 1)
#' @param delay_seconds Seconds between batches (default: 2)
#' @param chat Chat constructor from choose_ollama(), choose_gemini(), etc.
#' @param model_params Optional list of additional model parameters
#' @param track_params Whether to store model parameters as columns (default: TRUE)
#' @param show_progress Show progress messages? (default: TRUE)
#'
#' @return A data frame with columns: id, draw_id, each field from fields,
#'         plus metadata (model_name, provider, prompt, params_hash, and parameter columns)
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Define extraction schema
#' extraction_fields <- list(
#'   sentiment = field_category("Sentiment", c("positive", "negative", "neutral")),
#'   rating = field_integer("Rating from 1 to 5"),
#'   would_recommend = field_boolean("Whether user would recommend")
#' )
#'
#' # Sample data
#' reviews <- data.frame(
#'   review_id = 1:2,
#'   text = c(
#'     "Great battery life but screen is dim. I'd recommend it though - 4/5",
#'     "Terrible product, completely broken. Would not recommend. 1/5"
#'   )
#' )
#'
#' chat <- choose_gemini(model = "gemini-2.0-flash-lite")
#'
#' results <- reviews |>
#'   llm_extract(
#'     fields = extraction_fields,
#'     input = text,
#'     id = review_id,
#'     prompt_task = "Analyze this product review",
#'     chat = chat,
#'     n_draws = 3
#'   )
#'
#' # View results
#' print(results)
#' }
#'
#' @export
llm_extract <- function(data, fields, input = NULL, input_type = "text", id = NULL,
                        prompt_task,
                        batch_size = 10,
                        n_draws = 1,
                        delay_seconds = 2,
                        chat = NULL,
                        model_params = list(),
                        track_params = TRUE,
                        show_progress = TRUE) {
  if(is.null(chat)) {
    stop("chat is required. Use choose_ollama(), choose_gemini(), etc.")
  }

  if(length(fields) == 0) {
    stop("At least one field must be provided in fields")
  }

  if(is.null(names(fields)) || any(names(fields) == "")) {
    stop("All fields must be named (e.g., list(gender = field_category(...)))")
  }

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

  # Check provider for native file support
  has_native_files <- provider_name %in% c("google", "openai", "anthropic")

  # Create content column based on input type (only if input is provided)
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

  type_components <- list()
  for(field_name in names(fields)) {
    type_components[[field_name]] <- fields[[field_name]]$ellmer_type
  }

  type_spec <- ellmer::type_object(!!!type_components, .description = "Extracted fields from analysis")

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
    cli::cli_h1("llm_extract: extracting {length(fields)} fields from {nrow(data)} items x {n_draws} draws")
    cli::cli_alert_info("Model: {model_name} ({provider_name})")
    cli::cli_alert_info("Fields: {paste(names(fields), collapse = ', ')}")
    if(!is.null(input_col_name)) {
      cli::cli_alert_info("Input column: {input_col_name} (type: {input_type})")
    } else {
      cli::cli_alert_info("No input column provided (using prompts only)")
    }

    if(length(all_params) > 0) {
      param_str <- paste(names(all_params), unlist(all_params), sep = "=", collapse = ", ")
      cli::cli_alert_info("Parameters: {param_str}")
    }
  }

  all_draws <- vector("list", n_draws)

  for(draw in seq_len(n_draws)) {
    if(show_progress) cli::cli_h2("Draw {draw}/{n_draws}")

    if(draw > 1 && show_progress) {
      cli::cli_alert_info("Waiting 5 seconds before next draw...")
      Sys.sleep(5)
    }

    id_field_map <- process_extract_draw(
      data = data,
      text_col = NULL,
      content_col = content_col_name,
      prompt_task = prompt_task,
      type_spec = type_spec,
      fields = fields,
      batch_size = batch_size,
      chat = chat,
      delay_seconds = delay_seconds,
      model_params = all_params,
      show_progress = show_progress
    )

    draw_df <- data |>
      dplyr::left_join(id_field_map, by = "id") |>
      dplyr::mutate(
        draw_id = as.integer(draw),
        model_name = model_name,
        provider = provider_name,
        prompt = prompt_task,
        params_hash = params_hash
      )

    for(field_name in names(fields)) {
      field_type <- fields[[field_name]]$type

      if (field_type == "array") {
        # For array fields, keep as list column
        draw_df <- draw_df |>
          dplyr::mutate(!!field_name := purrr::map(value, function(x) {
            if (is.null(x) || (length(x) == 1 && is.na(x))) return(NA)
            if (is.list(x) && !is.null(x[[field_name]])) {
              # Return as list (for array/vector)
              return(x[[field_name]])
            } else {
              return(NA)
            }
          }))
      } else {
        # For scalar fields (category, integer, number, text, boolean)
        draw_df <- draw_df |>
          dplyr::mutate(!!field_name := purrr::map_chr(value, function(x) {
            if (is.null(x) || (length(x) == 1 && is.na(x))) return(NA_character_)
            if (is.list(x) && !is.null(x[[field_name]])) {
              as.character(x[[field_name]])
            } else {
              NA_character_
            }
          }))
      }
    }

    draw_df <- draw_df |> dplyr::select(-value, -dplyr::any_of(".__temp_content"))

    if(track_params && length(all_params) > 0) {
      for(param_name in names(all_params)) {
        param_value <- all_params[[param_name]]
        if(is.numeric(param_value)) {
          draw_df <- draw_df |> dplyr::mutate(!!param_name := param_value)
        } else if(is.logical(param_value)) {
          draw_df <- draw_df |> dplyr::mutate(!!param_name := param_value)
        } else {
          draw_df <- draw_df |> dplyr::mutate(!!param_name := as.character(param_value))
        }
      }
    }

    all_draws[[draw]] <- draw_df
  }

  result <- dplyr::bind_rows(all_draws)

  return(result)
}
