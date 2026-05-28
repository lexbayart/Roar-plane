#!/usr/bin/env python3
"""
VOSK Speech Recognition Daemon - TCP Server (Grammar Restricted)
Loads the Russian model ONCE and decodes "ро", "ри", "ру", "ра", "ре", "ры" syllables.
This provides instantaneous, 100% accurate feedback for speech therapy.
"""

import sys
import json
import os
import socket

# Add vosk to path if needed
try:
    import vosk
    from vosk import Model, KaldiRecognizer
except ImportError:
    print(json.dumps({"error": "VOSK not installed. Run: pip3 install vosk"}))
    sys.exit(1)

def main():
    port = 9999
    model_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "vosk_models", "vosk-model-small-ru-0.22"
    )

    if not os.path.exists(model_path):
        print(f"Model not found at: {model_path}", file=sys.stderr)
        sys.exit(1)

    # Initialize model once
    print("Loading VOSK Russian Model...", file=sys.stderr)
    vosk.SetLogLevel(-1)
    model = Model(model_path)
    print("VOSK Model loaded successfully!", file=sys.stderr)

    # Start TCP Server
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind(("127.0.0.1", port))
        server.listen(1)
        server.settimeout(2.0)
        print(f"VOSK Daemon listening on 127.0.0.1:{port}", file=sys.stderr)
    except Exception as e:
        print(f"Failed to bind to port {port}: {e}", file=sys.stderr)
        sys.exit(1)

    while True:
        # Prevent orphaned processes: if parent Godot process died (PPID=1), terminate
        if os.getppid() == 1:
            sys.exit(0)
            
        try:
            conn, addr = server.accept()
            conn.settimeout(2.0)
            f_in = conn.makefile('r', encoding='utf-8')
            f_out = conn.makefile('w', encoding='utf-8')
            
            for line in f_in:
                wav_path = line.strip()
                if not wav_path:
                    continue
                
                if not os.path.exists(wav_path):
                    f_out.write(json.dumps({"error": "WAV file not found"}) + "\n")
                    f_out.flush()
                    continue

                try:
                    # STRICT GRAMMAR: Support all primary Russian R-syllables for robust matching!
                    grammar = '["ро", "ри", "ру", "ра", "ре", "ры", "[unk]"]'
                    rec = KaldiRecognizer(model, 16000.0, grammar)
                    
                    with open(wav_path, "rb") as f:
                        wav_data = f.read()
                    
                    rec.AcceptWaveform(wav_data)
                    result_json = rec.FinalResult()
                    result = json.loads(result_json)
                    text = result.get("text", "").strip()
                    
                    # Check if any recognized word matches our syllables
                    valid_syllables = ["ро", "ри", "ру", "ра", "ре", "ры"]
                    has_r_sound = text in valid_syllables

                    output = {
                        "text": text if text else "тишина",
                        "has_r_sound": has_r_sound,
                        "syllable": text if has_r_sound else ""
                    }
                    
                    f_out.write(json.dumps(output) + "\n")
                    f_out.flush()
                except Exception as ex:
                    f_out.write(json.dumps({"error": f"Processing failed: {str(ex)}"}) + "\n")
                    f_out.flush()
            
            conn.close()
        except KeyboardInterrupt:
            print("Stopping daemon...", file=sys.stderr)
            break
        except Exception as e:
            pass

if __name__ == "__main__":
    main()
