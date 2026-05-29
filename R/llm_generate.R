#' Generate structured synthetic data
#'
#' Creates synthetic data from scratch using an LLM, with structured output
#' defined by field specifications. Perfect for generating vignettes,
#' survey responses, stimulus materials, or test data.
#'
#' @param n Number of items to generate
#' @param fields Named list of field specifications from field_*() functions
#' @param prompt_template Template prompt (can include placeholders like \{row\})
#' @param chat Chat constructor
#' @param n_draws Number of independent draws per item (default: 1)
#' @param ... Additional arguments passed to llm_extract
#'
#' @return A data frame with columns: id, draw_id, and each field from fields
#' @export
#'
#' @examples
#' \dontrun{
#' schema <- list(
#'   age = field_integer("Patient age (20-80)"),
#'   diagnosis = field_category("Diagnosis", c("depression", "GAD", "PTSD")),
#'   vignette = field_text("The therapy vignette (2-3 sentences)")
#' )
#'
#' # Generate 10 synthetic therapy vignettes
#' synthetic_data <- llm_generate(
#'   n = 10,
#'   fields = schema,
#'   prompt_template = "Generate a therapy vignette.",
#'   chat = chat
#' )
#' }
llm_generate <- function(n, fields, prompt_template = NULL, chat = NULL,
                         n_draws = 1, ...) {

  if (is.null(chat)) {
    stop("chat is required. Use choose_ollama(), choose_gemini(), etc.")
  }

  # Create a simple data frame with just an id column (no dummy generation column)
  data <- data.frame(id = seq_len(n))

  # If no prompt_template, create a generic one
  if (is.null(prompt_template)) {
    field_names <- paste(names(fields), collapse = ", ")
    prompt_template <- paste("Generate realistic content. Include:", field_names)
  }

  # Use llm_extract with the id column as dummy input
  # The id column is ignored by the model but serves as row identifier
  result <- llm_extract(
    data = data,
    fields = fields,
    input = id,  # Use id as dummy input (will be passed but not used by model)
    input_type = "text",
    id = id,
    prompt_task = prompt_template,
    chat = chat,
    n_draws = n_draws,
    ...
  )

  # Remove the input column if it appears (it's just a dummy)
  if ("input" %in% colnames(result)) {
    result <- result %>% dplyr::select(-input)
  }

  return(result)
}
