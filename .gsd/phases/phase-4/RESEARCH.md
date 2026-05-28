# Research: Phase 4 (UI Enhancements & Micro Feedback)

## Current Status & Audit
We have already built the core speech panel and syllables HUD (РО, РИ, РУ) with glowing red tweens.

## Target Enhancements
1. **Dynamic Microphone Volume Level Bar**:
   - Instead of just a flashing emoji, we will draw a sleek horizontal or vertical VU meter (progress bar) in the UI.
   - It will read the microphone's instant volume levels (which we already calculate internally as RMS/amplitude) and update in real-time.
2. **Juicy Micro Feedback (Popping Word Bubbles)**:
   - Spawn a floating text effect (e.g. `РО!`, `РИ!`, `РУ!`) right above the plane node when a syllable is successfully recognized.
   - It will float upward, scale up slightly, and fade out smoothly using a Tween.
3. **Toggleable Speech Debug HUD Panel**:
   - Cleanly pack the debug labels into a sleek, toggleable diagnostic sidebar or drawer, which can be opened/closed.
