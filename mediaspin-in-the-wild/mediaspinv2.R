library(dplyr)

# 1. Define bias columns based on your provided definitions
subjective_bias_cols <- c(
  "opinion_statements_presented_as_fact",
  "sensationalism_emotionalism",
  "mudslinging_ad_hominem",
  "mind_reading",
  "subjective_qualifying_adjectives",
  "word_choice",
  "spin"
)

objective_bias_cols <- c(
  "unsubstantiated_claims",
  "slant",
  "flawed_logic",
  "bias_by_omission",
  "omission_of_source_attribution",
  "bias_by_story_choice_and_placement"
)

library(dplyr)

delib <- delib %>%
  mutate(
    overall_subjective_bias = if_else(rowSums(select(., all_of(subjective_bias_cols)) == 1, na.rm = TRUE) > 0, 1, 0),
    overall_objective_bias  = if_else(rowSums(select(., all_of(objective_bias_cols)) == 1, na.rm = TRUE) > 0, 1, 0)
  )


library(jsonlite)
library(dplyr)
library(tidyr)

# Parse metrics into structured columns
library(dplyr)
library(stringr)
library(tidyr)

# Extract numeric counts using regex
delib_parsed <- delib %>%
  mutate(
    retweet_count = as.numeric(str_extract(public_metrics, "(?<=retweet_count': )\\d+")),
    reply_count   = as.numeric(str_extract(public_metrics, "(?<=reply_count': )\\d+")),
    like_count    = as.numeric(str_extract(public_metrics, "(?<=like_count': )\\d+"))
  )




# Create long-form for plotting by bias type
library(dplyr)
library(tidyr)

# Summary: Subjective bias only
subjective_summary <- delib_parsed %>%
  mutate(subjective_label = ifelse(overall_subjective_bias == 1, "Biased", "Not Biased")) %>%
  pivot_longer(cols = c(like_count, reply_count, retweet_count),
               names_to = "engagement_type", values_to = "count") %>%
  group_by(bias_label = subjective_label, engagement_type) %>%
  summarise(
    mean_count = mean(count, na.rm = TRUE),
    se_count = sd(count, na.rm = TRUE) / sqrt(n()),
    bias_type = "Subjective Bias",
    .groups = "drop"
  )

# Summary: Objective bias only
objective_summary <- delib_parsed %>%
  mutate(objective_label = ifelse(overall_objective_bias == 1, "Biased", "Not Biased")) %>%
  pivot_longer(cols = c(like_count, reply_count, retweet_count),
               names_to = "engagement_type", values_to = "count") %>%
  group_by(bias_label = objective_label, engagement_type) %>%
  summarise(
    mean_count = mean(count, na.rm = TRUE),
    se_count = sd(count, na.rm = TRUE) / sqrt(n()),
    bias_type = "Objective Bias",
    .groups = "drop"
  )

# Combine
engagement_summary <- bind_rows(subjective_summary, objective_summary)
engagement_summary$engagement_type <- factor(
  engagement_summary$engagement_type,
  levels = c("like_count", "reply_count", "retweet_count"),
  labels = c("Likes", "Replies", "Retweets")
)

library(ggplot2)

ggplot(engagement_summary, aes(x = engagement_type, y = mean_count, fill = bias_label)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_errorbar(
    aes(ymin = mean_count - se_count, ymax = mean_count + se_count),
    position = position_dodge(width = 0.8), width = 0.2
  ) +
  facet_wrap(~ bias_type) +
  scale_fill_manual(values = c("Biased" = "#f8766d", "Not Biased" = "#00bfc4")) +
  labs(
    title = "Mean Engagement by Bias Type",
    x = "Engagement Metric",
    y = "Mean Engagement",
    fill = "Bias"
  ) +
  theme_minimal(base_size = 14)


ggplot(engagement_summary, aes(x = engagement_type, y = mean_count + 1, fill = bias_label)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.6) +
  geom_errorbar(
    aes(ymin = mean_count + 1 - se_count, ymax = mean_count + 1 + se_count),
    width = 0.2,
    position = position_dodge(width = 0.8)
  ) +
  facet_wrap(~ bias_type) +
  scale_y_log10(labels = scales::comma_format(accuracy = 1)) +
  scale_fill_manual(values = c("Biased" = "#f8766d", "Not Biased" = "#00bfc4")) +
  labs(
    title = "Log-Scaled Mean Engagement by Bias Type",
    x = "Engagement Metric",
    y = "Mean Engagement (log scale)",
    fill = "Bias"
  ) +
  theme_minimal(base_size = 14)


ggplot(engagement_summary, aes(x = engagement_type, y = mean_count + 1, color = bias_label)) +
  geom_pointrange(
    aes(
      ymin = mean_count + 1 - se_count,
      ymax = mean_count + 1 + se_count
    ),
    position = position_dodge(width = 0.5),
    size = 0.8
  ) +
  scale_y_log10(labels = scales::comma_format(accuracy = 1)) +
  facet_wrap(~ bias_type) +
  scale_color_manual(values = c("Biased" = "#f8766d", "Not Biased" = "#00bfc4")) +
  labs(
    title = "Log-Scaled Mean Engagement by Bias Type",
    x = "Engagement Metric",
    y = "Mean Engagement (log scale)",
    color = "Bias"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "right",
    panel.grid.minor.y = element_blank()
  )


#######
library(ggplot2)

ggplot(engagement_summary, aes(x = engagement_type, y = mean_count + 1, color = bias_label)) +
  geom_pointrange(
    aes(
      ymin = mean_count + 1 - se_count,
      ymax = mean_count + 1 + se_count
    ),
    position = position_dodge(width = 0.5),
    size = 0.7,
    fatten = 3  # controls dot size relative to line
  ) +
  scale_y_log10(labels = scales::comma_format(accuracy = 1)) +
  scale_color_manual(
    values = c("Biased" = "#f8766d", "Not Biased" = "#00bfc4"),
    name = "Bias"
  ) +
  facet_wrap(~ bias_type) +
  labs(
    title = "Log-Scaled Mean Engagement by Bias Type",
    x = "Engagement Metric",
    y = "Mean Engagement (log scale)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "right",
    panel.border = element_rect(color = "black", fill = NA, size = 1),
    panel.grid.minor.y = element_blank(),
    strip.background = element_rect(fill = "white", color = "black", size = 0.5),
    strip.text = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  )



######### t tests

library(dplyr)
library(broom)
# Ensure inputs are character, not factor
delib_parsed <- delib_parsed %>%
  mutate(
    like_count = as.numeric(like_count),
    reply_count = as.numeric(reply_count),
    retweet_count = as.numeric(retweet_count),
    overall_subjective_bias = as.numeric(overall_subjective_bias),
    overall_objective_bias = as.numeric(overall_objective_bias)
  )

# Define function to run t-tests
library(rlang)

run_t_tests <- function(df, bias_col, metric) {
  bias_vals <- pull(df, !!sym(bias_col))
  metric_vals <- pull(df, !!sym(metric))
  
  t.test(metric_vals ~ bias_vals) %>%
    tidy() %>%
    mutate(
      metric = metric,
      bias_type = bias_col,
      comparison = "Biased vs Not Biased"
    )
}


# Run all combinations
metrics <- c("like_count", "reply_count", "retweet_count")
bias_types <- c("overall_subjective_bias", "overall_objective_bias")

test_grid <- expand.grid(bias_col = bias_types, metric = metrics, stringsAsFactors = FALSE)
t_test_results <- pmap_dfr(test_grid, ~ run_t_tests(delib_parsed, ..1, ..2))


###
t_test_labels <- t_test_results %>%
  mutate(
    bias_type = recode(bias_type,
                       "overall_subjective_bias" = "Subjective Bias",
                       "overall_objective_bias" = "Objective Bias"),
    metric = recode(metric,
                    "like_count" = "Likes",
                    "reply_count" = "Replies",
                    "retweet_count" = "Retweets"),
    sig_label = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      TRUE            ~ ""
    )
  ) %>%
  select(bias_type, metric, sig_label)

label_positions <- engagement_summary %>%
  group_by(bias_type, engagement_type) %>%
  summarise(y = max(mean_count + se_count, na.rm = TRUE) * 1.5, .groups = "drop") %>%
  left_join(t_test_labels, by = c("bias_type", "engagement_type" = "metric"))


engagement_summary$bias_type <- factor(engagement_summary$bias_type, 
                                       levels = c("Subjective Bias", "Objective Bias"))


ggplot(engagement_summary, aes(x = engagement_type, y = mean_count + 1, color = bias_label)) +
  geom_pointrange(
    aes(
      ymin = mean_count + 1 - se_count,
      ymax = mean_count + 1 + se_count
    ),
    position = position_dodge(width = 0.5),
    size = 0.7,
    fatten = 3  # controls dot size relative to line
  ) +
  scale_y_log10(labels = scales::comma_format(accuracy = 1)) +
  scale_color_manual(
    values = c("Biased" = "#f8766d", "Not Biased" = "#00bfc4"),
    name = "Bias"
  ) +
  facet_wrap(~ bias_type) +
  labs(
    title = "Log-Scaled Mean Engagement by Bias Type",
    x = "Engagement Metric",
    y = "Mean Engagement (log scale)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA, size = 1),
    panel.grid.minor.y = element_blank(),
    strip.background = element_rect(fill = "white", color = "black", size = 0.5),
    strip.text = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  )+ geom_text(
    data = label_positions,
    aes(x = engagement_type, y = y, label = sig_label),
    inherit.aes = FALSE,
    size = 5,
    fontface = "bold"
  )


