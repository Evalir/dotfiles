# /// script
# requires-python = ">=3.11"
# dependencies = ["prompt-toolkit==3.0.53", "pexpect==4.9.0"]
# ///
"""uv run shell/tests/test_torvus_ssh.py [--live]. Live checks need Torvus."""

import importlib.util
import os
from pathlib import Path
import signal
import sys
import termios
import time
import unittest

import pexpect

HELPER = Path(__file__).resolve().parents[1] / "bin" / "torvus-ssh.py"
spec = importlib.util.spec_from_file_location("torvus_ssh", HELPER)
helper = importlib.util.module_from_spec(spec)
sys.dont_write_bytecode = True
spec.loader.exec_module(helper)
LIVE = "--live" in sys.argv
if LIVE:
    sys.argv.remove("--live")


class StreamTests(unittest.TestCase):
    def test_fragmented_marker_preserves_other_terminal_metadata(self):
        marker = b"\x1b]777;random-token\x07"
        visible = b"hello\x1b]7501;state=idle:app=codex\x07\x1b]133;C\x07"
        stream = visible + marker + b"world"
        for split in range(len(stream) + 1):
            parser = helper.MarkerStream(marker)
            first, hit1 = parser.feed(stream[:split])
            second, hit2 = parser.feed(stream[split:])
            self.assertEqual(first + second + parser.pending, visible + b"world")
            self.assertTrue(hit1 or hit2)

    def test_marker_one_byte_at_a_time(self):
        marker = b"\x1b]777;token\x07"
        parser = helper.MarkerStream(marker)
        results = [parser.feed(bytes([byte])) for byte in b"x" + marker + b"y"]
        self.assertEqual(b"".join(data for data, _ in results), b"xy")
        self.assertEqual(sum(found for _, found in results), 1)


@unittest.skipUnless(LIVE, "pass --live to connect to Torvus")
class LiveTests(unittest.TestCase):
    def setUp(self):
        self.child = pexpect.spawn(
            sys.executable, [str(HELPER)], encoding="utf-8", timeout=30,
            dimensions=(35, 120), env={**os.environ, "TERM": "xterm-256color"},
        )
        self.terminal = termios.tcgetattr(self.child.child_fd)
        self.addCleanup(lambda: self.child.close(force=True))
        self.prompt()

    def prompt(self):
        self.child.expect_exact("[local]>")

    def test_termination_restores_terminal(self):
        p = self.child
        p.kill(signal.SIGTERM)
        p.expect(pexpect.EOF)
        self.assertEqual(termios.tcgetattr(p.child_fd), self.terminal)
        p.close()
        self.assertEqual(p.exitstatus, 128 + signal.SIGTERM)

    def test_editing_programs_and_metadata(self):
        p = self.child
        p.send("echo LOCAL_")
        start = time.monotonic()
        p.expect_exact("LOCAL_")
        elapsed = time.monotonic() - start
        print(f"\nLocal echo: {elapsed * 1000:.1f} ms", flush=True)
        self.assertLess(elapsed, 0.15)
        p.send("OK\r")
        p.expect_exact("\rLOCAL_OK\r\n")
        self.prompt()

        # Split the prompt text in the command so expect cannot match its echo.
        p.send("python3 -c 'import getpass; v=getpass.getpass(\"Dummy\"+\" password: \"); print(\"HIDDEN_OK\",len(v))'\r")
        p.expect_exact("Dummy password: ")
        p.send("dummy_probe_123")
        with self.assertRaises(pexpect.TIMEOUT):
            p.expect_exact("dummy_probe_123", timeout=0.6)
        p.send("\r")
        p.expect_exact("HIDDEN_OK 15")
        self.prompt()

        p.send("printf '\\e]7501;state=idle:app=codex\\a\\e]133;C\\a'\r")
        p.expect_exact("\x1b]7501;state=idle:app=codex\x07")
        p.expect_exact("\x1b]133;C\x07")
        self.prompt()

        p.send("command -s /usr/bin/unam\t")
        p.expect_exact("\r\x1b[2Ktorvus> ")
        time.sleep(0.5)
        p.send("\r")
        p.expect_exact("\r/usr/bin/uname\r\n")
        self.prompt()

        p.send("nvim -u NONE -i NONE -n\r")
        p.expect_exact("\x1b[?1049h")
        time.sleep(0.3)
        p.send(":q!\r")
        self.prompt()

        p.setwinsize(41, 113)
        time.sleep(0.2)
        p.send("python3 -c 'import os; print(\"SIZE\",tuple(os.get_terminal_size()))'\r")
        p.expect_exact("SIZE (113, 41)")
        self.prompt()

        # Typeahead in the same read as Ctrl-] must reach SSH without lost keys.
        p.send("echo QUICK\x1d_OK\r")
        p.expect_exact("\rQUICK_OK\r\n")
        self.prompt()
        p.send("cd /tmp\r")
        p.expect_exact("torvus:/tmp [local]>")

        p.send("echo BEFORE\x03")
        time.sleep(0.2)
        p.send("echo CANCEL_OK\r")
        p.expect_exact("\rCANCEL_OK\r\n")
        self.prompt()
        p.send("sleep 20\r")
        p.expect_exact("\x1b]133;C;cmdline_url=sleep%2020")
        p.send("\x03")
        self.prompt()

        p.send("exit 7\r")
        p.expect(pexpect.EOF)
        self.assertEqual(termios.tcgetattr(p.child_fd), self.terminal)
        p.close()
        self.assertEqual(p.exitstatus, 7)


if __name__ == "__main__":
    unittest.main()
