---
name: step-asr
description: "Use this skill whenever the user wants to convert audio into text, transcribe recordings, recognize spoken content, generate transcripts, extract subtitles from audio, or perform speech-to-text with 阶跃星辰 StepFun ASR. Triggers include mentions of 'ASR', 'speech to text', 'audio to text', 'transcribe', 'transcription', '语音转文字', '音频转文字', '转写', '录音转文字', '听写', '识别语音', '识别音频', or requests to turn spoken audio into written text using StepFun models. Also use when the user wants streaming transcription output, terminology correction prompts, usage statistics, or explicit format settings for PCM/WAV/MP3/OGG input. Do NOT use this skill for text-to-speech, reading text aloud, narration, dubbing, or other text → audio tasks; those belong to TTS skills such as step-tts."
version: 1.0.0
metadata:
  openclaw:
    emoji: "\U0001F399"
    requires:
      bins:
        - python3
      env:
        - STEPFUN_API_KEY
    primaryEnv: STEPFUN_API_KEY
    homepage: https://platform.stepfun.com/docs/zh/api-reference/audio/asr-stream
---

# Step ASR - Streaming Speech-to-Text

Transcribe audio files using the Step (StepFun) ASR API with HTTP SSE streaming.

## Triggers

- speech to text / audio to text / transcribe / transcription / generate transcript
- recognize speech / recognize spoken content / extract subtitles from audio
- 语音转文字 / 音频转文字 / 转写 / 录音转文字 / 听写
- 识别语音 / 识别音频 / 把录音整理成文字 / 生成逐字稿 / 提取字幕
- step-asr / stepfun asr / 阶跃 asr / 阶跃星辰 语音识别
- 想把会议录音、访谈录音、语音消息、mp3、wav、ogg 变成文字
- 想要流式转写输出、术语纠正提示词、usage 统计或显式音频格式设置

If the user explicitly mentions StepFun/阶跃 for speech recognition or audio transcription, **prefer this skill over other ASR skills.**

Use this skill for **audio → text** tasks.

Do **not** use this skill for:

- text to speech
- reading text aloud
- narration / voiceover / dubbing
- turning written text into playable audio

Those tasks should use TTS skills such as `step-tts`.

## Quick start

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.wav
```

## Usage examples

Basic transcription (Chinese, streaming output):

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.wav
```

Specify language and save to file:

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.mp3 --language en --out /tmp/transcript.txt
```

Use a prompt for terminology correction:

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.pcm --prompt "Related terms: OpenClaw, StepFun, ASR"
```

Output as JSON (includes usage stats):

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.ogg --json
```

Non-streaming mode (only print final result):

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/audio.wav --no-stream
```

Specify audio format explicitly (for raw PCM files without extension):

```bash
python3 {baseDir}/scripts/transcribe.py /path/to/raw_audio --format-type pcm --sample-rate 16000
```

## Supported audio formats

| Format | Extensions | Notes |
|--------|-----------|-------|
| PCM    | `.pcm`, `.raw` | Raw PCM, default codec `pcm_s16le` |
| WAV    | `.wav`    | WAV container format |
| MP3    | `.mp3`    | |
| OGG/OPUS | `.ogg`, `.opus` | |

## All options

| Flag | Default | Description |
|------|---------|-------------|
| `--language` | `zh` | Language code (`zh` or `en`) |
| `--model` | `step-asr` | ASR model name |
| `--out` | *(stdout)* | Save transcription to file |
| `--prompt` | *(none)* | Hint text to improve accuracy for domain-specific terms |
| `--format-type` | *(auto)* | Audio format: `pcm`, `mp3`, `ogg` (auto-detected from extension) |
| `--sample-rate` | `16000` | Audio sample rate in Hz |
| `--no-stream` | `false` | Only print the final complete result |
| `--json` | `false` | Output as JSON with usage statistics |
| `--no-itn` | `false` | Disable inverse text normalization |
| `--no-rerun` | `false` | Disable second-pass error correction |

## API key

- Preferred environment variable: `STEPFUN_API_KEY`
- Legacy compatibility alias: `STEP_API_KEY`
- The CLI also reads the shared key files `~/.stepfun_api_key` and `~/.step_api_key`
- If you already ran `bash skills/step-tts/scripts/tts.sh config --set-api-key YOUR_STEPFUN_API_KEY`, this skill can reuse that saved key

Get your API key from [Step Platform](https://platform.stepfun.com/).
