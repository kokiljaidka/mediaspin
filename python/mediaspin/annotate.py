"""Core annotation logic for the MediaSpin bias detection pipeline."""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Tuple

from openai import OpenAI

from .prompt import BIAS_TYPES, SYSTEM_PROMPT


def _diff_words(original: str, edited: str) -> Tuple[List[str], List[str]]:
    """Compute added and removed words via simple word-level set difference."""
    orig_words = original.split()
    edit_words = edited.split()

    # Use multisets (count occurrences) for accurate diffing
    from collections import Counter

    orig_counts = Counter(orig_words)
    edit_counts = Counter(edit_words)

    added = []
    for word, count in edit_counts.items():
        diff = count - orig_counts.get(word, 0)
        added.extend([word] * max(diff, 0))

    removed = []
    for word, count in orig_counts.items():
        diff = count - edit_counts.get(word, 0)
        removed.extend([word] * max(diff, 0))

    return added, removed


def _format_user_message(
    original: str,
    edited: str,
    added_words: List[str],
    removed_words: List[str],
) -> str:
    """Format the user message for the OpenAI API call."""
    added_str = ", ".join(added_words) if added_words else "(none)"
    removed_str = ", ".join(removed_words) if removed_words else "(none)"
    return (
        f"Original Headline: {original}\n"
        f"Edited Headline: {edited}\n"
        f"Added words: {added_str}\n"
        f"Removed words: {removed_str}"
    )


def parse_response(text: str) -> Dict[str, Any]:
    """Parse the raw LLM response into a structured dictionary.

    Returns a dict with:
        - "words_added": list of {"word": str, "pos": str}
        - "words_removed": list of {"word": str, "pos": str}
        - "bias_analysis": dict mapping each bias type to
          {"value": "Added"/"Removed"/"None", "reason": str}
        - "raw": the original response text
    """
    result: Dict[str, Any] = {
        "words_added": [],
        "words_removed": [],
        "bias_analysis": {},
        "raw": text,
    }

    # Parse Words Added
    added_match = re.search(r"Words Added:\s*(.+)", text)
    if added_match:
        for m in re.finditer(r"(\S+)\s*\[([^\]]+)\]", added_match.group(1)):
            result["words_added"].append({"word": m.group(1).rstrip(","), "pos": m.group(2)})

    # Parse Words Removed
    removed_match = re.search(r"Words Removed:\s*(.+)", text)
    if removed_match:
        for m in re.finditer(r"(\S+)\s*\[([^\]]+)\]", removed_match.group(1)):
            result["words_removed"].append({"word": m.group(1).rstrip(","), "pos": m.group(2)})

    # Parse Bias Analysis list
    # Match lines like: 1. Spin [None]: explanation text
    bias_pattern = re.compile(
        r"^\d+\.\s*(.+?)\s*\[(Added|Removed|None)\]\s*:\s*(.+)",
        re.MULTILINE,
    )
    for m in bias_pattern.finditer(text):
        bias_name = m.group(1).strip()
        value = m.group(2).strip()
        reason = m.group(3).strip()
        result["bias_analysis"][bias_name] = {"value": value, "reason": reason}

    return result


def annotate_bias(
    original: str,
    edited: str,
    added_words: Optional[List[str]] = None,
    removed_words: Optional[List[str]] = None,
    api_key: Optional[str] = None,
    model: str = "gpt-3.5-turbo",
) -> Dict[str, Any]:
    """Annotate bias in a news headline edit.

    Parameters
    ----------
    original : str
        The original headline.
    edited : str
        The edited headline.
    added_words : list of str, optional
        Words added in the edit. Computed automatically if not provided.
    removed_words : list of str, optional
        Words removed in the edit. Computed automatically if not provided.
    api_key : str, optional
        OpenAI API key. If not provided, the OPENAI_API_KEY environment
        variable is used.
    model : str
        OpenAI model to use (default: ``"gpt-3.5-turbo"``).

    Returns
    -------
    dict
        Structured annotation result with keys ``words_added``,
        ``words_removed``, ``bias_analysis``, and ``raw``.
    """
    if added_words is None or removed_words is None:
        auto_added, auto_removed = _diff_words(original, edited)
        if added_words is None:
            added_words = auto_added
        if removed_words is None:
            removed_words = auto_removed

    user_message = _format_user_message(original, edited, added_words, removed_words)

    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
        temperature=0.0,
    )

    raw_text = response.choices[0].message.content or ""
    return parse_response(raw_text)


def annotate_batch(
    pairs: List[Tuple[str, str]],
    api_key: Optional[str] = None,
    model: str = "gpt-3.5-turbo",
) -> List[Dict[str, Any]]:
    """Annotate bias for a batch of headline pairs.

    Parameters
    ----------
    pairs : list of (str, str)
        List of ``(original_headline, edited_headline)`` tuples.
    api_key : str, optional
        OpenAI API key.
    model : str
        OpenAI model to use.

    Returns
    -------
    list of dict
        List of structured annotation results.
    """
    results = []
    for original, edited in pairs:
        result = annotate_bias(original, edited, api_key=api_key, model=model)
        results.append(result)
    return results
