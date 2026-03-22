# Extract and tabulate unique place names from headline columns
#
# Input:  final_dataset_oct2025_checked.csv
# Output: places_mentioned.csv

# Update path to match your environment
final_dataset <- read.csv(
  "C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/final_dataset_oct2025_checked.csv",
  encoding = "UTF-8", stringsAsFactors = FALSE
)

places_cols <- grep("_places$", names(final_dataset), value = TRUE)

all_places <- unlist(strsplit(paste(final_dataset[, places_cols], collapse = ","), ","))
all_places <- trimws(all_places)
all_places <- all_places[all_places != "" & !is.na(all_places)]

place_freq <- sort(table(tolower(all_places)), decreasing = TRUE)
place_freq_df <- as.data.frame(place_freq)
colnames(place_freq_df) <- c("place", "frequency")

# Filter noise
noise_terms <- c("city", "town", "region", "area", "village", "state", "province",
                 "district", "north", "south", "east", "west", "downtown", "local")
place_freq_clean <- subset(place_freq_df,
  !grepl(paste(noise_terms, collapse = "|"), place, ignore.case = TRUE))

known_countries <- c("russia", "ukraine", "china", "india", "united states",
                     "uk", "usa", "us", "turkey")
place_freq_clean$has_country_hint <- grepl(
  paste(known_countries, collapse = "|"), place_freq_clean$place, ignore.case = TRUE)

write.csv(place_freq_clean,
  "C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/places_mentioned.csv",
  row.names = FALSE)
