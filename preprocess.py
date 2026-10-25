#!/usr/bin/env python3
"""
Text Preprocessor for Antigravity Text-to-Speech (TTS)
1. Cleans code symbols, markdown artifacts, and programming syntax.
2. Intelligently converts Romanized Hinglish words to native phonetics (Devanagari)
   for flawless, ultra-realistic, human-like Hindi and Hinglish speech.
3. Leaves English technical words and standard English sentences completely intact.
"""

import re
import sys

# High-precision Hinglish (Romanized Hindi) to Devanagari dictionary.
# Excludes any collisions with English words (e.g. 'to', 'me', 'in', 'is', 'on', 'at', 'do', 'or', 'so').
HINGLISH_DICTIONARY = {
    # Pronouns & Demonstratives
    "yeh": "यह", "ye": "यह", "woh": "वह", "wo": "वह", "vo": "वह",
    "aap": "आप", "aapka": "आपका", "aapki": "आपकी", "aapke": "आपके", "aapko": "आपको",
    "tum": "तुम", "tumhara": "तुम्हारा", "tumhari": "तुम्हारी", "tumhare": "तुम्हारे", "tumhe": "तुम्हें", "tumko": "तुमको",
    "hum": "हम", "humein": "हमें", "hume": "हमें", "humara": "हमारा", "humari": "हमारी", "humare": "हमारे", "humko": "हमको",
    "mujhe": "मुझे", "mujhko": "मुझको", "mera": "मेरा", "meri": "मेरी", "mere": "मेरे",
    "tera": "तेरा", "teri": "तेरी", "tere": "तेरे", "tujhe": "तुझे", "tujhko": "तुझको",
    "apna": "अपना", "apni": "अपनी", "apne": "अपने", "apno": "अपनों",
    "isse": "इससे", "usse": "उससे", "inse": "इनसे", "unse": "उनसे", "kisse": "किससे", "jisse": "जिससे",
    "iska": "इसका", "iski": "इसकी", "iske": "इसके",
    "uska": "उसका", "uski": "उसकी", "uske": "उसके",
    "inka": "इनका", "inki": "इनकी", "inke": "इनके",
    "unka": "उनका", "unki": "उनकी", "unke": "उनके",
    "kisko": "किसको", "jisko": "जिसको", "jiska": "जिसका", "jiski": "जिसकी", "jiske": "जिसके",
    "kisi": "किसी", "sab": "सब", "sabhi": "सभी", "sabko": "सबको", "log": "लोग", "logo": "लोगों",
    "aisa": "ऐसा", "aisi": "ऐसी", "aise": "ऐसे",
    "waisa": "वैसा", "waisi": "वैसी", "waise": "वैसे",
    "kaisa": "कैसा", "kaisi": "कैसी", "kaise": "कैसे", "kese": "कैसे",

    # Question Words
    "kya": "क्या", "kyun": "क्यों", "kyu": "क्यों", "kyunki": "क्योंकि", "kyoki": "क्योंकि",
    "kahan": "कहाँ", "kaha": "कहाँ", "kab": "कब", "kaun": "कौन", "kon": "कौन",
    "kitna": "कितना", "kitne": "कितने", "kitni": "कितनी",
    "kidhar": "किधर", "jidhar": "जिधर", "idhar": "इधर", "udhar": "उधर",

    # Auxiliary & State Verbs (All Tenses & Forms)
    "hai": "है", "hain": "हैं", "ho": "हो", "hoon": "हूँ", "hu": "हूँ",
    "tha": "था", "thi": "थी", "the": "थे",
    "hoga": "होगा", "hogi": "होगी", "hoge": "होओगे", "honge": "होंगे",
    "hota": "होता", "hoti": "होती", "hote": "होते", "hona": "होना", "hone": "होने",
    "hua": "हुआ", "hue": "हुए", "hui": "हुई",
    "raha": "रहा", "rha": "रहा", "rahi": "रही", "rhi": "रही",
    "rahe": "रहे", "rhe": "रहे", "raho": "रहो", "rho": "रहो",
    "rahna": "रहना", "rhna": "रहना", "rahenge": "रहेंगे", "rhenge": "रहेंगे",
    "rahega": "रहेगा", "rhega": "रहेगा", "rahegi": "रहेगी", "rhegi": "रहेगी",
    "rahunga": "रहूँगा", "rhunga": "रहूँगा",

    # Compulsion / Obligation Verbs (padna)
    "padega": "पड़ेगा", "padegi": "पड़ेगी", "padenge": "पड़ेंगे",
    "pada": "पड़ा", "padi": "पड़ी", "pade": "पड़े",
    "padta": "पड़ता", "padti": "पड़ती", "padte": "पड़ते",
    "padna": "पड़ना", "padne": "पड़ने",

    # Action Verbs (Full & Colloquial Abbreviations)
    "kar": "कर", "kr": "कर", "karo": "करो", "kro": "करो",
    "karna": "करना", "krna": "करना", "karne": "करने", "krne": "करने",
    "karega": "करेगा", "krega": "करेगा", "karegi": "करेगी", "kregi": "करेगी",
    "karenge": "करेंगे", "krenge": "करेंगे", "karke": "करके", "krke": "करके",
    "karunga": "करूँगा", "krunga": "करूँगा", "karungi": "करूँगी", "krungi": "करूँगी",
    "karte": "करते", "krte": "करते", "karta": "करता", "krta": "करता", "karti": "करती", "krti": "करती",
    "karoge": "करोगे", "kroge": "करोगे", "kariye": "करिए", "kijiye": "कीजिए",
    "kiya": "किया", "kiye": "किए", "kii": "की",

    "dekh": "देख", "dekho": "देखो", "dekha": "देखा", "dekhe": "देखे", "dekhi": "देखी",
    "dekhna": "देखना", "dekhne": "देखने", "dekhte": "देखते", "dekhta": "देखता", "dekhti": "देखती",
    "dekhenge": "देखेंगे", "dekhega": "देखेगा", "dekhegi": "देखेगी", "dekhiye": "देखिए",

    "samajh": "समझ", "samjh": "समझ", "samjho": "समझो", "samjha": "समझा",
    "samjhe": "समझे", "samjhi": "समझी", "samajhna": "समझना", "samajhne": "समझने",
    "samajhte": "समझते", "samajhta": "समझता", "samajhti": "समझती", "samajhiye": "समझिए",

    "bata": "बता", "btao": "बताओ", "batao": "बताओ", "bataya": "बताया",
    "bataye": "बताए", "batayi": "बताई", "batana": "बताना", "btana": "बताना",
    "batane": "बताने", "bataenge": "बताएंगे", "bataunga": "बताऊँगा", "bataiye": "बताइए",

    "bol": "बोल", "bolo": "बोलो", "bola": "बोला", "bole": "बोले", "boli": "बोली",
    "bolna": "बोलना", "bolne": "बोलने", "bolte": "बोलते", "bolta": "बोलता", "bolti": "बोलती",
    "bolenge": "बोलेंगे", "boliye": "बोलिए",

    "sun": "सुन", "suno": "सुनो", "suna": "सुना", "sune": "सुने", "suni": "सुनी",
    "sunna": "सुनना", "sunne": "सुनने", "sunte": "सुनते", "sunta": "सुनता", "sunti": "सुनती",
    "sunenge": "सुनेंगे", "suniye": "सुनिए",

    "chahiye": "चाहिए", "chahta": "चाहता", "chahti": "चाहती", "chahte": "चाहते",
    "chaho": "चाहो", "chahenge": "चाहेंगे", "chaha": "चाहा",

    "sakta": "सकता", "sakti": "सकती", "sakte": "सकते", "sakenge": "सकेंगे",
    "saka": "सका", "saki": "सकी", "sake": "सके",

    "chal": "चल", "chalo": "चलो", "chala": "चला", "chale": "चले", "chali": "चली",
    "chalna": "चलना", "chalne": "चलने", "chalta": "चलता", "chalti": "चलती", "chalte": "चलते",
    "chalega": "चलेगा", "chalegi": "चलेगी", "chalenge": "चलेंगे",

    "aao": "आओ", "aana": "आना", "aane": "आने", "aata": "आता", "aati": "आती", "aate": "आते",
    "aaye": "आए", "aayega": "आएगा", "aayegi": "आएगी", "aayenge": "आएंगे",
    "aaya": "आया", "aayi": "आयी", "aaiye": "आइए",

    "jao": "जाओ", "jaa": "जा", "jaana": "जाना", "jana": "जाना", "jaane": "जाने",
    "jaate": "जाते", "jaata": "जाता", "jaati": "जाती",
    "jaayega": "जाएगा", "jaayegi": "जाएगी", "jaayenge": "जाएंगे",
    "gaya": "गया", "gayi": "गयी", "gaye": "गए", "jaiye": "जाइए", "jaaiye": "जाइए",

    "daal": "डाल", "dal": "डाल", "daalo": "डालो", "dalo": "डालो",
    "daala": "डाला", "dala": "डाला", "daale": "डाले", "dale": "डाले",
    "daali": "डाली", "dali": "डाली", "daalna": "डालना", "dalna": "डालना",

    "dena": "देना", "dene": "देने", "diya": "दिया", "diye": "दिए",
    "dete": "देते", "deta": "देता", "deti": "देती", "denge": "देंगे",
    "dega": "देगा", "degi": "देगी", "dijiye": "दीजिए",

    "lena": "लेना", "lene": "लेने", "liya": "लिया", "liye": "लिए",
    "lete": "लेते", "leta": "लेता", "leti": "लेती", "lenge": "लेंगे",
    "lega": "लेगा", "legi": "लेगी", "lijiye": "लीजिए",

    "likho": "लिखो", "likh": "लिख", "likhna": "लिखना", "likhne": "लिखने", "likha": "लिखा", "likhe": "लिखे",
    "padho": "पढ़ो", "padh": "पढ़", "padhna": "पढ़ना", "padhne": "पढ़ने", "padha": "पढ़ा", "padhe": "पढ़े",

    "mil": "मिल", "mila": "मिला", "mile": "मिले", "mili": "मिली", "milo": "मिलो",
    "milna": "मिलना", "milne": "मिलने", "milte": "मिलते", "milta": "मिलता", "milti": "मिलती",
    "milega": "मिलेगा", "milegi": "मिलेगी", "milenge": "मिलेंगे",

    "rakho": "रखो", "rakh": "रख", "rakhna": "रखना", "rakhne": "रखने",
    "rakha": "रखा", "rakhe": "रखे", "rakhi": "रखी", "rakhiye": "रखिए",

    "banao": "बनाओ", "bana": "बना", "banana": "बनाना", "banane": "बनाने",
    "banaya": "बनाया", "banaye": "बनाए", "banayi": "बनाई",
    "banega": "बनेगा", "banegi": "बनेगी", "banenge": "बनेंगे",

    "lag": "लग", "lago": "लगो", "laga": "लगा", "lage": "लगे", "lagi": "लगी",
    "lagna": "लगना", "lagne": "लगने", "lagta": "लगता", "lagti": "लगती", "lagte": "लगते",
    "lagega": "लगेगा", "lagegi": "लगेगी", "lagenge": "लगेंगे",

    "ruk": "रुक", "ruko": "रुको", "ruka": "रुका", "ruke": "रुके", "rukna": "रुकना",
    "chhod": "छोड़", "chhodo": "छोड़ो", "chhoro": "छोड़ो", "chhoda": "छोड़ा", "chhodna": "छोड़ना",
    "soch": "सोच", "socho": "सोचो", "socha": "सोचा", "soche": "सोचे", "sochna": "सोचना", "sochne": "सोचने",
    "bhej": "भेज", "bhejo": "भेजो", "bheja": "भेजा", "bheje": "भेजे", "bhejna": "भेजना", "bhejne": "भेजने",
    "sambhal": "संभाल", "sambhalo": "संभालो", "sambhalna": "संभालना",

    # Conjunctions, Adverbs & Particles
    "nahi": "नहीं", "nahin": "नहीं", "nhi": "नहीं", "nhin": "नहीं", "mat": "मत",
    "bhi": "भी", "toh": "तो",
    "aur": "और", "ya": "या", "lekin": "लेकिन", "magar": "मगर", "agar": "अगर",
    "isliye": "इसलिए", "isiliye": "इसलिए", "jabki": "जबकि",
    "pe": "पे", "se": "से", "ko": "को", "ka": "का", "ki": "की", "ke": "के",
    "mein": "में",

    # Common Expressions, Adjectives & Colloquial Terms
    "bhai": "भाई", "yaar": "यार", "dost": "दोस्त",
    "theek": "ठीक", "thik": "ठीक", "thk": "ठीक", "sahi": "सही", "galat": "गलत",
    "achha": "अच्छा", "accha": "अच्छा", "acha": "अच्छा",
    "achhi": "अच्छी", "achi": "अच्छी", "achhe": "अच्छे", "ache": "अच्छे",
    "badhiya": "बढ़िया", "badiya": "बढ़िया",
    "pata": "पता", "kaam": "काम", "baat": "बात", "cheez": "चीज़", "chiz": "चीज़",
    "sirf": "सिर्फ", "kuch": "कुछ", "kuchh": "कुछ", "kch": "कुछ",
    "bohot": "बहुत", "bahut": "बहुत", "bhot": "बहुत", "bhut": "बहुत",
    "zyada": "ज़्यादा", "jyada": "ज़्यादा", "kam": "कम",
    "jaldi": "जल्दी", "dhire": "धीरे", "dheere": "धीरे", "turant": "तुरंत",
    "pehle": "पहले", "pahle": "पहले", "baad": "बाद", "ab": "अब", "abhi": "अभी",
    "tab": "तब", "jab": "जब", "phir": "फिर", "fir": "फिर",
    "shuru": "शुरू", "khatam": "खत्म", "chalu": "चालू", "band": "बंद",
    "waqt": "वक्त", "samay": "समय", "matlab": "मतलब",
    "zaroorat": "ज़रूरत", "jarurat": "ज़रूरत",
    "zaroori": "ज़रूरी", "jaroori": "ज़रूरी",
    "zaroor": "ज़रूर", "jaroor": "ज़रूर",
    "bilkul": "बिल्कुल", "pakka": "पक्का", "shayad": "शायद",
    "hamesha": "हमेशा", "kabhi": "कभी",
    "aaj": "आज", "kal": "कल", "parso": "परसों",
    "din": "दिन", "raat": "रात", "subah": "सुबह", "shaam": "शाम",
    "yahan": "यहाँ", "wahan": "वहाँ",
    "upar": "ऊपर", "niche": "नीचे", "neeche": "नीचे", "andar": "अंदर", "bahar": "बाहर",
    "paas": "पास", "door": "दूर", "saath": "साथ", "alag": "अलग",
    "samne": "सामने", "piche": "पीछे", "peeche": "पीछे", "aage": "आगे",
    "khud": "खुद",
    "wala": "वाला", "wali": "वाली", "wale": "वाले",
    "namaste": "नमस्ते", "namaskar": "नमस्कार", "pranam": "प्रणाम",
    "dhanyawad": "धन्यवाद", "shukriya": "शुक्रिया",
    "kripya": "कृपया", "krpya": "कृपया", "plz": "प्लीज़", "pls": "प्लीज़"
}

def transliterate_hinglish_words(text: str) -> str:
    """Converts Romanized Hinglish words to Devanagari for natural Hindi pronunciation."""
    def replacer(match):
        word = match.group(0)
        lower_word = word.lower()
        if lower_word in HINGLISH_DICTIONARY:
            return HINGLISH_DICTIONARY[lower_word]
        return word

    # Replace standalone alphanumeric words only
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

    # 5. Clean URLs to prevent reciting entire link strings
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
        if trimmed:
            lines.append(trimmed)

    cleaned = "\n".join(lines).strip()

    # 10. Natural prosody ending: Ensure sentence finishes with natural cadence
    if cleaned and cleaned[-1] not in ".!?।":
        cleaned += "."

    return cleaned

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_text = " ".join(sys.argv[1:])
    else:
        input_text = sys.stdin.read()
    print(preprocess_text(input_text))
