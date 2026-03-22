# -*- coding: utf-8 -*-
"""
Row-by-row POS tagging and word frequency extraction for added/removed words.

Input:  final_dataset.csv (with 'added_words' / 'removed_words' columns)
Output: word_frequencies_added_pos.csv, word_frequencies_removed_pos.csv

Requires: spacy (en_core_web_sm), nltk
"""

import pandas as pd
import spacy
from collections import Counter
from nltk.corpus import stopwords
import nltk
import string
import csv

# --- Setup ---
nltk.download('stopwords', quiet=True)
stop_words = set(stopwords.words('english'))

nlp = spacy.load("en_core_web_sm", disable=["ner", "parser"])
nlp.max_length = 2_000_000

# --- File paths (update to match your environment) ---
PATH = r"C:/Users/cnmkj/Documents/00 DATA/2025 mediaspin/"
input_file = PATH + "final_dataset.csv"
output_added = PATH + "word_frequencies_added_pos.csv"
output_removed = PATH + "word_frequencies_removed_pos.csv"

# --- Write headers ---
with open(output_added, "w", newline="", encoding="utf-8") as f1, \
     open(output_removed, "w", newline="", encoding="utf-8") as f2:
    csv.writer(f1).writerow(["row_id", "word", "POS", "count", "type"])
    csv.writer(f2).writerow(["row_id", "word", "POS", "count", "type"])


def process_text(text, label):
    """Return a list of (word, POS, count, label) tuples for one row."""
    if not isinstance(text, str) or not text.strip():
        return []
    words = [w.strip() for w in text.split(",") if w.strip()]
    words = [w for w in words if w.lower() not in stop_words and w not in string.punctuation]
    if not words:
        return []
    pos_counts = Counter()
    doc = nlp(" ".join(words))
    for token in doc:
        if token.text.lower() not in stop_words and token.is_alpha:
            pos_counts[(token.lemma_.lower(), token.pos_)] += 1
    return [(w, p, c, label) for (w, p), c in pos_counts.items()]


# --- Process row by row ---
chunksize = 500
reader = pd.read_csv(input_file, dtype=str, chunksize=chunksize, low_memory=False)

row_index = 0
for chunk in reader:
    chunk = chunk.fillna("")
    results_added, results_removed = [], []

    for _, row in chunk.iterrows():
        added = process_text(row.get("added_words", ""), "added")
        removed = process_text(row.get("removed_words", ""), "removed")

        for w, p, c, label in added:
            results_added.append([row_index, w, p, c, label])
        for w, p, c, label in removed:
            results_removed.append([row_index, w, p, c, label])

        row_index += 1

    with open(output_added, "a", newline="", encoding="utf-8") as f1:
        csv.writer(f1).writerows(results_added)
    with open(output_removed, "a", newline="", encoding="utf-8") as f2:
        csv.writer(f2).writerows(results_removed)

print("Done. POS frequency files saved.")
