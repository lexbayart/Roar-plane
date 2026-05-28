# Project: Roar-plane / Рев-самолёт

## Vision
A speech-controlled flying game for children practicing the English "R" sound. The plane rises when the user speaks words containing the "R" sound and falls under gravity during silence or other sounds.

## Technology Stack
- **Engine**: Godot 4.x (GDScript)
- **Speech Recognition**: VOSK Speech Recognition (Small English Model: `vosk-model-small-en-us-0.15`)
- **Integration**: Python bridge script (`scripts/vosk_bridge.py`) called from GDScript (`scripts/SpeechManager.gd`)
- **Target Platforms**: macOS (Primary app bundle), Windows, Android/iOS (secondary via C# addon)

## Core Architecture
1. **Audio Capture**: `SpeechManager.gd` captures raw microphone input and writes it to a temporary 16kHz mono WAV file.
2. **Recognition Bridge**: `vosk_bridge.py` reads the WAV, feeds it to the VOSK model, analyzes the recognized text, and outputs JSON mapping `has_r_sound`, `text`, and parsed words containing 'r'.
3. **Game Logic**: `Plane.gd` processes the JSON output, applying vertical thrust/wing-flap animations if the sound was validated.

## Coding Conventions
- **GDScript**: Strict typing where possible in Godot 4.x. Use descriptive node names.
- **Python**: Standard PEP8. Maintain lightweight processing for low latency.
- **Resources**: Assets, scenes, and scripts organized cleanly in respective directories.
