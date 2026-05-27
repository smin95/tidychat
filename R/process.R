#' Process a single draw with fixed prompt
#'
#' Internal function that processes one draw (iteration) of annotation
#' using a fixed prompt across all items. Handles batching, rate limiting,
#' content processing (text, images, PDFs), and response parsing.
#'
#' @param data Data frame containing items to process (must have id column)
#' @param text_col Name of column containing text input (optional)
#' @param content_col Name of column containing pre-processed content objects
#' @param prompt_task The prompt template to use for all items
#' @param extract_type Type of extraction: "category", "numeric", or "text"
#' @param categories Vector of allowed categories (for category extraction)
#' @param batch_size Number of items to process per batch
#' @param chat_constructor Chat constructor function that returns a chat object
#' @param delay_seconds Delay between batches (and items within batch) in seconds
#' @param model_params List of additional model parameters
#' @param use_structured Whether to use structured extraction
#' @param type_spec Type specification for structured extraction
#' @param show_progress Whether to show progress messages
#'
#' @return A data frame with columns id and value (the extracted annotation)
#'
#' @keywords internal
process_single_draw <- function(data, text_col, content_col = NULL, prompt_task, extract_type,
                                categories, batch_size, chat_constructor,
                                delay_seconds, model_params = list(),
                                use_structured = FALSE, type_spec = NULL,
                                show_progress) {

  n_items <- nrow(data)
  n_batches <- ceiling(n_items / batch_size)

  if(show_progress) {
    cli::cli_progress_bar("Processing batches", total = n_batches)
  }

  all_results <- vector("list", n_batches)

  for(b in seq_len(n_batches)) {
    if(b > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

    idx_start <- (b - 1) * batch_size + 1
    idx_end <- min(b * batch_size, n_items)
    batch_df <- data[idx_start:idx_end, ]

    batch_results <- list()

    for(i in seq_len(nrow(batch_df))) {
      # Add delay between items within batch (CRITICAL for rate limits)
      if(i > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

      id_val <- batch_df$id[i]

      if(extract_type == "category" && !is.null(categories)) {
        strict_prompt <- paste0(
          prompt_task,
          "\n\nIMPORTANT: Respond with ONLY ONE WORD from this list: ",
          paste(categories, collapse = ", "),
          ". Do not explain. Do not add punctuation. Do not add extra words. Just the single word."
        )
      } else if(extract_type == "numeric") {
        strict_prompt <- paste0(
          prompt_task,
          "\n\nIMPORTANT: Respond with ONLY THE NUMBER. Do not explain. Do not add extra words. Just the number."
        )
      } else {
        strict_prompt <- prompt_task
      }

      full_prompt <- if (!is.null(text_col)) {
        paste0(strict_prompt, "\n\nText: ", batch_df[[text_col]][i])
      } else {
        strict_prompt
      }

      raw_response <- NULL
      chat <- chat_constructor()

      # Check if we have content from PDFs, images, etc.
      if(!is.null(content_col)) {
        content_item <- batch_df[[content_col]][[i]]

        if(!is.null(content_item)) {
          # Case 1: Character content (extracted text)
          if (is.character(content_item) && nchar(content_item) > 0) {
            full_prompt_with_content <- paste0(full_prompt, "\n\nDocument Content:\n", content_item)

            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt_with_content)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
                Sys.sleep(delay_seconds)
              }
            }
          }
          # Case 2: Native content objects
          else if (is.object(content_item) && !is.character(content_item)) {
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt, images = content_item)
              }, error = function(e) {
                if(grepl("429|rate|limit|quota|too many requests", e$message, ignore.case = TRUE)) {
                  wait_time <- min(30 * attempt, 300)
                  if(show_progress) {
                    cli::cli_alert_warning("Rate limit hit, waiting {wait_time}s before retry {attempt}/5")
                  }
                  Sys.sleep(wait_time)
                } else if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                } else if(attempt < 5 && show_progress) {
                  cli::cli_alert_warning("Attempt {attempt}/5 failed: {e$message}")
                  Sys.sleep(delay_seconds * attempt)
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }
            }
          }
          else {
            # Fallback: just text
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                Sys.sleep(delay_seconds * attempt)
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
              }
            }
          }
        } else {
          # No content, just text
          for(attempt in 1:5) {
            resp_obj <- tryCatch({
              chat$chat(full_prompt)
            }, error = function(e) {
              if(attempt == 5 && show_progress) {
                cli::cli_alert_danger("Item {id_val} error: {e$message}")
              }
              Sys.sleep(delay_seconds * attempt)
              return(NULL)
            })

            if(!is.null(resp_obj)) {
              raw_response <- as.character(resp_obj)
              break
            }

            if(attempt < 5 && show_progress) {
              cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
            }
          }
        }
      } else {
        # No content column, just text
        for(attempt in 1:5) {
          resp_obj <- tryCatch({
            chat$chat(full_prompt)
          }, error = function(e) {
            if(attempt == 5 && show_progress) {
              cli::cli_alert_danger("Item {id_val} error: {e$message}")
            }
            Sys.sleep(delay_seconds * attempt)
            return(NULL)
          })

          if(!is.null(resp_obj)) {
            raw_response <- as.character(resp_obj)
            break
          }

          if(attempt < 5 && show_progress) {
            cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
          }
        }
      }

      # Parse the response
      if(is.null(raw_response) || is.na(raw_response) || nchar(trimws(raw_response)) == 0) {
        value <- NA_character_
      } else {
        raw_response_char <- as.character(raw_response)

        if(extract_type == "numeric") {
          clean_response <- trimws(tolower(raw_response_char))
          nums <- regmatches(clean_response, gregexpr("\\b[0-9]+\\b", clean_response))[[1]]
          if(length(nums) > 0) {
            value <- nums[1]
          } else {
            value <- NA_character_
          }
        } else if(extract_type == "category" && !is.null(categories) && length(categories) > 0) {
          clean_response <- trimws(tolower(raw_response_char))
          words <- strsplit(clean_response, "[^a-z]+")[[1]]
          valid_cats <- tolower(categories)
          matched <- words[words %in% valid_cats]
          if(length(matched) > 0) {
            value <- matched[1]
          } else {
            value <- NA_character_
            for(cat in valid_cats) {
              if(grepl(cat, clean_response)) {
                value <- cat
                break
              }
            }
          }
        } else {
          cleaned <- trimws(raw_response_char)
          cleaned <- gsub("^(the title of the paper is|the title is|the answer is|the result is|the paper title is)\\s*:?\\s*", "", cleaned, ignore.case = TRUE)
          cleaned <- gsub("^[*\\s]*", "", cleaned)
          cleaned <- gsub("[*\\s]*$", "", cleaned)
          value <- cleaned
        }
      }

      if(is.null(value)) value <- NA_character_
      if(!is.character(value)) value <- as.character(value)

      batch_results[[i]] <- tibble::tibble(id = id_val, value = value)

      if(show_progress) {
        if(!is.na(value) && value != "") {
          cli::cli_alert_success("Item {id_val}: {substr(value, 1, 100)}")
        } else {
          cli::cli_alert_warning("Item {id_val}: No response")
        }
      }
    }

    parsed <- dplyr::bind_rows(batch_results)
    n_valid <- sum(!is.na(parsed$value) & parsed$value != "")
    if(show_progress) {
      cli::cli_alert_success("Batch {b}: {n_valid}/{nrow(batch_df)} parsed")
    }

    all_results[[b]] <- parsed
    if(show_progress) cli::cli_progress_update()
  }

  if(show_progress) cli::cli_progress_done()

  final_mapping <- dplyr::bind_rows(all_results) |>
    dplyr::rename(id = id) |>
    dplyr::distinct(id, .keep_all = TRUE)

  return(final_mapping)
}


#' Process a single draw with per-row prompts
#'
#' Internal function that processes one draw (iteration) of annotation
#' where each row has its own custom prompt. Handles batching, rate limiting,
#' content processing, and response parsing for per-row prompts.
#'
#' @param data Data frame containing items to process (must have id column)
#' @param text_col Name of column containing text input (optional)
#' @param content_col Name of column containing pre-processed content objects
#' @param prompt_col Name of column containing per-row prompts
#' @param extract_type_col Name of column containing per-row extraction types
#' @param categories_col Name of column containing per-row categories (list column)
#' @param batch_size Number of items to process per batch
#' @param chat_constructor Chat constructor function that returns a chat object
#' @param delay_seconds Delay between batches (and items within batch) in seconds
#' @param model_params List of additional model parameters
#' @param use_structured Whether to use structured extraction
#' @param show_progress Whether to show progress messages
#'
#' @return A data frame with columns id and value (the extracted annotation)
#'
#' @keywords internal
process_single_draw_with_prompts <- function(data, text_col, content_col = NULL, prompt_col,
                                             extract_type_col, categories_col,
                                             batch_size, chat_constructor,
                                             delay_seconds, model_params = list(),
                                             use_structured = FALSE,
                                             show_progress) {

  n_items <- nrow(data)
  n_batches <- ceiling(n_items / batch_size)

  if(show_progress) {
    cli::cli_progress_bar("Processing batches", total = n_batches)
  }

  all_results <- vector("list", n_batches)

  for(b in seq_len(n_batches)) {
    if(b > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

    idx_start <- (b - 1) * batch_size + 1
    idx_end <- min(b * batch_size, n_items)
    batch_df <- data[idx_start:idx_end, ]

    batch_results <- list()

    for(i in seq_len(nrow(batch_df))) {
      # Add delay between items within batch (CRITICAL for rate limits)
      if(i > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

      id_val <- batch_df$id[i]
      prompt <- batch_df[[prompt_col]][i]
      extract_type <- batch_df[[extract_type_col]][i]
      categories <- batch_df[[categories_col]][[i]]

      if(is.list(categories) && length(categories) == 1 && !is.character(categories[[1]])) {
        categories <- categories[[1]]
      }

      if(extract_type == "category" && !is.null(categories) && length(categories) > 0) {
        strict_prompt <- paste0(
          prompt,
          "\n\nIMPORTANT: Respond with ONLY ONE WORD from this list: ",
          paste(categories, collapse = ", "),
          ". Do not explain. Do not add punctuation. Do not add extra words. Just the single word."
        )
      } else if(extract_type == "numeric") {
        strict_prompt <- paste0(
          prompt,
          "\n\nIMPORTANT: Respond with ONLY THE NUMBER. Do not explain. Do not add extra words. Just the number."
        )
      } else {
        strict_prompt <- prompt
      }

      full_prompt <- if (!is.null(text_col)) {
        paste0(strict_prompt, "\n\nText: ", batch_df[[text_col]][i])
      } else {
        strict_prompt
      }

      raw_response <- NULL
      chat <- chat_constructor()

      # Check if we have content from PDFs, images, etc.
      if(!is.null(content_col)) {
        content_item <- batch_df[[content_col]][[i]]

        if(!is.null(content_item)) {
          # Case 1: Character content (extracted text)
          if (is.character(content_item) && nchar(content_item) > 0) {
            full_prompt_with_content <- paste0(full_prompt, "\n\nDocument Content:\n", content_item)

            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt_with_content)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
                Sys.sleep(delay_seconds)
              }
            }
          }
          # Case 2: Native content objects
          else if (is.object(content_item) && !is.character(content_item)) {
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt, images = content_item)
              }, error = function(e) {
                if(grepl("429|rate|limit|quota|too many requests", e$message, ignore.case = TRUE)) {
                  wait_time <- min(30 * attempt, 300)
                  if(show_progress) {
                    cli::cli_alert_warning("Rate limit hit, waiting {wait_time}s before retry {attempt}/5")
                  }
                  Sys.sleep(wait_time)
                } else if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                } else if(attempt < 5 && show_progress) {
                  cli::cli_alert_warning("Attempt {attempt}/5 failed: {e$message}")
                  Sys.sleep(delay_seconds * attempt)
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }
            }
          }
          else {
            # Fallback: just text
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat$chat(full_prompt)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                Sys.sleep(delay_seconds * attempt)
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- as.character(resp_obj)
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
              }
            }
          }
        } else {
          # No content, just text
          for(attempt in 1:5) {
            resp_obj <- tryCatch({
              chat$chat(full_prompt)
            }, error = function(e) {
              if(attempt == 5 && show_progress) {
                cli::cli_alert_danger("Item {id_val} error: {e$message}")
              }
              Sys.sleep(delay_seconds * attempt)
              return(NULL)
            })

            if(!is.null(resp_obj)) {
              raw_response <- as.character(resp_obj)
              break
            }

            if(attempt < 5 && show_progress) {
              cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
            }
          }
        }
      } else {
        # No content column, just text
        for(attempt in 1:5) {
          resp_obj <- tryCatch({
            chat$chat(full_prompt)
          }, error = function(e) {
            if(attempt == 5 && show_progress) {
              cli::cli_alert_danger("Item {id_val} error: {e$message}")
            }
            Sys.sleep(delay_seconds * attempt)
            return(NULL)
          })

          if(!is.null(resp_obj)) {
            raw_response <- as.character(resp_obj)
            break
          }

          if(attempt < 5 && show_progress) {
            cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
          }
        }
      }

      # Parse the response
      if(is.null(raw_response) || is.na(raw_response) || nchar(trimws(raw_response)) == 0) {
        value <- NA_character_
      } else {
        raw_response_char <- as.character(raw_response)

        if(extract_type == "numeric") {
          clean_response <- trimws(tolower(raw_response_char))
          nums <- regmatches(clean_response, gregexpr("\\b[0-9]+\\b", clean_response))[[1]]
          if(length(nums) > 0) {
            value <- nums[1]
          } else {
            value <- NA_character_
          }
        } else if(extract_type == "category" && !is.null(categories) && length(categories) > 0) {
          clean_response <- trimws(tolower(raw_response_char))
          words <- strsplit(clean_response, "[^a-z]+")[[1]]
          valid_cats <- tolower(categories)
          matched <- words[words %in% valid_cats]
          if(length(matched) > 0) {
            value <- matched[1]
          } else {
            value <- NA_character_
            for(cat in valid_cats) {
              if(grepl(cat, clean_response)) {
                value <- cat
                break
              }
            }
          }
        } else {
          cleaned <- trimws(raw_response_char)
          cleaned <- gsub("^(the title of the paper is|the title is|the answer is|the result is|the paper title is)\\s*:?\\s*", "", cleaned, ignore.case = TRUE)
          cleaned <- gsub("^[*\\s]*", "", cleaned)
          cleaned <- gsub("[*\\s]*$", "", cleaned)
          value <- cleaned
        }
      }

      if(is.null(value)) value <- NA_character_
      if(!is.character(value)) value <- as.character(value)

      batch_results[[i]] <- tibble::tibble(id = id_val, value = value)

      if(show_progress) {
        if(!is.na(value) && value != "") {
          cli::cli_alert_success("Item {id_val}: {substr(value, 1, 100)}")
        } else {
          cli::cli_alert_warning("Item {id_val}: No response")
        }
      }
    }

    parsed <- dplyr::bind_rows(batch_results)
    n_valid <- sum(!is.na(parsed$value) & parsed$value != "")
    if(show_progress) {
      cli::cli_alert_success("Batch {b}: {n_valid}/{nrow(batch_df)} parsed")
    }

    all_results[[b]] <- parsed
    if(show_progress) cli::cli_progress_update()
  }

  if(show_progress) cli::cli_progress_done()

  final_mapping <- dplyr::bind_rows(all_results) |>
    dplyr::rename(id = id) |>
    dplyr::distinct(id, .keep_all = TRUE)

  return(final_mapping)
}


#' Process a single extraction draw for llm_extract
#'
#' Internal function that processes one draw (iteration) of structured extraction,
#' extracting multiple fields from each item using a type specification.
#' Handles batching, rate limiting, content processing, and structured response parsing.
#'
#' @param data Data frame containing items to process (must have id column)
#' @param text_col Name of column containing text input (optional)
#' @param content_col Name of column containing pre-processed content objects
#' @param prompt_task The prompt template to use for all items
#' @param type_spec Ellmer type specification for structured extraction
#' @param fields Named list of field specifications (for progress reporting)
#' @param batch_size Number of items to process per batch
#' @param chat Chat constructor function that returns a chat object
#' @param delay_seconds Delay between batches (and items within batch) in seconds
#' @param model_params List of additional model parameters
#' @param show_progress Whether to show progress messages
#'
#' @return A data frame with columns id and value (list column containing
#'         extracted fields as a named list)
#'
#' @keywords internal
process_extract_draw <- function(data, text_col, content_col = NULL, prompt_task,
                                 type_spec, fields, batch_size, chat,
                                 delay_seconds, model_params = list(),
                                 show_progress) {

  n_items <- nrow(data)
  n_batches <- ceiling(n_items / batch_size)

  if(show_progress) {
    cli::cli_progress_bar("Processing extraction batches", total = n_batches)
  }

  all_results <- vector("list", n_batches)

  for(b in seq_len(n_batches)) {
    if(b > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

    idx_start <- (b - 1) * batch_size + 1
    idx_end <- min(b * batch_size, n_items)
    batch_df <- data[idx_start:idx_end, ]

    batch_results <- list()

    for(i in seq_len(nrow(batch_df))) {
      # Add delay between items within batch (CRITICAL for rate limits)
      if(i > 1 && delay_seconds > 0) Sys.sleep(delay_seconds)

      # CRITICAL FIX: Use "id" column (without dot) to match the main data frame
      id_val <- batch_df$id[i]

      full_prompt <- if (!is.null(text_col)) {
        paste0(prompt_task, "\n\nText: ", batch_df[[text_col]][i])
      } else {
        prompt_task
      }

      raw_response <- NULL
      chat_instance <- chat()

      if(!is.null(content_col)) {
        content_item <- batch_df[[content_col]][[i]]

        if(!is.null(content_item)) {
          # Case 1: Character content (extracted text)
          if (is.character(content_item) && nchar(content_item) > 0) {
            full_prompt_with_content <- paste0(full_prompt, "\n\nDocument Content:\n", content_item)

            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat_instance$chat_structured(full_prompt_with_content, type = type_spec)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- resp_obj
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
                Sys.sleep(delay_seconds)
              }
            }
          }
          # Case 2: Native content objects
          else if (is.object(content_item) && !is.character(content_item)) {
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat_instance$chat_structured(full_prompt, type = type_spec, images = content_item)
              }, error = function(e) {
                if(grepl("429|rate|limit|quota|too many requests", e$message, ignore.case = TRUE)) {
                  wait_time <- min(30 * attempt, 300)
                  if(show_progress) {
                    cli::cli_alert_warning("Rate limit hit, waiting {wait_time}s before retry {attempt}/5")
                  }
                  Sys.sleep(wait_time)
                } else if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                } else if(attempt < 5 && show_progress) {
                  cli::cli_alert_warning("Attempt {attempt}/5 failed: {e$message}")
                  Sys.sleep(delay_seconds * attempt)
                }
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- resp_obj
                break
              }
            }
          }
          else {
            # Fallback: just text
            for(attempt in 1:5) {
              resp_obj <- tryCatch({
                chat_instance$chat_structured(full_prompt, type = type_spec)
              }, error = function(e) {
                if(attempt == 5 && show_progress) {
                  cli::cli_alert_danger("Item {id_val} error: {e$message}")
                }
                Sys.sleep(delay_seconds * attempt)
                return(NULL)
              })

              if(!is.null(resp_obj)) {
                raw_response <- resp_obj
                break
              }

              if(attempt < 5 && show_progress) {
                cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
              }
            }
          }
        } else {
          # No content, just text
          for(attempt in 1:5) {
            resp_obj <- tryCatch({
              chat_instance$chat_structured(full_prompt, type = type_spec)
            }, error = function(e) {
              if(attempt == 5 && show_progress) {
                cli::cli_alert_danger("Item {id_val} error: {e$message}")
              }
              Sys.sleep(delay_seconds * attempt)
              return(NULL)
            })

            if(!is.null(resp_obj)) {
              raw_response <- resp_obj
              break
            }

            if(attempt < 5 && show_progress) {
              cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
            }
          }
        }
      } else {
        # No content column, just text
        for(attempt in 1:5) {
          resp_obj <- tryCatch({
            chat_instance$chat_structured(full_prompt, type = type_spec)
          }, error = function(e) {
            if(attempt == 5 && show_progress) {
              cli::cli_alert_danger("Item {id_val} error: {e$message}")
            }
            Sys.sleep(delay_seconds * attempt)
            return(NULL)
          })

          if(!is.null(resp_obj)) {
            raw_response <- resp_obj
            break
          }

          if(attempt < 5 && show_progress) {
            cli::cli_alert_warning("Empty response, retrying {attempt + 1}/5...")
          }
        }
      }

      if(is.null(raw_response)) {
        value <- NA
      } else {
        if(is.list(raw_response)) {
          value <- list(raw_response)
        } else if(is.character(raw_response)) {
          parsed <- tryCatch(jsonlite::fromJSON(raw_response), error = function(e) NULL)
          if(is.list(parsed)) {
            value <- list(parsed)
          } else {
            value <- list(raw = raw_response)
          }
        } else {
          value <- list(raw = as.character(raw_response))
        }
      }

      batch_results[[i]] <- tibble::tibble(id = id_val, value = value)

      if(show_progress && !is.null(raw_response)) {
        cli::cli_alert_success("Item {id_val}: extracted {length(names(fields))} fields")
      }
    }

    parsed <- dplyr::bind_rows(batch_results)
    n_valid <- sum(!is.na(parsed$value))
    if(show_progress) {
      cli::cli_alert_success("Batch {b}: {n_valid}/{nrow(batch_df)} parsed")
    }

    all_results[[b]] <- parsed
    if(show_progress) cli::cli_progress_update()
  }

  if(show_progress) cli::cli_progress_done()

  final_mapping <- dplyr::bind_rows(all_results)

  return(final_mapping)
}
