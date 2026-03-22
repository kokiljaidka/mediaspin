"""MediaSpin: Annotation pipeline for detecting media bias in news headline edits."""

from .annotate import annotate_batch, annotate_bias, parse_response
from .prompt import BIAS_TYPES, SYSTEM_PROMPT

__all__ = [
    "annotate_bias",
    "annotate_batch",
    "parse_response",
    "BIAS_TYPES",
    "SYSTEM_PROMPT",
]
