#!/usr/bin/env python3
"""
Text Preprocessor for Antigravity Text-to-Speech (TTS)
Cleans code symbols, markdown artifacts, and formatting to produce
natural, human-sounding pronunciation.
"""

import re
import sys

def preprocess_text(text: str) -> str:
    if not text:
        return ""

    # 1. Clean markdown code fences (```python -> "")
    text = re.sub(r"```[a-zA-Z0-9_-]*", "", text)
    # Remove standalone backticks
    text = text.replace("`", "")

    # 2. Clean markdown headers (# Title -> Title)
    text = re.sub(r"^[ \t]*#+[ \t]*", "", text, flags=re.MULTILINE)

    # 3. Clean markdown bold and italics (**bold** -> bold, *italic* -> italic)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)

    # 4. Clean markdown bullet points (* item or - item -> item)
    text = re.sub(r"^[ \t]*[-*+][ \t]+", "", text, flags=re.MULTILINE)

    # 5. Clean URLs (avoid reading 100-character URL strings letter-by-letter)
    text = re.sub(r"https?://[^\s]+", " link ", text)

    # 6. Natural pronunciation for programming operators
    text = re.sub(r"\b!==\b|!=", " not equal to ", text)
    text = re.sub(r"\b===\b|==", " equals ", text)
    text = re.sub(r">=", " greater than or equal to ", text)
    text = re.sub(r"<=", " less than or equal to ", text)
    text = re.sub(r"=>|->", " arrow ", text)
    text = re.sub(r"&&", " and ", text)
    text = re.sub(r"\|\|", " or ", text)
    text = re.sub(r"\+\+", " increment ", text)
    text = re.sub(r"--", " decrement ", text)

    # 7. Convert snake_case identifiers into space-separated words
    # e.g. "calculate_total_sum" -> "calculate total sum"
    text = re.sub(r"(?<=[a-zA-Z0-9])_(?=[a-zA-Z0-9])", " ", text)

    # 8. Normalize whitespace while preserving line and paragraph breaks
    lines = []
    for line in text.splitlines():
        trimmed = re.sub(r"[ \t]+", " ", line).strip()
        lines.append(trimmed)

    cleaned = "\n".join(lines).strip()
    return cleaned

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_text = " ".join(sys.argv[1:])
    else:
        input_text = sys.stdin.read()
    print(preprocess_text(input_text))
