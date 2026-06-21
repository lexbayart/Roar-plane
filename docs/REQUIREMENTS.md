# Requirements: Roar-plane

This document outlines the functional and non-functional requirements for the Roar-plane speech-practice game.

## Functional Requirements

### 1. Voice Recognition & Processing
- **REQ-VOIC-01**: Capture microphone audio and save it locally as 16kHz mono WAV.
- **REQ-VOIC-02**: Integrate VOSK model via a fast Python bridge script.
- **REQ-VOIC-03**: Parse recognition output to identify words containing the English letter "r" (case-insensitive).
- **REQ-VOIC-04**: Output structured JSON: `{ "has_r_sound": boolean, "text": string, "r_words": Array }`.

### 2. Gameplay Mechanics
- **REQ-GAME-01**: The plane must fall under constant gravity when silence or non-R words are detected.
- **REQ-GAME-02**: Apply vertical impulse (lift/flap) when `has_r_sound` is true.
- **REQ-GAME-03**: Obstacles (pipes) must spawn periodically and scroll left.
- **REQ-GAME-04**: Track player score (pipes successfully cleared) and trigger crash/restart when hitting obstacles or ground.

### 3. User Interface
- **REQ-UI-01**: Display live score on screen.
- **REQ-UI-02**: Show game-over screen with current score, high score, and a restart button.
- **REQ-UI-03**: Display instructions guiding the player to speak "R" words (e.g., *red, run, car*) to fly.

---

## Technical & Non-Functional Requirements

### 1. Performance & Latency
- **REQ-PERF-01**: Audio processing and recognition loop latency must be under 500ms for real-time responsiveness.
- **REQ-PERF-02**: The game must run at a stable 60 FPS on macOS and Windows desktop systems.

### 2. Dependencies & Portability
- **REQ-PORT-01**: Automatically detect host Python installation (`python3` or `python`) at startup.
- **REQ-PORT-02**: Bundle the VOSK small model alongside the executable on desktop builds.
