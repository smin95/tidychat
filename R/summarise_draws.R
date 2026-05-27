#' Summarise multiple draws from LLM annotations
#'
#' Provides summary statistics across multiple draws for each annotated item,
#' including agreement, entropy, and frequency distributions. Helps identify
#' cases where the LLM produced inconsistent responses across draws.
#'
#' @param data Data frame from \code{\link{llm_annotate}} or \code{\link{llm_extract}}
#' @param ... Unquoted names of annotation columns to summarise
#' @param all If TRUE, summarise all non-metadata columns (default: FALSE)
#' @param agreement_threshold Agreement threshold below which to flag as uncertain
#'        (default: 0.7). Lower values mean more tolerance for disagreement.
#' @param na_rm Remove NA values before calculating summaries? (default: TRUE)
#'
#' @return A tibble with columns:
#'   \item{column}{Name of the annotation column summarised}
#'   \item{n_draws}{Total number of draws}
#'   \item{n_valid}{Number of valid (non-NA) responses}
#'   \item{majority}{Most common value (or mean for numeric data)}
#'   \item{agreement}{Proportion of draws matching the majority (0-1)}
#'   \item{entropy}{Normalised Shannon entropy (0-1, higher = more uncertain)}
#'   \item{uncertain}{TRUE if agreement < agreement_threshold}
#'   \item{distribution}{Frequency distribution of responses as a string}
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Basic usage
#' results <- reviews |>
#'   llm_annotate(
#'     col = sentiment,
#'     input = text,
#'     chat = chat,
#'     n_draws = 5
#'   )
#'
#' # Summarise draws
#' results |> summarise_draws(sentiment)
#'
#' # For llm_extract results (multiple columns)
#' results |> summarise_draws(sentiment, rating, would_recommend)
#'
#' # Find uncertain items (agreement < 0.7)
#' results |>
#'   summarise_draws(sentiment) |>
#'   filter(uncertain == TRUE)
#'
#' # With grouping (e.g., by temperature or prompt framing)
#' results |>
#'   group_by(temperature, framing) |>
#'   summarise_draws(distress_rating)
#'
#' # Summarise all non-metadata columns
#' results |> summarise_draws(all = TRUE)
#'
#' # Custom agreement threshold (more strict)
#' results |> summarise_draws(sentiment, agreement_threshold = 0.8)
#' }
#'
#' @seealso
#' \code{\link{llm_annotate}} for generating multiple draws,
#' \code{\link{llm_extract}} for structured extraction
#'
#' @export
summarise_draws <- function(data, ..., all = FALSE,
                            agreement_threshold = 0.7, na_rm = TRUE) {
  output_cols <- rlang::enquos(...)

  if (all && length(output_cols) == 0) {
    metadata_cols <- c(".id", ".draw_id", "model_name", "provider",
                       "prompt", "params_hash",
                       ".row_prompt", ".row_extract_type", ".row_categories")

    group_vars <- dplyr::group_vars(data)
    exclude_cols <- c(metadata_cols, group_vars)
    output_cols_names <- setdiff(colnames(data), exclude_cols)

    if (length(output_cols_names) == 0) {
      stop("No non-metadata columns found to analyze.")
    }

    output_cols <- lapply(output_cols_names, function(col) rlang::sym(col))
    cli::cli_alert_info("Analyzing {length(output_cols)} columns: {paste(output_cols_names, collapse = ', ')}")
  } else if (length(output_cols) == 0) {
    stop("No columns specified. Provide column names or use all = TRUE")
  }

  results_list <- list()

  for (col_quo in output_cols) {
    output_col <- rlang::as_name(col_quo)

    if (!output_col %in% colnames(data)) {
      cli::cli_alert_warning("Column '{output_col}' not found in data. Skipping.")
      next
    }

    temp_data <- data |>
      dplyr::rename(.temp_output = dplyr::all_of(output_col))

    result <- temp_data |>
      dplyr::summarise(
        n_draws = dplyr::n(),
        n_valid = sum(!is.na(.temp_output)),
        majority = {
          vals <- .temp_output[!is.na(.temp_output)]
          if (length(vals) == 0) NA_character_
          else if (suppressWarnings(!any(is.na(as.numeric(vals))))) {
            as.character(round(mean(as.numeric(vals), na.rm = na_rm), 3))
          } else {
            names(which.max(table(vals)))
          }
        },
        agreement = {
          vals <- .temp_output[!is.na(.temp_output)]
          if (length(vals) == 0) NA_real_
          else if (suppressWarnings(!any(is.na(as.numeric(vals))))) {
            nv <- as.numeric(vals)
            rng <- diff(range(nv))
            if (rng == 0) 1.0 else 1 - stats::var(nv) / (rng^2 + 1e-9)
          } else {
            max(table(vals)) / length(vals)
          }
        },
        entropy = {
          vals <- .temp_output[!is.na(.temp_output)]
          n_unique <- length(unique(vals))
          if (length(vals) < 2 || n_unique <= 1) 0
          else {
            probs <- as.numeric(table(vals)) / length(vals)
            raw_h <- -sum(probs * log2(probs))
            raw_h / log2(n_unique)
          }
        },
        uncertain = agreement < agreement_threshold,
        distribution = {
          vals <- .temp_output[!is.na(.temp_output)]
          if (length(vals) == 0) NA_character_
          else {
            tab <- sort(table(vals), decreasing = TRUE)
            paste(paste0(names(tab), " (", as.integer(tab), ")"), collapse = ", ")
          }
        },
        .groups = "drop"
      ) |>
      dplyr::mutate(column = output_col, .before = 1)

    results_list[[output_col]] <- result
  }

  final_result <- dplyr::bind_rows(results_list)

  return(final_result)
}


#' @rdname summarise_draws
#' @export
summarize_draws <- summarise_draws
