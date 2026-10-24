#!/usr/bin/env python3
"""
Text Preprocessor for Antigravity Text-to-Speech (TTS)
1. Cleans code symbols, markdown artifacts, and formatting.
2. Intelligently converts Romanized Hinglish words to native phonetics (Devanagari)
   for flawless, natural pronunciation of Hindi/Hinglish speech.
"""

import re
import sys

# High-accuracy Hinglish (Romanized Hindi) to Devanagari dictionary
# Only includes unambiguous Hinglish words so English code and sentences remain intact.
HINGLISH_DICTIONARY = {
    # Pronouns & Demonstratives
    "yeh": "यह", "ye": "यह", "woh": "वह", "wo": "वह", "vo": "वह",
    "aap": "आप", "aapka": "आपका", "aapki": "आपकी", "aapke": "आपके",
    "tum": "तुम", "tumhara": "तुम्हारा", "tumhari": "तुम्हारी", "tumhare": "तुम्हारे",
    "hum": "हम", "humein": "हमें", "humara": "हमारा", "humari": "हमारी", "humare": "हमारे",
    "mujhe": "मुझे", "mujhko": "मुझको", "mera": "मेरा", "meri": "मेरी", "mere": "मेरे",
    "tera": "तेरा", "teri": "तेरी", "tere": "तेरे",
    "apna": "अपना", "apni": "अपनी", "apne": "अपने",
    "isse": "इससे", "usse": "उससे", "inka": "इनका", "unka": "उनका",
    "kisko": "किसको", "jisko": "जिसको", "jiska": "जिसका", "jinki": "जिनकी",
    "kisi": "किसी", "sab": "सब", "sabhi": "सभी", "log": "लोग",
    "aisa": "ऐसा", "aisi": "ऐसी", "aise": "ऐसे",
    "waisa": "वैसा", "waisi": "वैसी", "waise": "वैसे",

    # Question Words
    "kya": "क्या", "kyun": "क्यों", "kyu": "क्यों", "kaise": "कैसे", "kese": "कैसे",
    "kaisa": "कैसा", "kaisi": "कैसी",
    "kahan": "कहाँ", "kaha": "कहाँ", "kab": "कब", "kaun": "कौन", "kon": "कौन",
    "kitna": "कितना", "kitne": "कितने", "kitni": "कितनी",

    # Auxiliary & State Verbs
    "hai": "है", "hain": "हैं", "ho": "हो", "hoon": "हूँ", "hu": "हूँ",
    "tha": "था", "thi": "थी", "the": "थे",
    "hoga": "होगा", "hogi": "होगी", "hoge": "होंगे", "honge": "होंगे",
    "hota": "होता", "hoti": "होती", "hote": "होते", "hona": "होना",
    "raha": "रहा", "rahi": "रही", "rahe": "रहे", "raho": "रहो", "rahna": "रहना",

    # Common Action Verbs
    "karo": "करो", "kar": "कर", "karna": "करना", "karne": "करने",
    "karega": "करेगा", "karegi": "करेगी", "karenge": "करेंगे", "karke": "करके",
    "karte": "करते", "karta": "करता", "karti": "करती",
    "dekho": "देखो", "dekh": "देख", "dekhna": "देखना", "dekhne": "देखने", "dekha": "देखा",
    "dekhte": "देखते", "dekhta": "देखता", "dekhti": "देखती",
    "sakte": "सकते", "sakta": "सकता", "sakti": "सकती",
    "batao": "बताओ", "bata": "बता", "batana": "बताना",
    "bolo": "बोलो", "bol": "बोल", "bolna": "बोलना", "bolne": "बोलने",
    "samjho": "समझो", "samajh": "समझ", "samajhna": "समझना", "samjha": "समझा",
    "chahiye": "चाहिए", "chahta": "चाहता", "chahti": "चाहती",
    "chalo": "चलो", "chal": "चल", "chalna": "चलना", "chalta": "चलता", "chalti": "चलती",
    "aata": "आता", "aati": "आती", "aate": "आते", "aao": "आओ", "aana": "आना", "aa": "आ",
    "aaye": "आये", "aayega": "आयेगा", "aayegi": "आयेगी", "aaya": "आया", "aayi": "आयी",
    "jao": "जाओ", "jaa": "जा", "jaana": "जाना", "jana": "जाना", "jaate": "जाते",
    "jaayega": "जायेगा", "gaya": "गया", "gayi": "गयी", "gaye": "गये",
    "dalo": "डालो", "daalo": "डालो", "daal": "डाल",
    "lena": "लेना", "liya": "लिया", "liye": "लिए",
    "dena": "देना", "diya": "दिया", "diye": "दिए",
    "likho": "लिखो", "likh": "लिख", "likhna": "लिखना",
    "padho": "पढ़ो", "padh": "पढ़", "padhna": "पढ़ना",
    "suno": "सुनो", "sun": "सुन", "sunna": "सुनना",
    "mil": "मिल", "mila": "मिला", "milega": "मिलेगा", "mili": "मिली",
    "rakho": "रखो", "rakh": "रख", "rakhna": "रखना",
    "banao": "बनाओ", "bana": "बना", "banana": "बनाना", "banaya": "बनाया",

    # Conjunctions, Adverbs & Particles
    "nahi": "नहीं", "nahin": "नहीं", "bhi": "भी", "toh": "तो",
    "aur": "और", "ya": "या", "lekin": "लेकिन", "magar": "मगर", "agar": "अगर",
    "kyunki": "क्योंकि", "kyoki": "क्योंकि", "isliye": "इसलिए", "isiliye": "इसलिए",
    "pe": "पे", "se": "से", "ko": "को", "ka": "का", "ki": "की", "ke": "के",
    "mein": "में",

    # Common Expressions & Adjectives
    "bhai": "भाई", "yaar": "यार", "dost": "दोस्त",
    "theek": "ठीक", "thik": "ठीक", "sahi": "सही", "galat": "गलत",
    "achha": "अच्छा", "accha": "अच्छा", "achhi": "अच्छी", "achhe": "अच्छे",
    "pata": "पता", "kaam": "काम", "baat": "बात", "cheez": "चीज़", "chiz": "चीज़",
    "sirf": "सिर्फ", "kuch": "कुछ", "kuchh": "कुछ",
    "bohot": "बहुत", "bahut": "बहुत", "zyada": "ज़्यादा", "jyada": "ज़्यादा", "kam": "कम",
    "jaldi": "जल्दी", "dhire": "धीरे", "dheere": "धीरे",
    "pehle": "पहले", "baad": "बाद", "ab": "अब", "abhi": "अभी", "phir": "फिर",
    "shuru": "शुरू", "khatam": "खत्म", "waqt": "वक्त", "samay": "समय",
    "wala": "वाला", "wali": "वाली", "wale": "वाले"
}

def transliterate_hinglish_words(text: str) -> str:
    """Converts common Romanized Hinglish words to Devanagari for accurate phonetics."""
    def replacer(match):
        word = match.group(0)
        lower_word = word.lower()
        if lower_word in HINGLISH_DICTIONARY:
            return HINGLISH_DICTIONARY[lower_word]
        return word

    # Replace standalone words only
    return re.sub(r"\b[a-zA-Z]+\b", replacer, text)

def preprocess_text(text: str) -> str:
    if not text:
        return ""

    # 1. Clean markdown code fences (```python -> "")
    text = re.sub(r"```[a-zA-Z0-9_-]*", "", text)
    text = text.replace("`", "")

    # 2. Clean markdown headers (# Title -> Title)
    text = re.sub(r"^[ \t]*#+[ \t]*", "", text, flags=re.MULTILINE)

    # 3. Clean markdown bold and italics (**bold** -> bold, *italic* -> italic)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)

    # 4. Clean markdown bullet points (* item or - item -> item)
    text = re.sub(r"^[ \t]*[-*+][ \t]+", "", text, flags=re.MULTILINE)

    # 5. Clean URLs
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
    text = re.sub(r"(?<=[a-zA-Z0-9])_(?=[a-zA-Z0-9])", " ", text)

    # 8. Transliterate Romanized Hinglish words into proper phonetics
    text = transliterate_hinglish_words(text)

    # 9. Normalize whitespace
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
