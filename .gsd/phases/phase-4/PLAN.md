# Plan: Phase 4 (UI Enhancements & Micro Feedback)

## Wave 1: Dynamic VU Meter (Microphone Volume Bar)
- **Files**: `scripts/SpeechManager.gd`, `scripts/Main.gd`
- **Actions**:
  - Expose instant mic volume via a new signal in `SpeechManager.gd` (`signal mic_volume_updated(db_level)`).
  - Add a gorgeous progress bar (`TextureProgressBar` or stylized `ProgressBar`) below the `mic_indicator` in `Main.gd` that shows real-time loudness.
- **Verification**: Ensure the bar jumps up and down dynamically when speaking.

## Wave 2: Juicy Floating Popping Syllables
- **Files**: `scripts/Main.gd`, `scripts/Plane.gd`
- **Actions**:
  - Implement a method `spawn_floating_text(text: String)` in `Main.gd`.
  - Spawns a Label node right above the `plane`'s global position.
  - Animate its position (drifting upwards), scale (popping up), and opacity (fading out) over 0.6 seconds using a Tween, then `queue_free()`.
- **Verification**: Syllables like `РО!`, `РИ!` pop up visually above the plane the exact moment they are recognized.

## Wave 3: Diagnostic Debug HUD Panel Toggle
- **Files**: `scripts/Main.gd`
- **Actions**:
  - Move the debug RichTextLabel and the VU meter into a unified, clean, semi-transparent Panel container (e.g. `DebugHUD`).
  - Add a small toggle button (or link it to a key like `F3`) to hide/show the debug panel.
- **Verification**: Toggling the HUD hides all diagnostics, leaving only the beautiful gameplay on-screen.
