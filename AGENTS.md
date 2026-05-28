# Project Rules

## Behavior
- **Manual Start Only**: NEVER perform automatic project analysis, codebase indexing, or build phases on startup. 
- **Wait for Input**: Do not use any tools (grep, glob, read) until the user provides a specific task or command.
- **Greeting**: On startup, provide a simple greeting and wait for instructions. Do not start "Build" or "Plan" phases unsolicited.
- **Explicit Commands**: Only initiate complex workflows (like GSD) when the user explicitly uses the `/gsd` command or asks for an autonomous task.
- **No Unsolicited Research**: Do not attempt to summarize the project structure or "catch up" on state unless the user asks "what's the current state?" or similar.
