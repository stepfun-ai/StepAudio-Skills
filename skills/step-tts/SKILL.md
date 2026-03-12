---
name: step-tts
description: "Use this skill whenever the user wants to convert text into speech, generate playable audio from written text, read a sentence aloud, narrate content, create voiceovers, or clone / customize voices, and the backend must be 阶跃星辰 StepFun TTS. Triggers include mentions of 'TTS', 'text to speech', 'step-tts', 'stepfun', '阶跃', '语音合成', '生成语音', '转成语音', '读出来', '念出来', '朗读', '配音', '旁白', '播报', or requests to turn written content into spoken audio using StepFun models. Also use when the user wants to control StepFun voice IDs, speed, volume, emotion/style tags (情绪/风格标签), or call the StepFun voice-clone API with an existing file_id. Do NOT use this skill for speech recognition or audio-to-text tasks; those belong to ASR skills. Do NOT use this skill for Noiz or Kokoro backends."
version: 1.0.0
metadata:
  openclaw:
    emoji: "\U0001F50A"
    requires:
      bins:
        - bash
        - curl
        - python3
      env:
        - STEPFUN_API_KEY
    primaryEnv: STEPFUN_API_KEY
    homepage: https://platform.stepfun.com/docs/zh/guide/tts
---

# step-tts

Use 阶跃星辰 StepFun TTS (models `step-tts-2`, `step-tts-mini`, `step-tts-vivid`) as the backend for all text-to-speech and voice-clone operations.

This mirrors the spirit of the original [`tts` skill](https://github.com/NoizAI/skills/tree/main/skills/tts), but **all network calls go to the StepFun APIs**:

- 语音合成（Text → Speech）：[`POST /v1/audio/speech`](https://platform.stepfun.com/docs/zh/api-reference/audio/create_audio)
- 复刻音色（Voice Clone）：[`POST /v1/audio/voices`](https://platform.stepfun.com/docs/zh/api-reference/audio/create_voice)

For StepFun best-practice guidance and official voice list, refer to the docs:  
[`音频合成最佳实践`](https://platform.stepfun.com/docs/zh/guide/tts#%E5%AE%98%E6%96%B9%E9%9F%B3%E8%89%B2%E6%B8%85%E5%8D%95)

## Triggers

- text to speech / tts / speak / say / read aloud / narration / voiceover
- 语音合成 / 生成语音 / 转成语音 / 合成语音
- 读出来 / 念出来 / 朗读 / 朗读一下 / 帮我读一下 / 读一遍
- 配音 / 旁白 / 播报 / 口播 / 文案配音
- step-tts / stepfun / 阶跃 / 阶跃星辰 语音
- 想把一句话、一段文字、文案、脚本、文章变成可播放的语音
- 想用具体 StepFun 模型或官方音色（例如 `step-tts-mini` + `cixingnansheng`）
- 想根据 StepFun 文档里的情绪 / 风格标签（如「高兴」「慢速」）调节说话方式
- 想基于已有 `file_id` 调用 StepFun 的「音色复刻」接口

If the user explicitly mentions StepFun/阶跃 for TTS, **prefer this skill over other TTS skills.**

Use this skill for **text → audio** tasks.

Do **not** use this skill for:

- speech recognition
- audio transcription
- audio → text
- extracting subtitles from audio

Those tasks should use ASR skills such as `step-asr`.

## Requirements

- A valid StepFun API key. Preferred env var: `STEPFUN_API_KEY`.
- Legacy env var `STEP_API_KEY` is still accepted for compatibility.
- CLI dependencies: `bash`, `curl`, `python3`.

The API key is sent as:

- Header: `Authorization: Bearer STEPFUN_API_KEY`

You can configure it once via the `config` command (see below).

## CLI: `tts.sh`

Main entrypoint: `skills/step-tts/scripts/tts.sh`

### 1. Configure API key

```bash
bash skills/step-tts/scripts/tts.sh config --set-api-key YOUR_STEPFUN_API_KEY
```

This writes the key (without the `Bearer` prefix) into `~/.stepfun_api_key` and uses it automatically for all later calls.  
If `STEPFUN_API_KEY` is set in the environment, it takes precedence. The legacy env var `STEP_API_KEY` and legacy file `~/.step_api_key` are also supported.

Check the current configuration:

```bash
bash skills/step-tts/scripts/tts.sh config
```

The key will be printed in masked form.

### 2. Simple text → audio (`speak`)

Backed by [`POST https://api.stepfun.com/v1/audio/speech`](https://platform.stepfun.com/docs/zh/api-reference/audio/create_audio).

```bash
# Minimal
bash skills/step-tts/scripts/tts.sh speak \
  -t "智能阶跃，十倍每一个人的可能" \
  --model step-tts-mini \
  --voice cixingnansheng \
  -o step.mp3

# From text file
bash skills/step-tts/scripts/tts.sh speak \
  -f article.txt \
  --model step-tts-2 \
  --voice elegantgentle-female \
  --response-format mp3 \
  -o article.mp3

# With speed / volume / emotion / style
bash skills/step-tts/scripts/tts.sh speak \
  -t "今天的学习进度很棒，我们继续加油！" \
  --model step-tts-mini \
  --voice livelybreezy-female \
  --speed 1.1 \
  --volume 1.2 \
  --emotion 高兴 \
  -o cheer.mp3
```

**Key options (mapped 1:1 to StepFun audio/speech API):**

- `--model` (required): `step-tts-2` | `step-tts-mini` | `step-tts-vivid`
- `--voice` (required): one of StepFun 官方音色 `voice` / `voice_id`，例如：
  - `cixingnansheng`
  - `elegantgentle-female`
  - `yuanqishaonv`
  - See full list in 官方文档: [`官方音色清单`](https://platform.stepfun.com/docs/zh/guide/tts#%E5%AE%98%E6%96%B9%E9%9F%B3%E8%89%B2%E6%B8%85%E5%8D%95)
- `--response-format`: `wav` | `mp3` | `flac` | `opus` | `pcm` (default: `mp3`)
- `--speed`: `0.5~2.0` （语速）
- `--volume`: `0.1~2.0` （音量）
- `--emotion`: 情绪标签，对应 `voice_label.emotion`（如：`高兴`、`悲伤`、`生气` 等）
- `--style`: 语速 / 演绎风格标签，对应 `voice_label.style`（如：`慢速`、`极快`、`温柔` 等）
- `--language`: 语言标签，对应 `voice_label.language`（如：`粤语`、`四川话`、`日语`），三者和 emotion/style 只可三选一。
- `--sample-rate`: 采样率，支持 `8000`、`16000`、`22050`、`24000`，默认 `24000`。

### 3. Voice clone (`clone-voice`)

Backed by [`POST https://api.stepfun.com/v1/audio/voices`](https://platform.stepfun.com/docs/zh/api-reference/audio/create_voice).

```bash
bash skills/step-tts/scripts/tts.sh clone-voice \
  --model step-tts-mini \
  --file-id file-Ckyl3cV09A \
  --text "智能阶跃，十倍每一个人的可能" \
  --sample-text "今天天气不错"
```

**Note: 如何获得 `file_id`（音色复刻的前提）**

This command assumes you have already uploaded the reference audio via the **StepFun Files API** and obtained a `file_id`:

- Use [`POST https://api.stepfun.com/v1/files`](https://platform.stepfun.com/docs/zh/api-reference/files/create)
- Set `purpose="storage"`
- Upload a **5–10 second** `mp3` or `wav` clip that contains the voice you want to clone  
  （例如：特朗普、某个主播、或你自己的声音）
- The response will be a File object with an `id` like `file-abc123` — this is the value to pass to `--file-id`

Example curl (simplified from the StepFun docs):

```bash
curl https://api.stepfun.com/v1/files \
  -H "Authorization: Bearer $STEPFUN_API_KEY" \
  -F purpose="storage" \
  -F file="@trump_sample.wav"
```

Once you have the returned `id`, you can call:

```bash
bash skills/step-tts/scripts/tts.sh clone-voice \
  --model step-tts-mini \
  --file-id file-abc123 \
  --text "智能阶跃，十倍每一个人的可能" \
  --sample-text "今天天气不错"
```

CLI options:

- `--model` (required): one of StepFun TTS models, e.g. `step-tts-mini`
- `--file-id` (required): File ID of reference audio
- `--text` (optional): 原始音频对应文本，不传则由系统 ASR 自动识别（官方建议传入以提升质量）
- `--sample-text` (optional): 用于生成试听音频的文本（最多 50 个字）

Response JSON (printed to stdout) contains:

- `id`: 新音色 ID，可直接用在 `--voice` 字段里
- `sample_audio`: base64 编码的试听 wav，可自行解码保存

### 4. Help

```bash
bash skills/step-tts/scripts/tts.sh --help
bash skills/step-tts/scripts/tts.sh speak --help
bash skills/step-tts/scripts/tts.sh clone-voice --help
```

## Agent Guidance

When using this skill:

- **Prefer StepFun voices / labels** as documented in [`音频合成最佳实践`](https://platform.stepfun.com/docs/zh/guide/tts#%E5%AE%98%E6%96%B9%E9%9F%B3%E8%89%B2%E6%B8%85%E5%8D%95) instead of Noiz or Kokoro names.
- When the user asks for a type of voice (e.g. “营销女声”, “有声书男声”), choose an appropriate `voice` and optional emotion/style tags from the StepFun docs. The guide at [`https://platform.stepfun.com/docs/zh/guide/tts`](https://platform.stepfun.com/docs/zh/guide/tts) contains per‑scenario recommendations and the full 官方音色清单。
- In the 官方音色清单 table, the **first 7 voices are the most recommended defaults by StepFun**. When the user does not care about the exact voice and just wants “good” audio, prefer those top 7 voices as sensible defaults.
- For cloning tasks, clearly inform the user that they must first upload audio to StepFun to get a `file_id`, then this skill can call `clone-voice` to create a reusable voice ID.
- If the user previously used the `tts` skill with Noiz, you can suggest migrating parameters (text, SRT, high-level emotion) while switching backend to StepFun via this skill.
