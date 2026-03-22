#' Parse a bias analysis response from the LLM
#'
#' Takes the raw text response from the LLM and parses it into a structured
#' named list with each of the 13 bias types.
#'
#' @param text Character string. The raw text response from the LLM.
#' @return A named list where each element corresponds to a bias type and
#'   contains a list with \code{value} ("Added", "Removed", or "None") and
#'   \code{reason} (the explanation string).
#' @export
parse_bias_response <- function(text) {
  # Define the 13 bias types
  bias_types <- c(
    "Spin",
    "Unsubstantiated Claims",
    "Opinion Statements Presented as Fact",
    "Sensationalism/Emotionalism",
    "Mudslinging/Ad Hominem",
    "Mind Reading",
    "Slant",
    "Flawed Logic",
    "Bias by Omission",
    "Omission of Source Attribution",
    "Bias by Story Choice and Placement",
    "Subjective Qualifying Adjectives",
    "Word Choice"
  )

  # Split the text into lines
  lines <- strsplit(text, "\n")[[1]]
  lines <- trimws(lines)

  # Initialize result list
  result <- stats::setNames(
    vector("list", length(bias_types)),
    bias_types
  )

  # Set defaults

for (bt in bias_types) {
    result[[bt]] <- list(value = NA_character_, reason = NA_character_)
  }

  # Parse each line looking for bias analysis entries
  # Pattern: number. BiasType [Added/Removed/None]: reason
  bias_pattern <- "^\\d+\\.\\s*(.+?)\\s*\\[(Added|Removed|None)\\]\\s*:\\s*(.+)$"

  for (line in lines) {
    m <- regmatches(line, regexec(bias_pattern, line))[[1]]
    if (length(m) == 4) {
      matched_type <- trimws(m[2])
      matched_value <- m[3]
      matched_reason <- trimws(m[4])

      # Find the closest matching bias type
      for (bt in bias_types) {
        if (grepl(matched_type, bt, fixed = TRUE) ||
            grepl(bt, matched_type, fixed = TRUE)) {
          result[[bt]] <- list(value = matched_value, reason = matched_reason)
          break
        }
      }
    }
  }

  # Also extract words added/removed if present
  words_added_line <- grep("^Words Added:", lines, value = TRUE)
  words_removed_line <- grep("^Words Removed:", lines, value = TRUE)

  if (length(words_added_line) > 0) {
    attr(result, "words_added") <- sub("^Words Added:\\s*", "", words_added_line[1])
  }
  if (length(words_removed_line) > 0) {
    attr(result, "words_removed") <- sub("^Words Removed:\\s*", "", words_removed_line[1])
  }

  result
}
