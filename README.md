# Roar-plane / Рев-самолёт

**A speech-controlled flying game for children practicing the English "R" sound.**
**Речевая летающая игра для детей, тренирующих английский звук "R".**

Built with Godot 4.x + VOSK speech recognition.
Сделано на Godot 4.x + распознавание речи VOSK.

## How it works / Как работает

- The plane rises when you speak words containing the R sound (red, run, car, rain, rocket...)
- Самолёт поднимается, когда вы говорите слова со звуком R
- Silence or words without R → gravity pulls the plane down
- Тишина или слова без R → гравитация тянет самолёт вниз
- **No keyboard or mouse input** — voice only!
- **Никакого ввода с клавиатуры или мыши** — только голос!

### R-sound detection / Определение звука R

The game checks if recognized words contain the letter "r" (case-insensitive).
Игра проверяет, содержит ли распознанное слово букву "r" (регистронезависимо).

Examples / Примеры:
- Word containing R: **red**, **run**, **car**, **are**, **rain**, **rocket**, **arrow**, **forest** → plane flaps!
- Word without R: **cat**, **sun**, **blue**, **hello**, **goodbye** → plane falls

## VOSK Model Setup / Установка модели VOSK

The VOSK English model is **not** included in the repository. You must download it separately.

Модель VOSK **не** включена в репозиторий. Скачайте её отдельно:

```bash
# Download the small English model
curl -L https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip -o vosk-model-small-en-us-0.15.zip

# Unzip into the project's vosk_models/ folder
unzip vosk-model-small-en-us-0.15.zip -d vosk_models/
```

If the folder already exists at `vosk_models/vosk-model-small-en-us-0.15/`, you're all set.
Если папка `vosk_models/vosk-model-small-en-us-0.15/` уже существует — всё готово.

### Python Dependencies / Зависимости Python

The game calls VOSK through a Python bridge script. Requires Python 3 and the `vosk` package:

```bash
pip3 install vosk
```

The game auto-detects `python3` or `python` at startup. If neither is found, an error message appears.

## Platform Build Instructions / Сборка под платформы

### macOS (Intel) — Priority / Приоритет

```bash
# 1. Open the project in Godot 4.x editor
# 2. Project → Export → Add... → macOS
# 3. In Export settings:
#    - Architecture: x86_64
#    - Custom Template: (leave blank, use default)
#    - Export Mode: Export for macOS (App Bundle)
# 4. Export Project → Choose destination
# 5. After export, copy the vosk_models/ folder next to the .app bundle:
#    cp -r vosk_models <YourApp>.app/Contents/Resources/
#    (or place it alongside the .app for Development builds)
#
# Run: ./Roar-plane.app/Contents/MacOS/Roar-plane
```

### Windows

```bash
# 1. Open in Godot 4.x editor
# 2. Project → Export → Add... → Windows Desktop
# 3. Architecture: x86_64
# 4. Export Project → Roar-plane.exe
# 5. Copy vosk_models/ folder next to the .exe
# 6. Ensure Python 3 is installed with: pip install vosk
#
# Run: Roar-plane.exe
```

### Android

```bash
# Requirements: Godot 4.x with Android build template installed
# 1. Project → Export → Add... → Android
# 2. Configure:
#    - Custom Package: (use default debug keystore for testing)
#    - Min SDK: 24+
#    - Target SDK: 33+
#    - Exclude Filters: add "vosk_models/*"
# 3. Export → Export APK
# 4. Push vosk_models/ to device: adb push vosk_models/ /sdcard/Android/data/
#    or bundle manually in the app's data directory
#
# NOTE: The Python bridge won't work natively on Android.
# For Android, the C# addon (GodotSpeechRecognition) must be used instead.
```

### iOS

```bash
# Requirements: macOS + Xcode + Godot 4.x iOS export template
# 1. Project → Export → Add... → iOS
# 2. Configure:
#    - App Store category: Games
#    - Exclude Filters: "vosk_models/*"
# 3. Export → Export Project → Open in Xcode
# 4. In Xcode, add vosk_models/ folder to Bundle Resources
# 5. Build and run on device (iOS simulator doesn't support mic input)
#
# NOTE: VOSK C# addon has limited iOS support — testing required.
```

## Project Structure / Структура проекта

```
Roar-plane/
├── README.md
├── project.godot              # Godot project file
├── export_presets.cfg         # Export configurations
├── icon.png                   # App icon
├── vosk_models/               # VOSK language models (NOT in .pck)
│   └── vosk-model-small-en-us-0.15/
├── assets/                    # Game textures
│   ├── bg.png
│   ├── bird1.png, bird2.png, bird3.png
│   ├── pipe.png
│   ├── ground.png
│   └── restart.png
├── scenes/
│   └── Main.tscn             # Main game scene
├── scripts/
│   ├── Main.gd               # Game controller
│   ├── Plane.gd              # Plane physics + animation
│   ├── Pipe.gd               # Pipe obstacle logic
│   ├── SpeechManager.gd      # Speech autoload (GDScript bridge)
│   └── vosk_bridge.py        # Python VOSK bridge script
└── addons/
    └── godot-speech-recognition/  # C# addon (for Android/iOS builds)
```

## Technical Notes / Технические заметки

- **R-sound heuristic**: The Python bridge checks if any recognized word contains lowercase 'r'. This covers common R-sound words (are, our, ear, air, car, far, red, run, rain, rocket, arrow, forest). False positives are possible (e.g., "are" sounds like "R" but "car" has an ending R) — this is acceptable for a children's practice game.
- **Python bridge**: `scripts/vosk_bridge.py` receives a 16kHz mono WAV file path, runs VOSK recognition, and outputs JSON with `has_r_sound`, `text`, and `r_words`.
- **Model isolation**: The `vosk_models/` folder is excluded from `.pck` via export filters. It must be placed alongside the executable on all platforms.
- **.NET / C#**: The `addons/godot-speech-recognition/` folder contains the C# version of VOSK integration. It's included for Android/iOS reference but the game uses the GDScript + Python bridge for desktop platforms.
- **GDScript only** on desktop — no C# compilation required.

## License / Лицензия

MIT — free to use, modify, and share.