#!/usr/bin/env python3
"""
VOSK Speech Recognition Bridge - Russian Speech-to-Text
Used by Roar-plane via OS.execute() from Godot
"""

import sys
import json
import os

# Add vosk to path if needed
try:
    import vosk
    from vosk import Model, KaldiRecognizer
except ImportError:
    print(json.dumps({"error": "VOSK not installed. Run: pip3 install vosk"}))
    sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: vosk_bridge.py <wav_file_path> [model_path]"}))
        sys.exit(1)

    wav_path = sys.argv[1]
    # Default to the newly downloaded Russian model
    model_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "vosk_models", "vosk-model-small-ru-0.22"
    )

    if not os.path.exists(wav_path):
        print(json.dumps({"error": f"WAV file not found: {wav_path}"}))
        sys.exit(1)

    if not os.path.exists(model_path):
        print(json.dumps({"error": f"Model not found at: {model_path}"}))
        sys.exit(1)

    # Initialize VOSK Russian Model
    try:
        vosk.SetLogLevel(-1)
        model = Model(model_path)
        rec = KaldiRecognizer(model, 16000.0)
        rec.SetWords(True)  # Enable word-level output
    except Exception as e:
        print(json.dumps({"error": f"Failed to initialize VOSK: {str(e)}"}))
        sys.exit(1)

    # Read WAV file
    try:
        with open(wav_path, "rb") as f:
            wav_data = f.read()
    except Exception as e:
        print(json.dumps({"error": f"Failed to read WAV file: {str(e)}"}))
        sys.exit(1)

    # Recognize speech
    rec.AcceptWaveform(wav_data)
    result_json = rec.FinalResult()
    result = json.loads(result_json)

    # Extract text and word details
    text = result.get("text", "").strip()

    # Search for Russian 'р' (Cyrillic) or English 'r'
    has_r_sound = False
    for char in text:
        if char.lower() in ['р', 'r']:
            has_r_sound = True
            break

    output = {
        "text": text if text else "тишина",
        "has_r_sound": has_r_sound,
        "word_count": len(text.split()) if text else 0
    }

    print(json.dumps(output))

if __name__ == "__main__":
    main()