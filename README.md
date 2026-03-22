# MediaSpin

**MediaSpin: A Dataset of Post-Publication News Headline Edits Annotated for Media Bias **

A large-scale language resource capturing how major news outlets modify headlines after publication, annotated with 13 types of media bias. Includes **MediaSpin-in-the-Wild**, a companion dataset linking revised headlines to downstream engagement on X (Twitter).

Please cite us!:
@inproceedings{vermajaidka2026mediaspin,
  author    = {Preetika Verma and Kokil Jaidka},
  title     = {The MediaSpin Dataset: Post-Publication News Headline Edits Annotated for Media Bias},
  booktitle = {Proceedings of the International AAAI Conference on Web and Social Media},
  year      = {2026},
  note      = {Accepted to ICWSM 2026}
}

## Dataset

- **78,910 headline pairs** (original + edited) from 5 English-language outlets
- **13 bias categories**: spin, unsubstantiated claims, opinion-as-fact, sensationalism, mudslinging, mind reading, slant, flawed logic, omission, omission of source attribution, story choice/placement, subjective adjectives, word choice
- **180,786 news-related tweets** from 819 consenting users (MediaSpin-in-the-Wild)

**Download:** [MediaSpin Dataset](https://anonymous.4open.science/r/mediaspin-A5C7)

### Outlets

| Outlet | Edited Headline Pairs |
|---|---|
| Washington Post | 30,605 |
| Reuters | 15,925 |
| New York Times | 13,066 |
| Fox News | 250 |
| Rebel News | 62 |

## Repository Structure

```
mediaspin/
├── annotation/                     # Step 1: Annotation pipeline
│   ├── cleaning.ipynb              # Text cleaning (deEmojify, remove HTML/links)
│   ├── annotation_creating_prompts.ipynb  # Generate prompts from headline pairs
│   ├── data_annotation.ipynb       # Run GPT-3.5-turbo annotation
│   └── annotation_processing_pipeline.ipynb  # Parse responses into bias labels
│
├── geographic/                     # Step 2: Geographic analysis
│   ├── process_places.py           # Extract places via spaCy NER
│   ├── process_words.py            # POS tagging and word frequencies
│   ├── place_dist.R                # Tabulate unique place names
│   ├── place_to_country.py         # Geocode places via OSM Nominatim
│   ├── check_places.py             # Validate place-country consistency
│   ├── check_countries.py          # Third-pass country merge
│   └── heatmap.R                   # Country heatmap figure (Figure 2)
│
├── analysis/                       # Step 3: Classification and coding
│   ├── subjective_objective_coding.R  # Compute binary subjective/objective flags
│   └── checking_coding.R           # Clean inconsistent country annotations
│
├── mediaspin-in-the-wild/          # Step 4: Engagement analysis
│   ├── match_public.py             # Fuzzy-match headlines to tweets (rapidfuzz)
│   ├── match_to_metric.R           # String-distance matching (R version)
│   └── engagement_figure.R         # Engagement figure (Figure 3)
│
└── README.md
```

## Pipeline Overview

### 1. Annotation

Run the notebooks in order:

1. **`cleaning.ipynb`** — Clean raw headline text (remove HTML, emojis, links)
2. **`annotation_creating_prompts.ipynb`** — Generate structured prompts from headline edit pairs, computing word-level diffs
3. **`data_annotation.ipynb`** — Send prompts to GPT-3.5-turbo for bias annotation using the 13-category AllSides-based taxonomy
4. **`annotation_processing_pipeline.ipynb`** — Parse GPT responses into structured columns (one per bias type, with Added/Removed/None labels)

### 2. Geographic Analysis

Extract place and country references from headlines to analyze representational dynamics:

1. **`process_places.py`** — Extract place entities from added/removed words using spaCy
2. **`place_dist.R`** — Tabulate place frequencies and filter noise
3. **`place_to_country.py`** — Geocode places to countries using OpenStreetMap Nominatim
4. **`check_places.py`** — Flag and clean inconsistent place-country mappings
5. **`check_countries.py`** — Third-pass merge to fill gaps in country detection
6. **`heatmap.R`** — Generate the country heatmap (Figure 2) with frequency-weighted scores

### 3. Classification

- **`subjective_objective_coding.R`** — Aggregate the 13 bias categories into binary subjective/objective flags
- **`checking_coding.R`** — Apply cleaned country annotations

### 4. Engagement Analysis (MediaSpin-in-the-Wild)

1. **`match_public.py`** — Fuzzy-match edited headlines to news mentions in user timelines using rapidfuzz (threshold: 70% similarity)
2. **`match_to_metric.R`** — Alternative matching using Levenshtein distance in R
3. **`engagement_figure.R`** — Generate the engagement comparison figure (Figure 3), including t-tests for significance

## Bias Taxonomy

The 13 bias categories are divided into two groups:

**Subjective bias** (linguistic/evaluative):
- Spin, Sensationalism, Mudslinging, Mind Reading, Opinion-as-Fact, Subjective Adjectives, Word Choice

**Objective bias** (structural/evidentiary):
- Unsubstantiated Claims, Slant, Flawed Logic, Omission, Omission of Source Attribution, Story Choice/Placement

## Requirements

### Python
```
pandas, spacy, pycountry, geonamescache, geopy, rapidfuzz, nltk, openai, tqdm
```

```bash
python -m spacy download en_core_web_sm
```

### R
```
dplyr, tidyr, ggplot2, stringr, scales, countrycode, stringdist, broom, purrr, rlang
```

## Citation

If you use MediaSpin in your research, please cite:

```
@inproceedings{verma2026mediaspin,
  title={MediaSpin: Exploring Media Bias Through Fine-Grained Analysis of News Headlines},
  author={Verma, Preetika and Jaidka, Kokil},
  booktitle={Proceedings of the AAAI Conference on Artificial Intelligence},
  year={2026}
}
```

## License

For research use. See dataset documentation for ethical use guidelines.
