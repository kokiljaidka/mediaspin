# Compute binary subjective/objective bias flags from 13-category annotations
#
# Input:  final_dataset (with *_value columns for each bias type)
# Output: final_dataset with subjective_bias and objective_bias columns

subjective_cols <- c(
  "opinion_statements_presented_as_fact_value",
  "sensationalism_value",
  "mudslinging_value",
  "mind_reading_value",
  "subjective_qualifying_adjectives_value",
  "word_choice_value",
  "spin_value"
)

objective_cols <- c(
  "unsubstantiated_claims_value",
  "slant_value",
  "flawed_logic_value",
  "bias_by_omission_value",
  "omission_of_source_attribution_value",
  "bias_by_story_choice_and_placement_value"
)

subjective_cols <- intersect(subjective_cols, names(final_dataset))
objective_cols <- intersect(objective_cols, names(final_dataset))

final_dataset$subjective_bias <- apply(
  final_dataset[subjective_cols], 1,
  function(x) any(as.logical(as.numeric(x)), na.rm = TRUE)
)

final_dataset$objective_bias <- apply(
  final_dataset[objective_cols], 1,
  function(x) any(as.logical(as.numeric(x)), na.rm = TRUE)
)

table(final_dataset$subjective_bias)
table(final_dataset$objective_bias)
