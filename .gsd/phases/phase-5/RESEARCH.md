# Research: Phase 5 (Scoreboard System & Collectible Stars)

## Current Status
- Obstacle speed and spawn rates are perfectly constant and comfortable for speech training.
- Game Over screen currently only shows the local absolute high score.

## Target Enhancements
1. **Collectible Stars**:
   - Spawns a glowing `Star` in the vertical gap of each pipe obstacle.
   - Collecting a star gives bonus points with a beautiful tween burst, motivating بچوں/children to sustain their vocal flight path.
2. **Persistent Local Leaderboard (Scoreboard)**:
   - **Name Entry**: Before the game starts (in the "Start" state), we present a sleek, simple text input box (`LineEdit`) where the child or speech therapist can type the child's name (e.g., "Саша", "Лена").
   - **Data Storage**: Scores are stored in a persistent local JSON file `user://leaderboard.json` using Godot's `FileAccess`. Each record stores `{"name": String, "score": int, "date": String}`.
   - **Leaderboard Display**: Upon Game Over, a beautiful, scrollable glassmorphic panel displays the Top 5 all-time high scores of children who played. This motivates positive peer competition during speech classes!
