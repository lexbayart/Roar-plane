#!/bin/bash
export GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
export GITHUB_PERSONAL_ACCESS_TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN}"

# Запускаем мост. Он будет брать "мозги" из oMLX (8000), а сам встанет на 8001
mcpm-aider start-bridge --port 8001 --openai-api-base http://localhost:8000/v1
