#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/skills/step-tts/scripts/tts.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[test] speak rejects missing output"
if bash "$SCRIPT_PATH" speak \
  -t "hello" \
  --model step-tts-mini \
  --voice cixingnansheng \
  >"$TMP_DIR/missing-output.stdout" 2>"$TMP_DIR/missing-output.stderr"; then
  echo "Expected missing output validation to fail." >&2
  exit 1
fi
grep -q -- "--output (-o) is required" "$TMP_DIR/missing-output.stderr"

echo "[test] speak rejects mutually exclusive voice labels"
if bash "$SCRIPT_PATH" speak \
  -t "hello" \
  --model step-tts-mini \
  --voice cixingnansheng \
  --emotion 高兴 \
  --style 慢速 \
  -o "$TMP_DIR/out.mp3" \
  >"$TMP_DIR/mutually-exclusive.stdout" 2>"$TMP_DIR/mutually-exclusive.stderr"; then
  echo "Expected mutually exclusive validation to fail." >&2
  exit 1
fi
grep -q "mutually exclusive" "$TMP_DIR/mutually-exclusive.stderr"

echo "[test] clone-voice rejects missing file id"
if bash "$SCRIPT_PATH" clone-voice \
  --model step-tts-mini \
  >"$TMP_DIR/missing-file-id.stdout" 2>"$TMP_DIR/missing-file-id.stderr"; then
  echo "Expected missing file id validation to fail." >&2
  exit 1
fi
grep -q -- "--file-id is required" "$TMP_DIR/missing-file-id.stderr"

echo "[test] speak uses default model voice and format"
FAKE_BIN_DIR="$TMP_DIR/fake-bin"
mkdir -p "$FAKE_BIN_DIR"
cat >"$FAKE_BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

payload=""
headers_file=""
out_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --data)
      payload="$2"
      shift 2
      ;;
    -D)
      headers_file="$2"
      shift 2
      ;;
    -o)
      out_file="$2"
      shift 2
      ;;
    -H| -X| -w)
      shift 2
      ;;
    -s|-S|-sS)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

printf '%s' "$payload" >"$FAKE_CURL_PAYLOAD_FILE"
printf 'Content-Type: audio/ogg\r\n' >"$headers_file"
printf 'fake audio' >"$out_file"
printf '200'
EOF
chmod +x "$FAKE_BIN_DIR/curl"

DEFAULT_PAYLOAD="$TMP_DIR/default-payload.json"
STEPFUN_API_KEY=test-key \
FAKE_CURL_PAYLOAD_FILE="$DEFAULT_PAYLOAD" \
PATH="$FAKE_BIN_DIR:$PATH" \
bash "$SCRIPT_PATH" speak \
  -t "hello default" \
  -o "$TMP_DIR/default.opus" \
  >"$TMP_DIR/default.stdout" 2>"$TMP_DIR/default.stderr"

python3 - "$DEFAULT_PAYLOAD" <<'PY'
import json
import sys

payload_path = sys.argv[1]
with open(payload_path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

assert payload["model"] == "step-tts-2", payload
assert payload["voice"] == "elegantgentle-female", payload
assert payload["response_format"] == "opus", payload
PY

echo "[test] speak respects explicit model voice and format"
OVERRIDE_PAYLOAD="$TMP_DIR/override-payload.json"
STEPFUN_API_KEY=test-key \
FAKE_CURL_PAYLOAD_FILE="$OVERRIDE_PAYLOAD" \
PATH="$FAKE_BIN_DIR:$PATH" \
bash "$SCRIPT_PATH" speak \
  -t "hello override" \
  --model step-tts-mini \
  --voice cixingnansheng \
  --response-format mp3 \
  -o "$TMP_DIR/override.mp3" \
  >"$TMP_DIR/override.stdout" 2>"$TMP_DIR/override.stderr"

python3 - "$OVERRIDE_PAYLOAD" <<'PY'
import json
import sys

payload_path = sys.argv[1]
with open(payload_path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

assert payload["model"] == "step-tts-mini", payload
assert payload["voice"] == "cixingnansheng", payload
assert payload["response_format"] == "mp3", payload
PY

echo "TTS validation tests passed."
