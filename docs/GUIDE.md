# Roar-plane — Complete User Guide

> Everything you need to install, run, and play the voice-controlled flying game. For parents, teachers, and children.

---

## 🖱️ Getting Started

### What you need

- A computer (macOS or Windows)
- A microphone (built-in laptop mic works fine)
- Python 3 installed on your system
- The VOSK English speech model (downloaded once, see below)

### Installation

1. **Download the VOSK model** — the game needs a speech recognition model that is not bundled with the project:

   ```bash
   curl -L https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip -o vosk-model-small-en-us-0.15.zip
   unzip vosk-model-small-en-us-0.15.zip -d vosk_models/
   ```

2. **Install the Python VOSK library:**

   ```bash
   pip3 install vosk
   ```

3. **Place the model** — make sure the `vosk_models/` folder is next to the game executable (or in the project root if running from Godot editor).

4. **Launch the game** — open the project in Godot 4.x and press Play, or run the exported executable.

The game will automatically detect your Python installation and start the speech recognition daemon.

---

## 🎮 How to Play

### The basic idea

Roar-plane is a side-scrolling flying game inspired by Flappy Bird. Instead of pressing a button or clicking to fly, **you speak**. The plane rises when it detects the "R" sound in your voice and falls when you're silent or say words without "R".

### Starting the game

When the game launches, the microphone is already listening. The start screen shows a prompt like "Say R-R-R to fly!" (or "Скажи Р-Р-Р чтобы взлететь!" in Russian). Simply speak any word containing the letter R:

- **English:** red, run, car, rain, rocket, arrow, forest, are
- **Russian:** ро, ри, ру, ра, ре, ры

The plane will take off and the game begins.

### Flying through pipes

Green pipes scroll from right to left with a gap in the middle. Keep speaking "R" words to stay aloft and fly through the gaps. If you hit a pipe or fall to the ground, the game ends.

### Collecting stars

Golden stars appear in the center of some pipe gaps. Fly through a star to collect it and earn **5 bonus points**. A floating "+5" appears when you collect one.

### Scoring

- **1 point** for each pipe you successfully pass through
- **5 points** for each collected star
- Your **current score** is displayed at the top of the screen
- Your **high score** (best ever) is shown on the game-over screen
- The top 5 scores are saved locally with names and dates

### Game over and restart

When you crash, the game-over screen appears with your score and high score. You can:
- Click the **Restart** button, or
- Simply speak an "R" sound again — the microphone stays active and will restart the game

---

## 🎛️ In-Game Controls & UI

### Language toggle

Click the **"RU / EN"** button in the top-left corner to switch the interface between Russian and English. This changes all on-screen text (start prompt, score labels, game-over message).

### Microphone indicator

A microphone icon (🎤) in the top-right corner shows the mic status:
- **Pulsing red** — microphone is actively listening
- **Gray** — microphone is inactive

### Volume meter

A horizontal bar in the center HUD shows your current microphone volume in real-time. This helps you and the child see if the microphone is picking up sound. If the bar doesn't move when you speak, check your system microphone settings.

### HUD toggle

Click **"HUD: ВКЛ / HUD: ВЫКЛ"** in the top-right to show or hide the debug panel (volume meter and speech recognition text).

### Syllable cards

Three cards — **РО**, **РИ**, **РУ** — are displayed on screen. When the child speaks a matching syllable, the corresponding card glows red with a brief animation. This gives immediate visual feedback that the sound was recognized.

### Debug: keyboard fallback

During testing or if the microphone is unavailable, pressing **Space** simulates an "R" sound detection and makes the plane flap. This is for debugging only.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Space | Simulate "R" sound (debug/test mode only) |

All other gameplay is voice-controlled. No other keyboard input is used during normal play.

---

## 🌐 Language Support

The game supports two language modes:

| Feature | English | Russian |
|---------|---------|---------|
| Start prompt | "Say R-R-R to fly!" | "Скажи Р-Р-Р чтобы взлететь!" |
| Score label | "Score:" | "Очки:" |
| High score label | "Best:" | "Рекорд:" |
| Game over | "Oops! Crashed!" | "Упс! Упали!" |
| Recognized syllables | red, run, car, rain, rocket, are, arrow, forest | ро, ри, ру, ра, ре, ры |

The VOSK model used is the small English model (`vosk-model-small-en-us-0.15`). Russian syllable recognition works through the same model's phonetic matching.

---

## ⚠️ Known Limitations

- **Microphone quality matters** — the game works best with a decent microphone. Very quiet or distant mics may not trigger recognition reliably.
- **Recognition latency** — there is a short delay (typically 200-500ms) between speaking and the plane responding. This is inherent to the speech recognition pipeline.
- **False positives** — the "R" detection checks if recognized words contain the letter "r". Some words without an actual "R" sound may trigger the plane (e.g., "are" vs "car"). This is acceptable for a children's practice game.
- **Desktop only** — the current version is designed for macOS and Windows. Android and iOS builds require additional setup (C# addon) and are not yet fully functional.
- **No internet required** — but the initial VOSK model download requires internet. After that, the game works fully offline.
- **Python dependency** — the game requires Python 3 with the `vosk` package installed. The game auto-detects `python3` or `python` at startup.

---

## 🔧 Troubleshooting

**"Mic Error!" on start screen** — Python 3 is not found or the VOSK daemon failed to start. Verify that `python3 --version` works in your terminal and that `pip3 install vosk` completed successfully.

**Volume meter doesn't move** — Check that your system microphone is enabled and not muted. On macOS, go to System Preferences → Sound → Input. On Windows, check Sound Settings → Input.

**Plane doesn't respond to voice** — Speak clearly and close to the microphone. Try saying "red" or "run" slowly and loudly. Check that the VOSK model folder (`vosk_models/vosk-model-small-en-us-0.15/`) exists in the correct location.

**Game feels too hard or too easy** — The physics (gravity, flap force) can be adjusted in `scripts/Plane.gd`. Look for `GRAVITY` and `FLAP_VELOCITY` constants.

---

*This guide covers Roar-plane Beta. The game is in active development — new features and improvements are being added regularly.*
