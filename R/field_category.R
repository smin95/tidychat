#' Create a category field specification
#'
#' Defines a categorical field for structured extraction with llm_extract().
#' The LLM will be constrained to return one of the specified categories.
#'
#' @param description Character string describing what to extract. This guides
#'        the LLM on what information to look for. Be specific and clear.
#'        Example: "The primary emotion expressed in the text"
#' @param categories Character vector of allowed category values. The LLM will
#'        only return values from this list. Example: c("happy", "sad", "neutral")
#' @param required Logical. If TRUE (default), the field must be present in the
#'        extraction. If FALSE, the field is optional.
#'
#' @return A list containing field metadata and ellmer type specification for
#'         structured extraction.
#'
#' @examples
#' \dontrun{
#' # Define a sentiment field
#' sentiment_field <- field_category(
#'   description = "Overall sentiment of the review",
#'   categories = c("positive", "negative", "neutral")
#' )
#'
#' # Use in llm_extract
#' fields <- list(
#'   sentiment = sentiment_field,
#'   would_recommend = field_category(
#'     description = "Would the user recommend this product?",
#'     categories = c("yes", "no", "maybe")
#'   )
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_category <- function(description, categories, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "category",
    description = description,
    categories = categories,
    required = required,
    ellmer_type = ellmer::type_enum(categories, description, required = required)
  )
}

#' Create an integer field specification
#'
#' Defines an integer field for structured extraction with llm_extract().
#' The LLM will be constrained to return an integer value.
#'
#' @param description Character string describing what integer to extract.
#'        Be specific about the range or meaning. Example: "Rating from 1 to 5 stars"
#' @param required Logical. If TRUE (default), the field must be present in the
#'        extraction. If FALSE, the field is optional.
#'
#' @return A list containing field metadata and ellmer type specification for
#'         structured extraction.
#'
#' @examples
#' \dontrun{
#' # Define a rating field
#' rating_field <- field_integer(
#'   description = "Number of stars given in the review (1-5)"
#' )
#'
#' # Use in llm_extract
#' fields <- list(
#'   rating = rating_field,
#'   session_count = field_integer(
#'     description = "Number of therapy sessions attended",
#'     required = FALSE
#'   )
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_integer <- function(description, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "integer",
    description = description,
    required = required,
    ellmer_type = ellmer::type_integer(description, required = required)
  )
}

#' Create a number field specification
#'
#' Defines a numeric field for structured extraction with llm_extract().
#' The LLM will be constrained to return a numeric value (can include decimals).
#'
#' @param description Character string describing what number to extract.
#'        Be specific about the meaning and possible range.
#'        Example: "Effect size (Cohen's d) from the statistical analysis"
#' @param required Logical. If TRUE (default), the field must be present in the
#'        extraction. If FALSE, the field is optional.
#'
#' @return A list containing field metadata and ellmer type specification for
#'         structured extraction.
#'
#' @examples
#' \dontrun{
#' # Define an effect size field
#' effect_size_field <- field_number(
#'   description = "Cohen's d effect size for the primary outcome"
#' )
#'
#' # Use in llm_extract
#' fields <- list(
#'   effect_size = effect_size_field,
#'   p_value = field_number(
#'     description = "P-value for the main statistical test",
#'     required = FALSE
#'   )
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_number <- function(description, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "number",
    description = description,
    required = required,
    ellmer_type = ellmer::type_number(description, required = required)
  )
}

#' Create a text field specification
#'
#' Defines a free-text field for structured extraction with llm_extract().
#' The LLM will return a text string (not constrained to categories).
#'
#' @param description Character string describing what text to extract.
#'        Be specific about length and content. Example: "Summarize the main
#'        limitation mentioned by the authors (max 50 words)"
#' @param required Logical. If TRUE (default), the field must be present in the
#'        extraction. If FALSE, the field is optional.
#'
#' @return A list containing field metadata and ellmer type specification for
#'         structured extraction.
#'
#' @examples
#' \dontrun{
#' # Define a text field for extracting limitations
#' limitation_field <- field_text(
#'   description = "Main limitation or weakness reported in the study"
#' )
#'
#' # Use in llm_extract
#' fields <- list(
#'   limitation = limitation_field,
#'   conclusion = field_text(
#'     description = "Author's main conclusion (one sentence)",
#'     required = FALSE
#'   )
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_text <- function(description, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "text",
    description = description,
    required = required,
    ellmer_type = ellmer::type_string(description, required = required)
  )
}

#' Create a boolean field specification
#'
#' Defines a boolean (TRUE/FALSE) field for structured extraction with llm_extract().
#' The LLM will be constrained to return either TRUE or FALSE.
#'
#' @param description Character string describing what boolean condition to evaluate.
#'        Frame as a yes/no question. Example: "Does the study report significant
#'        treatment effects?" (returns TRUE if yes, FALSE if no)
#' @param required Logical. If TRUE (default), the field must be present in the
#'        extraction. If FALSE, the field is optional.
#'
#' @return A list containing field metadata and ellmer type specification for
#'         structured extraction.
#'
#' @examples
#' \dontrun{
#' # Define a boolean field for significance
#' significant_field <- field_boolean(
#'   description = "Whether the main finding was statistically significant"
#' )
#'
#' # Use in llm_extract
#' fields <- list(
#'   is_significant = significant_field,
#'   uses_preregistration = field_boolean(
#'     description = "Does the study mention preregistration?",
#'     required = FALSE
#'   )
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_boolean <- function(description, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "boolean",
    description = description,
    required = required,
    ellmer_type = ellmer::type_boolean(description, required = required)
  )
}

#' Create an array field specification
#'
#' Defines an array/list field for structured extraction with llm_extract().
#' Useful when extracting multiple items of the same type.
#'
#' @param description Character string describing what to extract as a list.
#' @param item_type The type specification for each item in the array.
#'        Can be created with field_text(), field_integer(), etc.
#' @param required Logical. If TRUE (default), the field must be present.
#'
#' @return A list containing field metadata and ellmer type specification.
#'
#' @examples
#' \dontrun{
#' # Define an array of themes
#' themes_field <- field_array(
#'   description = "Main themes identified in the qualitative analysis",
#'   item_type = field_text("A single theme or category")
#' )
#' }
#'
#' @seealso \code{\link{llm_extract}} for using field specifications
#' @export
field_array <- function(description, item_type, required = TRUE) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required for field extraction")
  }
  list(
    type = "array",
    description = description,
    required = required,
    ellmer_type = ellmer::type_array(item_type$ellmer_type, description = description)
  )
}
