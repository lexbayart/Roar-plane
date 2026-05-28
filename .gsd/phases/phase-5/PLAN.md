# Plan: Phase 5 (Scoreboard System & Collectible Stars)

## Wave 1: Collectible Stars System
- **Files**: Create `scenes/Star.tscn`, `scripts/Star.gd`, edit `scripts/Main.gd`
- **Actions**:
  - Implement dynamic star spawning: spawn a star in the middle gap of each pipe obstacle.
  - Animate the star to scroll left in tandem with pipes.
  - When the plane collides with the star (Area2D), trigger a gorgeous puff particle/tween effect, award bonus points, and delete it.
- **Verification**: Collect stars to verify points are awarded and tween animations trigger.

## Wave 2: Local Persistent Leaderboard (Name Entry & Scoreboard)
- **Files**: `scripts/GameState.gd`, `scripts/Main.gd`
- **Actions**:
  - **Leaderboard Storage (`GameState.gd`)**:
    - Manage a list of player high scores: read from and write to `user://leaderboard.json`.
    - Method `save_score(player_name: String, score: int)` which adds the record, sorts in descending order, and saves.
  - **UI Integration (`Main.gd`)**:
    - **Start Screen**: Add a beautiful centered LineEdit (`player_name_input`) for entering the child's name. Focus it immediately.
    - **Game Over Screen**: Hide standard best score, and instead show a premium, glassmorphic table presenting the Top 5 rankings (e.g. `#1  Маша  52 очка`).
- **Verification**: Type a name, play a session, crash, and confirm the new score persistent table populates correctly under Game Over!
