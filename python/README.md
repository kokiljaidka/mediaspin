# mediaspin

Annotation pipeline for detecting 13 types of media bias in news headline edits, powered by OpenAI LLMs.

## Installation

```bash
pip install -e .
```

Or install directly from the source directory:

```bash
pip install .
```

## Usage

### Single headline pair

```python
from mediaspin import annotate_bias

result = annotate_bias(
    original="Protesters gather outside city hall",
    edited="Rioters storm city hall",
    api_key="sk-...",          # or set OPENAI_API_KEY env var
    model="gpt-3.5-turbo",    # default
)

# Structured output
for bias_type, info in result["bias_analysis"].items():
    print(f"{bias_type}: {info['value']} — {info['reason']}")
```

The `added_words` and `removed_words` arguments are optional. If omitted, they are computed automatically by diffing the two headlines at the word level.

### Batch annotation

```python
from mediaspin import annotate_batch

pairs = [
    ("Economy shows steady growth", "Economy shows alarming growth"),
    ("Senator speaks at rally", "Corrupt senator speaks at rally"),
]

results = annotate_batch(pairs, api_key="sk-...")
```

### Parsing a raw response

If you already have the raw text output from the LLM, you can parse it directly:

```python
from mediaspin import parse_response

structured = parse_response(raw_text)
print(structured["bias_analysis"])
```

### Inspecting the prompt and bias types

```python
from mediaspin import SYSTEM_PROMPT, BIAS_TYPES

print(BIAS_TYPES)       # list of 13 bias type names
print(SYSTEM_PROMPT)    # the full system prompt sent to the LLM
```

## Output format

`annotate_bias` returns a dictionary with the following keys:

| Key | Type | Description |
|-----|------|-------------|
| `words_added` | `list[dict]` | Each entry has `"word"` and `"pos"` keys |
| `words_removed` | `list[dict]` | Each entry has `"word"` and `"pos"` keys |
| `bias_analysis` | `dict` | Maps each bias type name to `{"value": "Added"/"Removed"/"None", "reason": "..."}` |
| `raw` | `str` | The raw LLM response text |

## Bias types

1. Spin
2. Unsubstantiated Claims
3. Opinion Statements Presented as Fact
4. Sensationalism/Emotionalism
5. Mudslinging/Ad Hominem
6. Mind Reading
7. Slant
8. Flawed Logic
9. Bias by Omission
10. Omission of Source Attribution
11. Bias by Story Choice and Placement
12. Subjective Qualifying Adjectives
13. Word Choice

## Requirements

- Python >= 3.8
- openai >= 1.0
- An OpenAI API key
