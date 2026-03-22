#' Annotate media bias in a headline edit
#'
#' Sends an original and edited headline to the OpenAI API and returns a
#' structured analysis of 13 types of media bias.
#'
#' @param original Character string. The original headline.
#' @param edited Character string. The edited headline.
#' @param added_words Character vector of words added in the edit, or NULL
#'   to compute automatically via word-level set difference.
#' @param removed_words Character vector of words removed in the edit, or NULL
#'   to compute automatically via word-level set difference.
#' @param api_key Character string. OpenAI API key. Defaults to the
#'   \code{OPENAI_API_KEY} environment variable.
#' @param model Character string. The OpenAI model to use. Defaults to
#'   \code{"gpt-3.5-turbo"}.
#' @return A named list with each bias type containing \code{value}
#'   ("Added"/"Removed"/"None") and \code{reason}.
#' @export
annotate_bias <- function(original,
                          edited,
                          added_words = NULL,
                          removed_words = NULL,
                          api_key = Sys.getenv("OPENAI_API_KEY"),
                          model = "gpt-3.5-turbo") {

  if (is.null(api_key) || nchar(api_key) == 0) {
    stop("OpenAI API key not found. Set the OPENAI_API_KEY environment variable or pass it via the api_key argument.")
  }

  # Compute word-level differences if not provided
  original_words <- strsplit(original, "\\s+")[[1]]
  edited_words <- strsplit(edited, "\\s+")[[1]]

  if (is.null(added_words)) {
    added_words <- setdiff(edited_words, original_words)
  }
  if (is.null(removed_words)) {
    removed_words <- setdiff(original_words, edited_words)
  }

  added_str <- if (length(added_words) == 0) "None" else paste(added_words, collapse = ", ")
  removed_str <- if (length(removed_words) == 0) "None" else paste(removed_words, collapse = ", ")

  # Build the user message

  user_message <- paste0(
    "Original Headline: ", original, "\n",
    "Edited Headline: ", edited, "\n",
    "Added words: ", added_str, "\n",
    "Removed words: ", removed_str
  )

  # Call the OpenAI Chat Completions API
  body <- list(
    model = model,
    messages = list(
      list(role = "system", content = mediaspin_prompt()),
      list(role = "user", content = user_message)
    ),
    temperature = 0
  )

  resp <- httr2::request("https://api.openai.com/v1/chat/completions") |>
    httr2::req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_perform()

  resp_body <- httr2::resp_body_json(resp)

  # Extract the assistant's reply

  raw_text <- resp_body$choices[[1]]$message$content

  # Parse and return structured result
  parse_bias_response(raw_text)
}


#' Batch annotate media bias for multiple headline pairs
#'
#' Processes a data.frame of original and edited headline pairs, calling
#' \code{annotate_bias} for each row.
#'
#' @param pairs_df A data.frame with at least two columns: \code{original} and
#'   \code{edited}. May optionally include \code{added_words} and
#'   \code{removed_words} columns (character strings with comma-separated words).
#' @param api_key Character string. OpenAI API key. Defaults to the
#'   \code{OPENAI_API_KEY} environment variable.
#' @param model Character string. The OpenAI model to use. Defaults to
#'   \code{"gpt-3.5-turbo"}.
#' @return A list of named lists, one per row, each containing the bias
#'   analysis results.
#' @export
annotate_batch <- function(pairs_df,
                           api_key = Sys.getenv("OPENAI_API_KEY"),
                           model = "gpt-3.5-turbo") {

  if (!all(c("original", "edited") %in% names(pairs_df))) {
    stop("pairs_df must contain 'original' and 'edited' columns.")
  }

  results <- vector("list", nrow(pairs_df))

  for (i in seq_len(nrow(pairs_df))) {
    added <- NULL
    removed <- NULL

    if ("added_words" %in% names(pairs_df) && !is.na(pairs_df$added_words[i])) {
      added <- trimws(strsplit(pairs_df$added_words[i], ",")[[1]])
    }
    if ("removed_words" %in% names(pairs_df) && !is.na(pairs_df$removed_words[i])) {
      removed <- trimws(strsplit(pairs_df$removed_words[i], ",")[[1]])
    }

    message(sprintf("Annotating row %d of %d...", i, nrow(pairs_df)))

    results[[i]] <- tryCatch(
      annotate_bias(
        original = pairs_df$original[i],
        edited = pairs_df$edited[i],
        added_words = added,
        removed_words = removed,
        api_key = api_key,
        model = model
      ),
      error = function(e) {
        warning(sprintf("Error on row %d: %s", i, conditionMessage(e)))
        NULL
      }
    )
  }

  results
}
