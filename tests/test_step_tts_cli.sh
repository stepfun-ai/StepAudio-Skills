#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/skills/step-tts/scripts/tts.sh"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "Making tts.sh executable..."
  chmod +x "$SCRIPT_PATH"
fi

echo "[test] tts.sh --help"
bash "$SCRIPT_PATH" --help >/dev/null

echo "[test] tts.sh speak --help"
bash "$SCRIPT_PATH" speak --help >/dev/null

echo "[test] tts.sh clone-voice --help"
bash "$SCRIPT_PATH" clone-voice --help >/dev/null

echo "All CLI help tests passed."

