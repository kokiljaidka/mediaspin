# -*- coding: utf-8 -*-
"""
Validate place-country consistency: flag and clean cases where the
resolved country name does not appear in the original place text.

Input:  final_dataset_oct2025.csv
Output: final_dataset_oct2025_checked.csv (with *_inconsistent flags and *_countries_clean)
"""

import pandas as pd
import re

pairs = ["original", "edited", "added", "removed"]

# Update path to match your environment
final_dataset = pd.read_csv(
    "C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/final_dataset_oct2025.csv"
)


def inconsistent_country(place_text, country_text):
    """Return list of inconsistent country names (those not referenced in place text)."""
    if not isinstance(country_text, str) or not country_text.strip():
        return []
    if not isinstance(place_text, str):
        place_text = ""
    place_text = place_text.lower()
    countries = [c.strip() for c in country_text.split(",") if c.strip()]
    inconsistent = []
    for c in countries:
        cname = c.lower()
        if not re.search(rf"\b{re.escape(cname)}\b", place_text):
            inconsistent.append(c)
    return inconsistent


for prefix in pairs:
    pcol, ccol = f"{prefix}_places", f"{prefix}_countries"
    flag_col = f"{prefix}_inconsistent"
    cleaned_col = f"{prefix}_countries_clean"

    inconsistencies = []
    cleaned = []

    for place, country in zip(final_dataset[pcol], final_dataset[ccol]):
        bad = inconsistent_country(place, country)
        inconsistencies.append(bool(bad))
        if not bad:
            cleaned.append(country)
        else:
            current = [c.strip() for c in str(country).split(",") if c.strip()]
            remaining = [c for c in current if c not in bad]
            cleaned.append(", ".join(remaining) if remaining else None)

    final_dataset[flag_col] = inconsistencies
    final_dataset[cleaned_col] = cleaned
    print(f"{prefix}: {sum(inconsistencies)} inconsistencies flagged.")

output_path = "C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/final_dataset_oct2025_checked.csv"
final_dataset.to_csv(output_path, index=False, encoding="utf-8-sig")
print(f"Cleaned dataset saved to: {output_path}")
