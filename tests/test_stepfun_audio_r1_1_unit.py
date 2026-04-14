#!/usr/bin/env python3
"""Unit tests for the StepFun step-audio-r1.1 helper functions."""

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = (
    REPO_ROOT
    / "skills"
    / "stepfun-step-audio-r1-1"
    / "scripts"
    / "stepfun_audio_chat.py"
)

SPEC = importlib.util.spec_from_file_location("stepfun_audio_chat", MODULE_PATH)
AUDIO_CHAT = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(AUDIO_CHAT)


class ResolveApiKeyTests(unittest.TestCase):
    def test_prefers_stepfun_env_var(self):
        with mock.patch.dict(
            os.environ,
            {"STEPFUN_API_KEY": "preferred-key", "STEP_API_KEY": "legacy-key"},
            clear=True,
        ):
            self.assertEqual(AUDIO_CHAT.resolve_api_key(), "preferred-key")

    def test_falls_back_to_legacy_env_var(self):
        with mock.patch.dict(os.environ, {"STEP_API_KEY": "legacy-key"}, clear=True):
            self.assertEqual(AUDIO_CHAT.resolve_api_key(), "legacy-key")

    def test_reads_shared_key_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            key_file = Path(temp_dir) / ".stepfun_api_key"
            key_file.write_text("file-key\n", encoding="utf-8")
            with mock.patch.dict(os.environ, {"HOME": temp_dir}, clear=True):
                self.assertEqual(AUDIO_CHAT.resolve_api_key(), "file-key")


class BuildPayloadTests(unittest.TestCase):
    def test_builds_default_audio_payload(self):
        args = SimpleNamespace(
            prompt="hello",
            system="",
            input_audio="",
            model="step-audio-r1.1",
            voice="wenrounansheng",
            format="wav",
            api_base_url="https://api.stepfun.com",
            temperature=None,
            max_tokens=None,
            output_dir="",
            print_json=False,
            dry_run=True,
            no_audio_output=False,
            list_voices=False,
            voice_limit=20,
        )
        payload = AUDIO_CHAT.build_payload(args)
        self.assertEqual(payload["modalities"], ["text", "audio"])
        self.assertEqual(payload["audio"]["voice"], "wenrounansheng")


if __name__ == "__main__":
    unittest.main()
