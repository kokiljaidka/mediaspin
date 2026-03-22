# -*- coding: utf-8 -*-
"""
Generate a place-to-country lookup using OpenStreetMap Nominatim geocoding.

Input:  places_mentioned.csv (unique place names extracted from headlines)
Output: place_country_lookup_osm.csv

Requires: geopy
"""

from geopy.geocoders import Nominatim
import pandas as pd
import time

geolocator = Nominatim(user_agent="place_country_mapper")


def get_country(place):
    """Return country name for a given place using OpenStreetMap."""
    try:
        location = geolocator.geocode(place, language="en", addressdetails=True, timeout=10)
        if location and "country" in location.raw["address"]:
            return location.raw["address"]["country"]
    except Exception as e:
        print(f"[WARN] {place}: {e}")
    return None


# Update paths to match your environment
PATH = r"C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/"
df = pd.read_csv(PATH + "places_mentioned.csv")
df["country_osm"] = None

for i, row in df.iterrows():
    df.loc[i, "country_osm"] = get_country(row["place"])
    if i % 50 == 0:
        print(f"{i}/{len(df)} processed...")
    time.sleep(1.0)  # Respect rate limits

df.to_csv(PATH + "place_country_lookup_osm.csv", index=False, encoding="utf-8-sig")
print("Saved with OSM geocoded countries.")
