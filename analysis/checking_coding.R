# Replace inconsistent country annotations with cleaned versions
#
# Input:  final_dataset_oct2025_checked (with *_inconsistent and *_countries_clean columns)
# Output: final_dataset_oct2025_checked with corrected *_countries columns

library(dplyr)

cols <- c("original", "edited", "added", "removed")

for (p in cols) {
  inconsistent_col <- paste0(p, "_inconsistent")
  clean_col <- paste0(p, "_countries_clean")
  country_col <- paste0(p, "_countries")

  final_dataset_oct2025_checked[[country_col]] <- ifelse(
    final_dataset_oct2025_checked[[inconsistent_col]] == TRUE &
      !is.na(final_dataset_oct2025_checked[[clean_col]]),
    final_dataset_oct2025_checked[[clean_col]],
    final_dataset_oct2025_checked[[country_col]]
  )
}

final_dataset_oct2025_checked <- final_dataset_oct2025_checked %>%
  select(-ends_with("_clean"), -ends_with("_inconsistent"))
