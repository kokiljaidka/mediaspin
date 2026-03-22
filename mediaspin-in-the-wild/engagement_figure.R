# Engagement figure for MediaSpin-in-the-Wild (Figure 3 in paper)
#
# Compares mean likes, replies, and retweets for biased vs unbiased tweets,
# faceted by subjective and objective bias.
#
# Input:  delib (with bias columns and public_metrics)
# Output: mediaspinv2.pdf / mediaspinv2.png

library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(purrr)
library(broom)
library(rlang)
library(stringr)

# ── 0. Setup: define bias columns and parse metrics ──────────────

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

delib <- delib %>%
  mutate(
    overall_subjective_bias = if_else(
      rowSums(select(., all_of(subjective_bias_cols)) == 1, na.rm = TRUE) > 0, 1, 0),
    overall_objective_bias = if_else(
      rowSums(select(., all_of(objective_bias_cols)) == 1, na.rm = TRUE) > 0, 1, 0)
  )

delib_parsed <- delib %>%
  mutate(
    retweet_count = as.numeric(str_extract(public_metrics, "(?<=retweet_count': )\\d+")),
    reply_count   = as.numeric(str_extract(public_metrics, "(?<=reply_count': )\\d+")),
    like_count    = as.numeric(str_extract(public_metrics, "(?<=like_count': )\\d+"))
  )

# ── 1. Compute engagement summaries ─────────────────────────────

make_summary <- function(df, bias_col, bias_label) {
  df %>%
    mutate(bias_label = ifelse(!!sym(bias_col) == 1, "Biased", "Not Biased")) %>%
    pivot_longer(cols = c(like_count, reply_count, retweet_count),
                 names_to = "engagement_type", values_to = "count") %>%
    group_by(bias_label, engagement_type) %>%
    summarise(
      mean_count = mean(count, na.rm = TRUE),
      se_count   = sd(count, na.rm = TRUE) / sqrt(n()),
      ci95       = 1.96 * sd(count, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(bias_type = bias_label)
}

engagement_summary <- bind_rows(
  make_summary(delib_parsed, "overall_subjective_bias", "Subjective Bias"),
  make_summary(delib_parsed, "overall_objective_bias", "Objective Bias")
) %>%
  mutate(
    engagement_type = factor(engagement_type,
      levels = c("like_count", "reply_count", "retweet_count"),
      labels = c("Likes", "Replies", "Retweets")),
    bias_type = factor(bias_type, levels = c("Subjective Bias", "Objective Bias"))
  )

# ── 2. T-tests for significance labels ──────────────────────────

run_t_test <- function(df, bias_col, metric) {
  t.test(pull(df, !!sym(metric)) ~ pull(df, !!sym(bias_col))) %>%
    tidy() %>%
    mutate(metric = metric, bias_type = bias_col)
}

test_grid <- expand.grid(
  bias_col = c("overall_subjective_bias", "overall_objective_bias"),
  metric   = c("like_count", "reply_count", "retweet_count"),
  stringsAsFactors = FALSE
)

t_test_results <- pmap_dfr(test_grid, ~ run_t_test(delib_parsed, ..1, ..2)) %>%
  mutate(
    bias_type = recode(bias_type,
      "overall_subjective_bias" = "Subjective Bias",
      "overall_objective_bias"  = "Objective Bias"),
    metric = recode(metric,
      "like_count" = "Likes", "reply_count" = "Replies", "retweet_count" = "Retweets"),
    sig_label = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01  ~ "**",
      p.value < 0.05  ~ "*",
      TRUE            ~ ""
    )
  )

# Position labels centered above each engagement metric group
label_positions <- engagement_summary %>%
  group_by(bias_type, engagement_type) %>%
  summarise(y = max(mean_count + ci95, na.rm = TRUE) * 1.8 + 1, .groups = "drop") %>%
  left_join(t_test_results %>% select(bias_type, metric, sig_label),
            by = c("bias_type", "engagement_type" = "metric"))

# ── 3. Plot ──────────────────────────────────────────────────────

p <- ggplot(engagement_summary,
       aes(x = engagement_type, y = mean_count + 1, color = bias_label)) +
  geom_pointrange(
    aes(ymin = pmax(mean_count + 1 - ci95, 0.5),
        ymax = mean_count + 1 + ci95),
    position = position_dodge(width = 0.45),
    size = 0.6, fatten = 3.5, linewidth = 0.8
  ) +
  geom_text(
    data = label_positions,
    aes(x = engagement_type, y = y, label = sig_label),
    inherit.aes = FALSE,
    size = 4.5, fontface = "bold", color = "grey30"
  ) +
  scale_y_log10(
    labels = label_number(accuracy = 1),
    breaks = c(1, 2, 5, 10, 20, 50, 100, 500, 1000, 5000)
  ) +
  scale_color_manual(
    values = c("Biased" = "#c0392b", "Not Biased" = "#2471a3"),
    name = NULL
  ) +
  facet_wrap(~ bias_type) +
  labs(
    x = NULL,
    y = "Mean Engagement (log scale)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 11),
    panel.border = element_rect(color = "grey70", fill = NA, linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.background = element_rect(fill = "grey95", color = "grey70", linewidth = 0.5),
    strip.text = element_text(face = "bold", size = 12),
    axis.text = element_text(color = "black", size = 10),
    axis.title.y = element_text(size = 11),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("mediaspinv2.pdf", p, width = 7, height = 4, device = cairo_pdf)
ggsave("mediaspinv2.png", p, width = 7, height = 4, dpi = 300)

cat("Figure saved.\n")
