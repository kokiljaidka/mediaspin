# Country-level heatmap of added vs removed country references
#
# Input:  final_dataset_with_countries-finals.csv
# Output: heatmap figure (map.pdf) and top-country tables
#
# Requires: dplyr, tidyr, ggplot2, countrycode, scales

library(dplyr)
library(tidyr)
library(ggplot2)
library(countrycode)
library(stringr)
library(scales)

# --- 1. Helper: parse list-like strings to vectors ---
parse_list <- function(x) {
  x <- gsub("\\[|\\]|'", "", x)
  x <- trimws(unlist(strsplit(x, ",")))
  x <- x[x != ""]
  return(x)
}

# --- 2. Expand added and removed countries into long format ---
added <- final_dataset_with_countries_finals %>%
  mutate(countries = lapply(added_countries, parse_list)) %>%
  select(countries) %>%
  unnest(countries) %>%
  filter(countries != "") %>%
  mutate(type = "added")

removed <- final_dataset_with_countries_finals %>%
  mutate(countries = lapply(removed_countries, parse_list)) %>%
  select(countries) %>%
  unnest(countries) %>%
  filter(countries != "") %>%
  mutate(type = "removed")

combined <- bind_rows(added, removed)

# --- 3. Count occurrences ---
country_counts <- combined %>%
  count(countries, type) %>%
  pivot_wider(names_from = type, values_from = n, values_fill = 0) %>%
  mutate(
    total = added + removed,
    score_raw = (added - removed),
    score_norm = ifelse(total > 0, score_raw / total, 0)
  )

# Frequency-weighted score
country_counts <- country_counts %>%
  mutate(
    score_freq_weighted = (added - removed) * log1p(total),
    score_freq_norm = score_freq_weighted / max(abs(score_freq_weighted), na.rm = TRUE)
  )

# --- 4. Map to ISO3 and world polygons ---
world <- map_data("world") %>%
  mutate(iso3 = countrycode(region, "country.name", "iso3c"))

country_counts <- country_counts %>%
  mutate(iso3 = countrycode(countries, "country.name", "iso3c"))

# Build universe of ALL countries ever mentioned
all_mentioned <- bind_rows(
  final_dataset_with_countries_finals %>%
    mutate(countries = lapply(original_countries, parse_list)) %>%
    select(countries) %>% unnest(countries),
  final_dataset_with_countries_finals %>%
    mutate(countries = lapply(edited_countries, parse_list)) %>%
    select(countries) %>% unnest(countries)
) %>%
  filter(countries != "") %>%
  distinct(countries) %>%
  mutate(iso3 = countrycode(countries, "country.name", "iso3c")) %>%
  filter(!is.na(iso3))

mentioned_not_edited <- all_mentioned %>%
  filter(!iso3 %in% country_counts$iso3)

plot_data <- left_join(world, country_counts, by = "iso3")

# Three-way classification: scored / mentioned / absent
plot_data <- plot_data %>%
  mutate(
    in_corpus = iso3 %in% all_mentioned$iso3,
    fill_category = case_when(
      !is.na(score_freq_weighted) ~ "scored",
      in_corpus ~ "mentioned",
      TRUE ~ "absent"
    ),
    score_freq_norm = case_when(
      fill_category == "scored" ~ score_freq_norm,
      fill_category == "mentioned" ~ 0,
      TRUE ~ NA_real_
    )
  )

# --- 5. Plot heatmap ---
ggplot() +
  geom_polygon(
    data = plot_data %>% filter(fill_category == "absent"),
    aes(long, lat, group = group),
    fill = "#d0d0d0", color = "gray60", linewidth = 0.15
  ) +
  geom_polygon(
    data = plot_data %>% filter(fill_category != "absent"),
    aes(long, lat, group = group, fill = score_freq_norm),
    color = "gray80", linewidth = 0.15
  ) +
  scale_fill_gradientn(
    colours = c("#67000d", "#de2d26", "#fb6a4a", "#fcae91",
                "white", "#e5f5e0", "#a1d99b", "#31a354", "#006400"),
    values = scales::rescale(c(-0.75, -0.5, -0.2, -0.01, 0, 0.05, 0.25, 0.5, 1)),
    limits = c(-0.75, 1),
    oob = scales::squish,
    na.value = "#d0d0d0",
    name = "Weighted Added vs Removed",
    guide = guide_colorbar(
      barwidth = unit(4, "in"), barheight = unit(0.25, "in"),
      title.position = "top", title.hjust = 0.5
    )
  ) +
  theme_void(base_size = 12) +
  coord_equal() +
  labs(
    title = "Country Likelihood: Added vs Removed (Weighted)",
    subtitle = "Green = more often added. Red = more often removed.\nWhite = mentioned but not edited. Gray = never mentioned."
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray20"),
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 9),
    plot.margin = margin(10, 10, 10, 10)
  )

# --- 6. Top countries tables ---
top_added <- country_counts %>%
  filter(!countries %in% c("Asia")) %>%
  arrange(desc(score_freq_norm)) %>%
  slice_head(n = 5) %>%
  transmute(Category = "Added", Country = countries,
            Added = added, Removed = removed, Total = total,
            Weighted_Score = round(score_freq_norm, 3))

top_removed <- country_counts %>%
  filter(!countries %in% c("Asia")) %>%
  arrange(score_freq_norm) %>%
  slice_head(n = 5) %>%
  transmute(Category = "Removed", Country = countries,
            Added = added, Removed = removed, Total = total,
            Weighted_Score = round(score_freq_norm, 3))

only_removed <- country_counts %>%
  filter(added == 0, removed > 0) %>%
  arrange(desc(removed)) %>%
  select(countries, added, removed, total, score_freq_norm)

never_edited <- all_mentioned %>%
  filter(!iso3 %in% country_counts$iso3) %>%
  arrange(countries)

cat("Top added:\n"); print(top_added)
cat("\nTop removed:\n"); print(top_removed)
cat("\nOnly ever removed:\n"); print(only_removed)
cat("\nMentioned but never edited:\n"); print(never_edited$countries)
