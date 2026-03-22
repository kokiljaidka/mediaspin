# mediaspin

An R package for detecting 13 types of media bias in news headline edits using the OpenAI API.

## Installation

```r
# Install from local source
install.packages("path/to/mediaspin/R", repos = NULL, type = "source")

# Or using devtools
devtools::install_local("path/to/mediaspin/R")
```

## Setup

Set your OpenAI API key as an environment variable:

```r
Sys.setenv(OPENAI_API_KEY = "your-api-key-here")
```

Or add it to your `.Renviron` file:

```
OPENAI_API_KEY=your-api-key-here
```

## Usage

### Single headline pair

```r
library(mediaspin)

result <- annotate_bias(
  original = "Protest draws large crowd downtown",
  edited = "Violent riot erupts downtown",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  model = "gpt-3.5-turbo"
)

# Each bias type has a value (Added/Removed/None) and a reason
result[["Spin"]]$value
# [1] "Added"

result[["Spin"]]$reason
# [1] "The change from 'protest' to 'riot' introduces spin..."
```

### Batch processing

```r
pairs <- data.frame(
  original = c(
    "Senator discusses policy changes",
    "Study finds new treatment effective"
  ),
  edited = c(
    "Controversial senator slams radical policy changes",
    "Groundbreaking study proves miracle treatment"
  ),
  stringsAsFactors = FALSE
)

results <- annotate_batch(pairs)

# Access result for first row
results[[1]][["Sensationalism/Emotionalism"]]$value
```

### Custom word lists

You can provide your own added/removed word lists instead of relying on automatic set-difference computation:

```r
result <- annotate_bias(
  original = "The policy was announced",
  edited = "The disastrous policy was unveiled",
  added_words = c("disastrous", "unveiled"),
  removed_words = c("announced")
)
```

### Parsing raw responses

If you have raw LLM text output from another source, you can parse it directly:

```r
parsed <- parse_bias_response(raw_text)
```

### Viewing the system prompt

```r
cat(mediaspin_prompt())
```

## Bias Types Detected

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

## Dependencies

- [httr2](https://httr2.r-lib.org/) -- HTTP requests to the OpenAI API
- [jsonlite](https://cran.r-project.org/package=jsonlite) -- JSON parsing

## Authors

- Preetika Verma
- Kokil Jaidka
