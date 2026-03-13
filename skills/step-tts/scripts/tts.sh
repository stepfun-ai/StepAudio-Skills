#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STEP_KEY_FILE="$HOME/.stepfun_api_key"
STEP_LEGACY_KEY_FILE="$HOME/.step_api_key"
STEP_BASE_URL="https://api.stepfun.com/v1"

usage_root() {
  cat <<'EOF'
Usage:
  tts.sh speak [options]         — text to audio via StepFun TTS
  tts.sh clone-voice [options]   — clone a voice via StepFun audio/voices
  tts.sh config [options]        — check / set STEPFUN_API_KEY

Examples:
  # Configure API key (saved to ~/.stepfun_api_key)
  tts.sh config --set-api-key YOUR_STEPFUN_API_KEY

  # Simple TTS
  tts.sh speak -t "智能阶跃，十倍每一个人的可能" \
    -o step.opus

  # With emotion / style
  tts.sh speak -t "今天的学习进度很棒，我们继续加油！" \
    --model step-tts-mini \
    --voice livelybreezy-female \
    --emotion 高兴 \
    --speed 1.1 \
    -o cheer.opus

  # Clone a voice
  tts.sh clone-voice \
    --model step-tts-mini \
    --file-id file-Ckyl3cV09A \
    --text "智能阶跃，十倍每一个人的可能" \
    --sample-text "今天天气不错"
EOF
  exit "${1:-0}"
}

usage_speak() {
  cat <<'EOF'
Usage:
  tts.sh speak [options]

Required:
  -t, --text TEXT           Text to synthesize
  -f, --text-file FILE      Or: file containing text (UTF-8)
  -o, --output FILE         Output audio file path

Optional:
  --model NAME              StepFun TTS model: step-tts-2 | step-tts-mini | step-tts-vivid
                            (default: step-tts-2)
  --voice ID                StepFun voice ID / official voice name
                            (default: elegantgentle-female)
  --response-format FMT     wav | mp3 | flac | opus | pcm (default: opus)
  --speed NUM               Speaking rate (0.5 ~ 2.0, default 1.0)
  --volume NUM              Volume (0.1 ~ 2.0, default 1.0)
  --emotion LABEL           Emotion label -> voice_label.emotion
  --style LABEL             Style label -> voice_label.style
  --language LABEL          Language label -> voice_label.language
                            NOTE: emotion/style/language are mutually exclusive; only one should be set.
  --sample-rate NUM         Sample rate: 8000 | 16000 | 22050 | 24000 (default 24000)

Notes:
  - This command calls POST /v1/audio/speech from StepFun:
    https://platform.stepfun.com/docs/zh/api-reference/audio/create_audio
EOF
  exit "${1:-0}"
}

usage_clone_voice() {
  cat <<'EOF'
Usage:
  tts.sh clone-voice [options]

Required:
  --model NAME              StepFun model: step-tts-2 | step-tts-mini | step-tts-vivid | step-audio-2
  --file-id ID              File ID of reference audio (uploaded via Files API, purpose=storage, 5-10s mp3/wav)

Optional:
  --text TEXT               Transcript of the source audio (recommended)
  --sample-text TEXT        Text used to generate a sample audio (<= 50 chars)

Notes:
  - This command calls POST /v1/audio/voices:
    https://platform.stepfun.com/docs/zh/api-reference/audio/create_voice
  - The full JSON response (including new voice id) is printed to stdout.
EOF
  exit "${1:-0}"
}

# ── API key persistence ──────────────────────────────────────────────

load_api_key() {
  if [[ -n "${STEPFUN_API_KEY:-}" ]]; then
    STEP_API_KEY="$STEPFUN_API_KEY"
    export STEPFUN_API_KEY STEP_API_KEY
    return 0
  fi
  if [[ -n "${STEP_API_KEY:-}" ]]; then
    STEPFUN_API_KEY="$STEP_API_KEY"
    export STEPFUN_API_KEY STEP_API_KEY
    return 0
  fi
  local key_file=""
  local key_value=""
  for key_file in "$STEP_KEY_FILE" "$STEP_LEGACY_KEY_FILE"; do
    if [[ -f "$key_file" ]]; then
      key_value="$(tr -d '[:space:]' < "$key_file")"
      if [[ -n "$key_value" ]]; then
        STEPFUN_API_KEY="$key_value"
        STEP_API_KEY="$key_value"
        export STEPFUN_API_KEY STEP_API_KEY
        return 0
      fi
    fi
  done
  return 1
}

save_api_key() {
  local raw="$1"
  printf '%s' "$raw" > "$STEP_KEY_FILE"
  chmod 600 "$STEP_KEY_FILE"
}

cmd_config() {
  local set_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --set-api-key) set_key="$2"; shift 2 ;;
      -h|--help) echo "Usage: tts.sh config [--set-api-key KEY]"; exit 0 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -n "$set_key" ]]; then
    save_api_key "$set_key"
    echo "STEPFUN_API_KEY saved to $STEP_KEY_FILE"
    return 0
  fi

  if load_api_key; then
    local masked="${STEPFUN_API_KEY:0:4}****${STEPFUN_API_KEY: -4}"
    echo "STEPFUN_API_KEY is configured: $masked"
  else
    echo "STEPFUN_API_KEY is NOT configured." >&2
    echo "Set it via: tts.sh config --set-api-key YOUR_STEPFUN_API_KEY" >&2
    exit 1
  fi
}

ensure_api_key() {
  load_api_key || true
  if [[ -z "${STEPFUN_API_KEY:-}" ]]; then
    echo "Error: STEPFUN_API_KEY is not configured." >&2
    echo "  Get your key from StepFun: https://platform.stepfun.com" >&2
    echo "  Then run: bash skills/step-tts/scripts/tts.sh config --set-api-key YOUR_STEPFUN_API_KEY" >&2
    exit 1
  fi
}

# ── Helpers ──────────────────────────────────────────────────────────

post_json_to_step() {
  local path="$1"
  local data="$2"
  local out_file="${3:-}"
  local tmp_body=""
  local tmp_headers=""
  local http_code=""
  local content_type=""

  ensure_api_key

  tmp_body="$(mktemp)"
  tmp_headers="$(mktemp)"

  http_code="$(curl -sS -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $STEPFUN_API_KEY" \
    --data "$data" \
    -D "$tmp_headers" \
    -o "$tmp_body" \
    -w '%{http_code}' \
    "$STEP_BASE_URL$path")" || {
      local curl_status=$?
      rm -f "$tmp_body" "$tmp_headers"
      return "$curl_status"
    }

  if [[ ! "$http_code" =~ ^2 ]]; then
    echo "Error: StepFun API request failed (HTTP $http_code)." >&2
    if [[ -s "$tmp_body" ]]; then
      cat "$tmp_body" >&2
      echo >&2
    fi
    rm -f "$tmp_body" "$tmp_headers"
    return 1
  fi

  content_type="$(awk 'BEGIN { IGNORECASE = 1 } /^Content-Type:/ { gsub(/\r/, "", $2); print tolower($2) }' "$tmp_headers" | tail -n 1)"

  if [[ -n "$out_file" ]]; then
    if [[ "$content_type" == application/json* ]]; then
      echo "Error: Expected audio output but received JSON from StepFun." >&2
      if [[ -s "$tmp_body" ]]; then
        cat "$tmp_body" >&2
        echo >&2
      fi
      rm -f "$tmp_body" "$tmp_headers"
      return 1
    fi
    mv "$tmp_body" "$out_file"
    rm -f "$tmp_headers"
  else
    cat "$tmp_body"
    rm -f "$tmp_body" "$tmp_headers"
  fi
}

build_speech_payload() {
  local model="$1" input_text="$2" voice="$3"
  local response_format="$4" speed="$5" volume="$6"
  local emotion="$7" style="$8" language="$9" sample_rate="${10}"

  python3 - "$model" "$input_text" "$voice" "$response_format" "$speed" "$volume" \
    "$emotion" "$style" "$language" "$sample_rate" <<'PY'
import json
import sys

model, text, voice, response_format, speed, volume, emotion, style, language, sample_rate = sys.argv[1:11]

body = {
    "model": model,
    "input": text,
    "voice": voice,
}

if response_format:
    body["response_format"] = response_format
if speed:
    body["speed"] = float(speed)
if volume:
    body["volume"] = float(volume)
if sample_rate:
    body["sample_rate"] = int(sample_rate)

voice_label = {}
if emotion:
    voice_label["emotion"] = emotion
if style:
    voice_label["style"] = style
if language:
    voice_label["language"] = language
if voice_label:
    body["voice_label"] = voice_label

print(json.dumps(body, ensure_ascii=False))
PY
}

build_clone_voice_payload() {
  local model="$1" text="$2" file_id="$3" sample_text="$4"

  python3 - "$model" "$text" "$file_id" "$sample_text" <<'PY'
import json
import sys

model, text, file_id, sample_text = sys.argv[1:5]

body = {
    "model": model,
    "file_id": file_id,
}
if text:
    body["text"] = text
if sample_text:
    body["sample_text"] = sample_text

print(json.dumps(body, ensure_ascii=False))
PY
}

# ── Commands ─────────────────────────────────────────────────────────

cmd_speak() {
  local text="" text_file="" output="" model="step-tts-2" voice="elegantgentle-female"
  local response_format="opus" speed="" volume=""
  local emotion="" style="" language="" sample_rate="24000"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--text) text="$2"; shift 2 ;;
      -f|--text-file) text_file="$2"; shift 2 ;;
      -o|--output) output="$2"; shift 2 ;;
      --model) model="$2"; shift 2 ;;
      --voice) voice="$2"; shift 2 ;;
      --response-format) response_format="$2"; shift 2 ;;
      --speed) speed="$2"; shift 2 ;;
      --volume) volume="$2"; shift 2 ;;
      --emotion) emotion="$2"; shift 2 ;;
      --style) style="$2"; shift 2 ;;
      --language) language="$2"; shift 2 ;;
      --sample-rate) sample_rate="$2"; shift 2 ;;
      -h|--help) usage_speak 0 ;;
      *) echo "Unknown option for speak: $1" >&2; usage_speak 1 ;;
    esac
  done

  if [[ -z "$output" ]]; then
    echo "Error: --output (-o) is required." >&2; exit 1
  fi
  if [[ -z "$text" && -z "$text_file" ]]; then
    echo "Error: --text (-t) or --text-file (-f) is required." >&2; exit 1
  fi
  if [[ -n "$text_file" && -z "$text" ]]; then
    text="$(<"$text_file")"
  fi

  if [[ -n "$emotion" && ( -n "$style" || -n "$language" ) ]] || \
     [[ -n "$style" && -n "$language" ]]; then
    echo "Error: --emotion, --style, --language are mutually exclusive; only one may be set." >&2
    exit 1
  fi

  local payload
  payload="$(build_speech_payload "$model" "$text" "$voice" "$response_format" \
    "$speed" "$volume" "$emotion" "$style" "$language" "$sample_rate")"

  post_json_to_step "/audio/speech" "$payload" "$output"
  echo "Audio saved to: $output" >&2
}

cmd_clone_voice() {
  local model="" file_id="" text="" sample_text=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --file-id) file_id="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --sample-text) sample_text="$2"; shift 2 ;;
      -h|--help) usage_clone_voice 0 ;;
      *) echo "Unknown option for clone-voice: $1" >&2; usage_clone_voice 1 ;;
    esac
  done

  if [[ -z "$model" ]]; then
    echo "Error: --model is required." >&2; exit 1
  fi
  if [[ -z "$file_id" ]]; then
    echo "Error: --file-id is required." >&2; exit 1
  fi

  local payload
  payload="$(build_clone_voice_payload "$model" "$text" "$file_id" "$sample_text")"

  post_json_to_step "/audio/voices" "$payload"
}

# ── Entrypoint ───────────────────────────────────────────────────────

case "${1:-}" in
  speak) shift; cmd_speak "$@" ;;
  clone-voice|clone_voice) shift; cmd_clone_voice "$@" ;;
  config) shift; cmd_config "$@" ;;
  -h|--help|"") usage_root 0 ;;
  *) echo "Unknown command: $1" >&2; usage_root 1 ;;
esac
