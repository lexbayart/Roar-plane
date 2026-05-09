#!/usr/bin/env python3
"""
VOSK Speech Recognition Bridge
Used by Roar-plane via OS.execute() from Godot
Accepts a WAV file path as argument, returns recognized text with word details
"""

import sys
import json
import os

# Add vosk to path if needed
try:
    from vosk import Model, KaldiRecognizer
except ImportError:
    print(json.dumps({"error": "VOSK not installed. Run: pip3 install vosk"}))
    sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: vosk_bridge.py <wav_file_path> [model_path]"}))
        sys.exit(1)

    wav_path = sys.argv[1]
    model_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "vosk_models", "vosk-model-small-en-us-0.15"
    )

    if not os.path.exists(wav_path):
        print(json.dumps({"error": f"WAV file not found: {wav_path}"}))
        sys.exit(1)

    if not os.path.exists(model_path):
        print(json.dumps({"error": f"Model not found at: {model_path}"}))
        sys.exit(1)

    # Initialize model
    model = Model(model_path)
    rec = KaldiRecognizer(model, 16000.0)
    rec.SetWords(True)  # Enable word-level output with time info

    # Read WAV file
    with open(wav_path, "rb") as f:
        wav_data = f.read()

    # Skip WAV header (44 bytes for standard PCM WAV)
    # VOSK accepts the full WAV including header
    rec.AcceptWaveform(wav_data)

    # Get result
    result_json = rec.FinalResult()
    result = json.loads(result_json)

    # Extract text and word details
    text = result.get("text", "")

    # Get word-level details if available
    words = []
    if "result" in result:
        for word_info in result["result"]:
            words.append({
                "word": word_info.get("word", ""),
                "conf": word_info.get("conf", 0.0),
                "start": word_info.get("start", 0.0),
                "end": word_info.get("end", 0.0),
            })

    # Check for R sound (contains letter 'r' case-insensitive)
    has_r_sound = False
    r_words = []
    for w in text.split():
        if 'r' in w.lower():
            has_r_sound = True
            r_words.append(w)

    output = {
        "text": text,
        "has_r_sound": has_r_sound,
        "r_words": r_words,
        "words": words,
        "word_count": len(text.split()),
    }

    print(json.dumps(output))

if __name__ == "__main__":
    main()