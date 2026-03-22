# -*- coding: utf-8 -*-
"""
Extract place names from headline words using spaCy NER and map them to countries.

Input:  final_dataset.csv (with 'added_words' / 'removed_words' columns)
Output: final_dataset_with_places_{added,removed}words.csv

Requires: spacy (en_core_web_sm), pycountry, geonamescache
"""

import pandas as pd
import spacy
import pycountry
import geonamescache
from tqdm import tqdm
import csv
import re

# --- Load spaCy model ---
nlp = spacy.load("en_core_web_sm", disable=["parser"])

# --- Configuration ---
# Update these paths to match your environment
PATH = r"C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/"
input_file = PATH + "final_dataset.csv"
output_file = PATH + "final_dataset_with_places_removedwords.csv"

df_iter = pd.read_csv(input_file, chunksize=500)

# --- Build a comprehensive set of known country names and variants ---
country_names = {c.name for c in pycountry.countries}
country_names |= {getattr(c, "common_name", "") for c in pycountry.countries}
country_names |= {c.alpha_2 for c in pycountry.countries}
country_names |= {c.alpha_3 for c in pycountry.countries}
country_names = {n.strip() for n in country_names if n}

alias_map = {
    "us": "United States",
    "usa": "United States",
    "america": "United States",
    "uk": "United Kingdom",
    "britain": "United Kingdom",
    "england": "United Kingdom",
    "scotland": "United Kingdom",
    "catalan": "Spain",
    "catalonia": "Spain",
    "eu": "European Union",
    "uae": "United Arab Emirates",
    "russia": "Russia",
    "serbia": "Serbia",
    "armenia": "Armenia",
    "kenya": "Kenya",
    "ecuador": "Ecuador",
    "north korea": "North Korea",
    "guinea": "Guinea",
    "canada": "Canada",
}

def _norm(s: str) -> str:
    return re.sub(r"[^\w\s]", "", s).strip().lower()

# --- Build city->country mapping using geonamescache ---
gc = geonamescache.GeonamesCache()
countries_data = gc.get_countries()
cities_data = gc.get_cities()

city_to_country = {}
for cityid, cityinfo in cities_data.items():
    name = cityinfo["name"]
    country_code = cityinfo["countrycode"]
    country_name = countries_data.get(country_code, {}).get("name")
    if country_name:
        city_to_country[name.lower()] = country_name


def detect_countries(text: str, places=None):
    """Return list of country names detected from spaCy places + raw text."""
    places = places or []
    detected = set()

    # Pass 1: from spaCy entities
    for p in places:
        n = _norm(p)
        if n.title() in country_names:
            detected.add(n.title())
        elif n in city_to_country:
            detected.add(city_to_country[n])
        elif n in alias_map:
            detected.add(alias_map[n])

    # Pass 2: from raw text tokens
    for token in text.split():
        n = _norm(token)
        if n in city_to_country:
            detected.add(city_to_country[n])
        elif n.title() in country_names:
            detected.add(n.title())
        elif n in alias_map:
            detected.add(alias_map[n])

    # Pass 3: catch multi-word aliases
    raw_norm = _norm(text)
    for k, v in alias_map.items():
        if k in raw_norm:
            detected.add(v)

    return sorted(detected)


# --- Write header ---
with open(output_file, "w", newline="", encoding="utf-8") as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["removed_words", "places_mentioned", "countries_mentioned"])

# --- Process and write chunk by chunk ---
for chunk in tqdm(df_iter, desc="Processing chunks"):
    chunk = chunk.fillna("")
    results = []

    for text in chunk["removed_words"]:
        doc = nlp(text)
        places = [ent.text for ent in doc.ents if ent.label_ in ("GPE", "LOC", "FAC")]
        countries = detect_countries(text, places)
        results.append([text, ", ".join(places), ", ".join(countries)])

    with open(output_file, "a", newline="", encoding="utf-8") as f_out:
        writer = csv.writer(f_out)
        writer.writerows(results)

print("Done. Results written to", output_file)
