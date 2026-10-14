# /// script
# requires-python = ">=3.11"
# dependencies = ["prompt-toolkit==3.0.53"]
# ///
"""Local shell-line editing around OpenSSH; remote programs keep raw input.

The session-only fish hooks identify real shell prompts, never password prompts.
Only our random OSC marker is consumed; other terminal output passes through.
"""

import asyncio
import contextlib
import errno
import fcntl
import os
import pty
import re
import secrets
import shlex
import signal
import sys
import termios
import tty
from urllib.parse import unquote, urlsplit

from prompt_toolkit import PromptSession
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.input.typeahead import get_typeahead
from prompt_toolkit.output.defaults import create_output


class MarkerStream:
    """Recognize a marker even when an SSH read splits it between packets."""

    def __init__(self, marker):
        self.marker = marker
        self.pending = b""

    def feed(self, data):
        data = self.pending + data
        self.pending = b""
        parts = data.split(self.marker)
        tail = parts[-1]
        for size in range(min(len(tail), len(self.marker) - 1), 0, -1):
            if tail.endswith(self.marker[:size]):
                self.pending = tail[-size:]
                parts[-1] = tail[:-size]
                break
        return b"".join(parts), len(parts) > 1


def remote_command(token):
    # Hooks and prompt changes live only in this child fish session. A marker
    # is emitted once per completed command, not on redraws or completions.
    init = f"""
set -g __torvus_ready 1
function __torvus_postexec --on-event fish_postexec
    set -g __torvus_ready 1
end
function __torvus_cancel --on-event fish_cancel
    set -g __torvus_ready 1
end
function fish_prompt
    printf 'torvus> '
    if test "$__torvus_ready" = 1
        set -g __torvus_ready 0
        printf '\\e]777;{token}\\a'
    end
end
function fish_right_prompt; end
function fish_mode_prompt; end
"""
    return "exec fish --interactive --init-command " + shlex.quote(init)


async def connect():
    loop = asyncio.get_running_loop()
    events = asyncio.Queue()
    original = termios.tcgetattr(0)
    token = secrets.token_hex(24)
    stream = MarkerStream(f"\x1b]777;{token}\x07".encode())
    bindings = KeyBindings()

    @bindings.add("c-]", eager=True)
    @bindings.add("tab", eager=True)
    def handoff(event):
        # Preserve the buffer; fish owns cursor movement/completion from here.
        suffix = "\t" if event.key_sequence[0].key == "c-i" else ""
        event.app.exit(result=(event.current_buffer.text, suffix))

    output = create_output(always_prefer_tty=True)
    # No cursor-position query: SSH responses belong to the remote application.
    output.enable_cpr = False
    session = PromptSession(
        "torvus [local]> ", key_bindings=bindings, erase_when_done=True,
        output=output,
    )  # Default history is in memory only; never saved on the client.
    pid, master = pty.fork()
    if pid == 0:
        os.execvp("ssh", ["ssh", "-tt", "torvus", remote_command(token)])
    os.set_blocking(master, False)

    editor = None
    reaped = False
    output_tail = b""
    prompt_text = "torvus [local]> "

    def resize():
        size = fcntl.ioctl(0, termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(master, termios.TIOCSWINSZ, size)

    # prompt_toolkit owns SIGWINCH while editing; propagate its redraw size too.
    session.app.before_render += lambda _: resize()

    def read(fd, kind):
        try:
            data = os.read(fd, 65536)
        except BlockingIOError:
            return
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b""
        if not data:
            loop.remove_reader(fd)
        events.put_nowait((kind, data))

    async def send(data):
        # A large paste must not block the loop that drains SSH's output.
        remaining = memoryview(data)
        while remaining:
            try:
                remaining = remaining[os.write(master, remaining):]
            except BlockingIOError:
                ready = loop.create_future()
                loop.add_writer(master, lambda: ready.done() or ready.set_result(None))
                try:
                    await ready
                finally:
                    loop.remove_writer(master)

    def raw_input():
        tty.setraw(0, termios.TCSANOW)
        loop.add_signal_handler(signal.SIGWINCH, resize)
        loop.add_reader(0, read, 0, "input")

    async def edit():
        while True:
            try:
                result = await session.prompt_async(prompt_text, handle_sigint=False)
                if isinstance(result, str):
                    result = (result, "\r")
                break
            except KeyboardInterrupt:
                continue
            except EOFError:
                result = ("", "\x04")
                break
        # Keys typed immediately after Enter/Tab can already be in the local
        # editor's queue. They belong to SSH now, not the next local prompt.
        extra = "".join(key.data for key in get_typeahead(session.app.input))
        events.put_nowait(("line", (*result, extra)))

    try:
        resize()
        loop.add_signal_handler(signal.SIGWINCH, resize)
        for sig in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, events.put_nowait, ("signal", sig))
        loop.add_reader(master, read, master, "output")
        raw_input()
        while True:
            kind, data = await events.get()
            if kind == "signal":
                return 128 + data
            if kind == "input":
                if not data:
                    return 0
                await send(data)
            elif kind == "line":
                await editor
                editor = None
                raw_input()
                text, suffix, extra = data
                os.write(1, b"\r\x1b[2Ktorvus> ")
                # Bracketed paste keeps multiline input together in fish.
                payload = text.encode()
                if payload:
                    payload = b"\x1b[200~" + payload + b"\x1b[201~"
                await send(payload + (suffix + extra).encode())
            elif kind == "output":
                if not data:
                    if stream.pending:
                        os.write(1, stream.pending)
                    _, status = await asyncio.to_thread(os.waitpid, pid, 0)
                    reaped = True
                    return os.waitstatus_to_exitcode(status)
                visible, prompt = stream.feed(data)
                output_tail = (output_tail + visible)[-16384:]
                paths = re.findall(rb"\x1b\]7;([^\x07\x1b]*)(?:\x07|\x1b\\)", output_tail)
                if paths:
                    path = unquote(urlsplit(paths[-1].decode(errors="replace")).path)
                    # A directory name must not inject terminal controls.
                    path = "".join(c if c.isprintable() else "?" for c in path)
                    prompt_text = f"torvus:{path} [local]> "
                if visible:
                    if editor is not None:
                        await run_in_terminal(lambda: os.write(1, visible))
                    else:
                        os.write(1, visible)
                if prompt and editor is None:
                    loop.remove_reader(0)
                    termios.tcsetattr(0, termios.TCSANOW, original)
                    os.write(1, b"\r\x1b[2K")
                    editor = asyncio.create_task(edit())
    finally:
        loop.remove_reader(0)
        loop.remove_reader(master)
        if editor is not None:
            editor.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await editor
        for sig in (signal.SIGWINCH, signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
            loop.remove_signal_handler(sig)
        termios.tcsetattr(0, termios.TCSANOW, original)
        os.close(master)
        if not reaped:
            with contextlib.suppress(ProcessLookupError):
                os.kill(pid, signal.SIGKILL)
            await asyncio.to_thread(os.waitpid, pid, 0)


def main():
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        print("torvus --ssh needs a terminal; use ssh torvus for pipes.", file=sys.stderr)
        return 2
    print("Local shell editing; Tab: fish completion; Ctrl-]: remote editing.\n"
          "Commands and password prompts use normal SSH input.", flush=True)
    return asyncio.run(connect())


if __name__ == "__main__":
    sys.exit(main())
