#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/skills/step-tts/scripts/tts.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "Making tts.sh executable..."
  chmod +x "$SCRIPT_PATH"
fi

echo "[test] tts.sh --help"
bash "$SCRIPT_PATH" --help >/dev/null

echo "[test] tts.sh speak --help"
bash "$SCRIPT_PATH" speak --help >"$TMP_DIR/speak-help.txt"
grep -q "default: step-tts-2" "$TMP_DIR/speak-help.txt"
grep -q "default: elegantgentle-female" "$TMP_DIR/speak-help.txt"
grep -q "default: opus" "$TMP_DIR/speak-help.txt"

echo "[test] tts.sh clone-voice --help"
bash "$SCRIPT_PATH" clone-voice --help >/dev/null

echo "All CLI help tests passed."
