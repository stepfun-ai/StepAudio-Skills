## StepAudio-Skills (StepFun TTS + ASR + Audio Chat skills)

This repository combines three standalone StepFun skills:

- `step-tts`: text-to-speech and voice cloning via StepFun TTS
- `step-asr`: speech-to-text via StepFun ASR streaming API
- `stepfun-step-audio-r1-1`: non-streaming audio chat turns via StepFun Chat Completions (`step-audio-r1.1`)

The three skills share one repo layout, while their underlying implementations remain separate:

- TTS stays in shell: `skills/step-tts/scripts/tts.sh`
- ASR stays in Python: `skills/step-asr/scripts/transcribe.py`
- Audio chat stays in Python: `skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py`

### Layout

- `skills/step-tts/SKILL.md`: Agent-facing description, triggers, and usage examples for TTS / voice clone
- `skills/step-tts/scripts/tts.sh`: Main TTS CLI entrypoint
- `skills/step-asr/SKILL.md`: Agent-facing description, triggers, and usage examples for ASR
- `skills/step-asr/scripts/transcribe.py`: Main ASR CLI entrypoint
- `skills/stepfun-step-audio-r1-1/SKILL.md`: Agent-facing description, triggers, and usage examples for StepFun audio chat
- `skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py`: Main non-streaming StepFun audio chat CLI
- `tests/test_step_tts_cli.sh`: Smoke tests for the TTS CLI help commands
- `tests/test_step_asr_cli.sh`: Smoke tests for the ASR CLI help commands
- `tests/test_stepfun_audio_r1_1_cli.sh`: Smoke tests for the audio-chat CLI

### Prerequisites

- `bash`, `curl`, `python3`
- A valid StepFun API key
- Optional for `stepfun-step-audio-r1-1` local audio normalization: `ffmpeg` or macOS `afconvert`

### Shared API key setup

- Preferred environment variable: `STEPFUN_API_KEY`
- Legacy alias still accepted for compatibility: `STEP_API_KEY`
- The `step-tts` config command stores the key in `~/.stepfun_api_key`
- All three skills read `~/.stepfun_api_key`
- All three skills also read the legacy file `~/.step_api_key` if present

### Basic usage

List skills from this repo (local dev, from repo root):

```bash
npx skills add . --list --full-depth
```

Note for OpenClaw local installs:

- OpenClaw's project-level skill directory is also named `skills/`.
- If you run `npx skills add ... --agent openclaw` **inside this source repository**, the installer may write into the repo's own `skills/` directory and overwrite the source layout.
- For OpenClaw verification, use a separate consumer project directory, or install globally.

Install just the TTS skill:

```bash
npx skills add . --full-depth --skill step-tts -y
```

Install just the ASR skill:

```bash
npx skills add . --full-depth --skill step-asr -y
```

Install just the audio-chat skill:

```bash
npx skills add . --full-depth --skill stepfun-step-audio-r1-1 -y
```

Install all three skills to OpenClaw from a separate consumer project:

```bash
cd /path/to/another/project
npx skills add /path/to/StepAudio-Skills --full-depth --agent openclaw -y
```

### TTS quick start

Configure your TTS API key (saved to `~/.stepfun_api_key`):

```bash
bash skills/step-tts/scripts/tts.sh config --set-api-key YOUR_STEPFUN_API_KEY
```

Generate audio:

```bash
bash skills/step-tts/scripts/tts.sh speak \
  -t "智能阶跃，十倍每一个人的可能" \
  -o step.opus
```

Defaults for `speak`:

- `--model`: `step-tts-2`
- `--voice`: `elegantgentle-female`
- `--response-format`: `opus`

Clone a voice (using an existing `file_id` from StepFun Files API):

```bash
bash skills/step-tts/scripts/tts.sh clone-voice \
  --model step-tts-mini \
  --file-id file-XXXX \
  --text "智能阶跃，十倍每一个人的可能" \
  --sample-text "今天天气不错"
```

The `file_id` must come from the official StepFun Files API:

- Upload your reference audio (5–10 seconds of the voice you want to clone, `mp3` or `wav`) using
  [`POST https://api.stepfun.com/v1/files`](https://platform.stepfun.com/docs/zh/api-reference/files/create)
- Set `purpose="storage"` in the request body
- The response will contain a File object with an `id` like `file-abc123` — pass this value to `--file-id`

### ASR quick start

Set the ASR API key as an environment variable:

```bash
export STEPFUN_API_KEY=YOUR_STEPFUN_API_KEY
```

If you already ran the TTS `config` command, `step-asr` can also reuse the shared key saved in `~/.stepfun_api_key`.

Transcribe an audio file:

```bash
python3 skills/step-asr/scripts/transcribe.py /path/to/audio.wav
```

Save the transcription to a file:

```bash
python3 skills/step-asr/scripts/transcribe.py /path/to/audio.mp3 --out /tmp/transcript.txt
```

Output as JSON:

```bash
python3 skills/step-asr/scripts/transcribe.py /path/to/audio.ogg --json
```

### Audio chat quick start

Reuse the shared StepFun API key from `~/.stepfun_api_key`, or export it directly:

```bash
export STEPFUN_API_KEY=YOUR_STEPFUN_API_KEY
```

Create a non-streaming text-in, audio-out turn:

```bash
python3 skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py \
  --prompt "用中文介绍一下苏州的春天，语气自然一点。" \
  --voice wenrounansheng \
  --format wav
```

Send text plus local audio input:

```bash
python3 skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py \
  --prompt "听完这段语音后，总结重点，并用更简洁的话复述。" \
  --input-audio /path/to/input.wav \
  --voice wenrounansheng \
  --format wav
```

Inspect the generated payload without sending a network request:

```bash
python3 skills/stepfun-step-audio-r1-1/scripts/stepfun_audio_chat.py \
  --prompt "测试 step-audio-r1.1 非流式 payload" \
  --dry-run \
  --print-json
```

### Development smoke tests

Run all CLI and unit tests from the repo root:

```bash
npm test
```
