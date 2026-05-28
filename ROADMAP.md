# Roadmap: Roar-plane

Phased plan for stabilizing, developing, and shipping the Roar-plane voice-controlled practice game.

## Milestone 1: Stabilization & Verification (v0.1)

### Phase 1: Codebase Audit & Mapping
- [ ] Map all files, nodes, and dependencies in `/Users/usara/roar-plane`.
- [ ] Document code structure and connections in `PROJECT.md`.
- [ ] Verify local Python 3 and VOSK installations.

### Phase 2: Python Bridge Optimization
- [ ] Test `vosk_bridge.py` independently to measure latency.
- [ ] Optimize the communication pipe (GDScript `OS.execute` vs background socket thread) to reduce lag.
- [ ] Add exception handling to prevent game freezes on microphone disconnect.

### Phase 3: Physics & Lift Tuning
- [ ] Rebalance plane weight, flap impulse, and gravity to compensate for VOSK latency.
- [ ] Ensure smooth transitions between wing-flapping animations.

---

## Milestone 2: Game Features & UI (v0.2)

### Phase 4: UI Enhancements & Micro Feedback
- [ ] Add an active microphone volume indicator.
- [ ] Show temporary visual highlights when an "R" word is successfully detected (e.g., word bubble).
- [ ] Build a sleek "Speech Status" panel to help debug mic levels in-game.

### Phase 5: Level Progression & Obstacles
- [ ] Implement varied pipe spacing and heights as score increases.
- [ ] Add collectible stars or fuel canisters to reward sustained "R" phonetic output.

---

## Milestone 3: Shipping & Bundling (v1.0)

### Phase 6: Build Configs & Bundling
- [ ] Setup Godot 4.x export presets for macOS (app bundle) and Windows.
- [ ] Write post-export script to auto-copy `vosk_models/` into the app bundle resources directory.
- [ ] Document final installation and gameplay instructions in README.
