# Match headlines to news mentions using string distance and extract engagement metrics
#
# Input:  delibdata_filtered_news_mentions (tweets with public_metrics)
#         dataset_with_keywords (headlines with bias labels)
# Output: matched_headlines_with_bias.csv

library(stringdist)
library(dplyr)

mentions_df <- delibdata_filtered_news_mentions %>%
  select(text, public_metrics)

headlines_df <- dataset_with_keywords %>%
  select(edited_headline, overall_objective_bias, overall_subjective_bias)

results <- list()

for (i in seq_len(nrow(headlines_df))) {
  headline <- headlines_df$edited_headline[i]
  cat("Processing headline", i, "of", nrow(headlines_df), "\n")

  distances <- stringdist::stringdist(mentions_df$text, headline, method = "lv")
  matched_indices <- which(distances < 50)

  if (length(matched_indices) > 0) {
    matched_mentions <- mentions_df[matched_indices, ]
    temp_df <- data.frame(
      mention_text = matched_mentions$text,
      public_metrics = matched_mentions$public_metrics,
      headline = headline,
      distance = distances[matched_indices],
      overall_objective_bias = headlines_df$overall_objective_bias[i],
      overall_subjective_bias = headlines_df$overall_subjective_bias[i],
      stringsAsFactors = FALSE
    )
    results[[length(results) + 1]] <- temp_df
  }
}

matched_with_bias <- bind_rows(results)
write.csv(matched_with_bias, "matched_headlines_with_bias.csv", row.names = FALSE)
