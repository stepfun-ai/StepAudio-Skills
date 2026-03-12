#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/skills/step-asr/scripts/transcribe.py"

echo "[test] transcribe.py --help"
python3 "$SCRIPT_PATH" --help >/dev/null

echo "ASR CLI help test passed."
