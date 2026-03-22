# -*- coding: utf-8 -*-
"""
Third-pass country merge: re-detect countries from places and merge
with existing country annotations to fill gaps.

Input:  final_dataset_oct2025_checked.csv
Output: final_dataset_oct2025_final.csv
"""

import pandas as pd
import spacy
import pycountry
import geonamescache
import re

nlp = spacy.load("en_core_web_sm", disable=["parser"])

def _norm(s: str) -> str:
    return re.sub(r"[^\w\s]", "", s).strip().lower()

gc = geonamescache.GeonamesCache()
countries_data = gc.get_countries()
cities_data = gc.get_cities()

alias_map = {
    "us": "United States", "usa": "United States", "america": "United States",
    "uk": "United Kingdom", "britain": "United Kingdom", "england": "United Kingdom",
    "scotland": "United Kingdom", "catalan": "Spain", "catalonia": "Spain",
    "eu": "European Union", "uae": "United Arab Emirates", "russia": "Russia",
    "serbia": "Serbia", "armenia": "Armenia", "kenya": "Kenya",
    "ecuador": "Ecuador", "north korea": "North Korea", "guinea": "Guinea",
    "canada": "Canada",
}

country_names = {c.name for c in pycountry.countries}
country_names |= {getattr(c, "common_name", "") for c in pycountry.countries}
country_names |= {c.alpha_2 for c in pycountry.countries}
country_names |= {c.alpha_3 for c in pycountry.countries}
country_names = {n.strip() for n in country_names if n}

city_to_country = {}
for cityid, cityinfo in cities_data.items():
    name = cityinfo["name"]
    country_code = cityinfo["countrycode"]
    country_name = countries_data.get(country_code, {}).get("name")
    if country_name:
        city_to_country[name.lower()] = country_name

# Update paths to match your environment
input_path  = r"C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/final_dataset_oct2025_checked.csv"
output_path = r"C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/final_dataset_oct2025_final.csv"

df = pd.read_csv(input_path, encoding="utf-8-sig")
pairs = ["original", "edited", "added", "removed"]


def detect_countries(text: str, places=None):
    """Return list of country names detected from spaCy places + raw text."""
    places = places or []
    detected = set()
    for p in places:
        n = _norm(p)
        if n.title() in country_names:
            detected.add(n.title())
        elif n in city_to_country:
            detected.add(city_to_country[n])
        elif n in alias_map:
            detected.add(alias_map[n])
    for token in text.split():
        n = _norm(token)
        if n in city_to_country:
            detected.add(city_to_country[n])
        elif n.title() in country_names:
            detected.add(n.title())
        elif n in alias_map:
            detected.add(alias_map[n])
    raw_norm = _norm(text)
    for k, v in alias_map.items():
        if k in raw_norm:
            detected.add(v)
    return sorted(detected)


def merge_detected_countries(places, countries):
    """Append missing detected countries without overwriting existing ones."""
    detected = []
    if isinstance(places, str) and places.strip():
        detected = detect_countries(places)
    existing = [c.strip() for c in str(countries).split(",")
                if isinstance(countries, str) and c.strip()]
    merged = sorted(set(existing + detected))
    return ", ".join(merged) if merged else None


for prefix in pairs:
    pcol, ccol = f"{prefix}_places", f"{prefix}_countries"
    print(f"Processing {pcol} -> {ccol}...")
    df[ccol] = df.apply(lambda r: merge_detected_countries(r[pcol], r[ccol]), axis=1)

df.to_csv(output_path, index=False, encoding="utf-8-sig")
print(f"Third-pass merge complete. Saved to: {output_path}")
