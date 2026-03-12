#!/usr/bin/env python3
"""Unit tests for the Step ASR helper functions."""

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = REPO_ROOT / "skills" / "step-asr" / "scripts" / "transcribe.py"

SPEC = importlib.util.spec_from_file_location("step_asr_transcribe", MODULE_PATH)
TRANSCRIBE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(TRANSCRIBE)


class ParseSseLineTests(unittest.TestCase):
    def test_parses_valid_data_event(self):
        event = TRANSCRIBE.parse_sse_line(
            'data: {"type":"transcript.text.delta","delta":"你好"}\n'
        )
        self.assertEqual(event["type"], "transcript.text.delta")
        self.assertEqual(event["delta"], "你好")

    def test_ignores_done_marker(self):
        self.assertIsNone(TRANSCRIBE.parse_sse_line("data: [DONE]\n"))

    def test_ignores_non_data_lines(self):
        self.assertIsNone(TRANSCRIBE.parse_sse_line("event: keepalive\n"))


class LoadApiKeyTests(unittest.TestCase):
    def test_prefers_stepfun_env_var(self):
        with mock.patch.dict(
            os.environ,
            {"STEPFUN_API_KEY": "preferred-key", "STEP_API_KEY": "legacy-key"},
            clear=True,
        ):
            self.assertEqual(TRANSCRIBE.load_api_key(), "preferred-key")

    def test_falls_back_to_legacy_env_var(self):
        with mock.patch.dict(os.environ, {"STEP_API_KEY": "legacy-key"}, clear=True):
            self.assertEqual(TRANSCRIBE.load_api_key(), "legacy-key")

    def test_reads_shared_key_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            key_file = Path(temp_dir) / ".stepfun_api_key"
            key_file.write_text("file-key\n", encoding="utf-8")
            with mock.patch.dict(os.environ, {"HOME": temp_dir}, clear=True):
                self.assertEqual(TRANSCRIBE.load_api_key(), "file-key")


if __name__ == "__main__":
    unittest.main()
