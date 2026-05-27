#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x

#' @noRd
stable_hash <- function(x) {
  if(requireNamespace("digest", quietly = TRUE)) {
    digest::digest(x, algo = "crc32")
  } else {
    as.character(sum(utf8ToInt(paste(x, collapse = ""))) %% 1e6)
  }
}

#' @noRd
create_category_type <- function(categories, description = "The extracted category") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  if (!is.null(categories) && length(categories) > 0) {
    ellmer::type_array(
      ellmer::type_object(
        id = ellmer::type_integer("The ID of the item"),
        value = ellmer::type_enum(categories, description)
      )
    )
  } else {
    ellmer::type_array(
      ellmer::type_object(
        id = ellmer::type_integer("The ID of the item"),
        value = ellmer::type_string(description)
      )
    )
  }
}

#' @noRd
create_numeric_type <- function(description = "The extracted numeric value") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  ellmer::type_array(
    ellmer::type_object(
      id = ellmer::type_integer("The ID of the item"),
      value = ellmer::type_string(description)
    )
  )
}

#' @noRd
create_text_type <- function(description = "The extracted text") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  ellmer::type_array(
    ellmer::type_object(
      id = ellmer::type_integer("The ID of the item"),
      value = ellmer::type_string(description)
    )
  )
}

#' Create an integer type specification for structured extraction
#' @keywords internal
create_integer_type <- function(description = "The extracted integer value") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  ellmer::type_array(
    ellmer::type_object(
      id = ellmer::type_integer("The ID of the item"),
      value = ellmer::type_integer(description)
    )
  )
}

#' Create a boolean type specification for structured extraction
#' @keywords internal
create_boolean_type <- function(description = "The extracted boolean value") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  ellmer::type_array(
    ellmer::type_object(
      id = ellmer::type_integer("The ID of the item"),
      value = ellmer::type_boolean(description)
    )
  )
}

#' Create an array type specification for structured extraction
#' @keywords internal
create_array_type <- function(description = "The extracted array of values") {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for structured extraction")
  }
  ellmer::type_array(
    ellmer::type_object(
      id = ellmer::type_integer("The ID of the item"),
      value = ellmer::type_array(ellmer::type_string("Array item"), description = description)
    )
  )
}

#' Extract text from PDF file
#' @keywords internal
extract_pdf_text <- function(pdf_path, max_chars = 10000) {
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    warning("pdftools package required for PDF extraction. Install with: install.packages('pdftools')")
    return(NA_character_)
  }

  if (!file.exists(pdf_path)) {
    return(NA_character_)
  }

  tryCatch({
    text <- pdftools::pdf_text(pdf_path)
    text <- paste(text, collapse = "\n\n")
    if (nchar(text) > max_chars) {
      text <- substr(text, 1, max_chars)
      text <- paste0(text, "\n\n[Truncated due to length...]")
    }
    return(text)
  }, error = function(e) {
    cli::cli_alert_warning("Failed to extract PDF text: {e$message}")
    return(NA_character_)
  })
}
