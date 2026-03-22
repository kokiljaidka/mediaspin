# MediaSpin

**MediaSpin: A Dataset of Post-Publication News Headline Edits Annotated for Media Bias **

A large-scale language resource capturing how major news outlets modify headlines after publication, annotated with 13 types of media bias. Includes **MediaSpin-in-the-Wild**, a companion dataset linking revised headlines to downstream engagement on X (Twitter).


## Dataset

- **78,910 headline pairs** (original + edited) from 5 English-language outlets
- **13 bias categories**: spin, unsubstantiated claims, opinion-as-fact, sensationalism, mudslinging, mind reading, slant, flawed logic, omission, omission of source attribution, story choice/placement, subjective adjectives, word choice
- **180,786 news-related tweets** from 819 consenting users (MediaSpin-in-the-Wild)

**Download:** [MediaSpin Dataset (Harvard Dataverse)](https://doi.org/10.7910/DVN/MOCQTZ)


## Citation

If you use MediaSpin in your research, please cite:

```
@inproceedings{vermajaidka2026mediaspin,
  author    = {Preetika Verma and Kokil Jaidka},
  title     = {The MediaSpin Dataset: Post-Publication News Headline Edits Annotated for Media Bias},
  booktitle = {Proceedings of the International AAAI Conference on Web and Social Media},
  year      = {2026},
  note      = {Accepted to ICWSM 2026}
}
```

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
│   └── mediaspinv2.R               # Engagement figure (Figure 3)
│
├── python/                         # Python annotation package
│   ├── mediaspin/
│   │   ├── __init__.py
│   │   ├── annotate.py             # annotate_bias(), annotate_batch()
│   │   └── prompt.py               # Exact prompt from Figure 1
│   ├── pyproject.toml
│   └── README.md
│
├── R/                              # R annotation package
│   ├── R/
│   │   ├── annotate.R              # annotate_bias(), annotate_batch()
│   │   ├── parse.R                 # parse_bias_response()
│   │   └── prompt.R                # mediaspin_prompt()
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   └── README.md
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

## Annotation Packages

We provide standalone packages in Python and R that wrap the MediaSpin annotation pipeline. Both use the exact prompt from Figure 1 of the paper and require your own OpenAI API key.

### Python

```bash
cd python && pip install -e .
```

```python
from mediaspin import annotate_bias

result = annotate_bias(
    original="Asia hit by Wall St's tumble",
    edited="Savaged global stocks head for worst week since 2011",
    api_key="sk-..."
)
result["bias_analysis"]["Bias by Omission"]  # {"value": "Added", "reason": "..."}
```

### R

```r
devtools::install_local("R/")
library(mediaspin)

result <- annotate_bias(
    original = "Asia hit by Wall St's tumble",
    edited = "Savaged global stocks head for worst week since 2011"
)
result[["Bias by Omission"]]$value  # "Added"
```

See [`python/README.md`](python/README.md) and [`R/README.md`](R/README.md) for full documentation.

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

## License

For research use. See dataset documentation for ethical use guidelines.
