#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[test] stepfun_audio_chat.py --help"
python3 "$SCRIPT_PATH" --help >/dev/null

echo "[test] dry-run writes request.json with default audio settings"
python3 "$SCRIPT_PATH" \
  --prompt "hello step-audio" \
  --dry-run \
  --output-dir "$TMP_DIR/default" \
  >"$TMP_DIR/default.stdout"

python3 - "$TMP_DIR/default/request.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

assert payload["model"] == "step-audio-r1.1", payload
assert payload["modalities"] == ["text", "audio"], payload
assert payload["audio"]["voice"] == "wenrounansheng", payload
assert payload["audio"]["format"] == "wav", payload
PY

echo "[test] dry-run supports text-only output mode"
python3 "$SCRIPT_PATH" \
  --prompt "text only turn" \
  --no-audio-output \
  --dry-run \
  --output-dir "$TMP_DIR/text-only" \
  >"$TMP_DIR/text-only.stdout"

python3 - "$TMP_DIR/text-only/request.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

assert payload["modalities"] == ["text"], payload
assert "audio" not in payload, payload
PY

echo "step-audio-r1.1 CLI tests passed."
