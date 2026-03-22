# -*- coding: utf-8 -*-
"""
Fuzzy-match edited headlines to news mentions in user timelines.

Input:  mentionsdf.csv (tweet texts + public_metrics)
        headlinesdf.csv (edited headlines + bias labels)
Output: matched_headlines_with_bias.csv

Requires: rapidfuzz, pandas, tqdm
"""

import pandas as pd
from rapidfuzz import process, fuzz
from tqdm import tqdm

# Update paths to match your environment
mentions_df = pd.read_csv("mentionsdf.csv")
headlines_df = pd.read_csv("headlinesdf.csv")

results = []

for idx, headline_row in tqdm(headlines_df.iterrows(), total=headlines_df.shape[0]):
    headline = headline_row['edited_headline']

    all_matches = process.extract(
        headline,
        mentions_df['text'],
        scorer=fuzz.QRatio,
        limit=None
    )

    for match_text, score, match_index in all_matches:
        if score >= 70:
            matched_row = mentions_df.iloc[match_index]
            results.append({
                'headline': headline,
                'matched_mention': matched_row['text'],
                'public_metrics': matched_row['public_metrics'],
                'match_score': score,
                'overall_objective_bias': headline_row['overall_objective_bias'],
                'overall_subjective_bias': headline_row['overall_subjective_bias']
            })

results_df = pd.DataFrame(results)
results_df.to_csv("matched_headlines_with_bias.csv", index=False)
print(f"Matched {len(results_df)} headline-mention pairs.")
