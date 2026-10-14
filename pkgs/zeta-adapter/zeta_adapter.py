#!/usr/bin/env python3
"""Zeta prompt adapter: LSP-AI FIM/text-completion -> Zeta 2.1 Multi-Region SPM.

LSP-AI (Helix) speaks standard FIM; Zeta expects Zed's suffix-first Multi-Region
prompt with <|marker_1|>/<|user_cursor|>/<|marker_2|> tags. This bridges them:
it parses the incoming completion request, rebuilds the Zeta prompt around the
current line, calls the real llama.cpp server, and returns only the inserted
text in OpenAI completion shape.
"""

import json
import os
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

FIM_PREFIX = "<[fim-prefix]>"
FIM_SUFFIX = "<[fim-suffix]>"
FIM_MIDDLE = "<[fim-middle]>"
MARKER_1 = "<|marker_1|>"
MARKER_2 = "<|marker_2|>"
CURSOR = "<|user_cursor|>"

UPSTREAM_URL = os.environ.get("ZETA_UPSTREAM", "http://127.0.0.1:8097/v1/completions")
UPSTREAM_KEY = os.environ.get("LLAMA_API_KEY", "")
AUTH_TOKEN = os.environ.get("ZETA_ADAPTER_TOKEN") or UPSTREAM_KEY
LISTEN_HOST = os.environ.get("ZETA_ADAPTER_HOST", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("ZETA_ADAPTER_PORT", "8098"))


def split_fim(prompt):
    """Return (prefix, suffix) from an LSP-AI FIM prompt, or plain text fallback."""
    if FIM_SUFFIX in prompt:
        before, after = prompt.split(FIM_SUFFIX, 1)
        before = before.split(FIM_PREFIX, 1)[1] if FIM_PREFIX in before else before
        after = after.split(FIM_MIDDLE, 1)[0]
        return before, after
    if FIM_PREFIX in prompt:
        prompt = prompt.split(FIM_PREFIX, 1)[1]
    return prompt.split(FIM_MIDDLE, 1)[0], ""


def build_prompt(prefix, suffix, filename="current_file"):
    """Build the Zeta Multi-Region prompt and return it with the original region."""
    nl = prefix.rfind("\n")
    if nl == -1:
        code_before, region = "", prefix
    else:
        code_before, region = prefix[: nl + 1], prefix[nl + 1 :]
    prompt = (
        FIM_SUFFIX
        + "\n"
        + suffix
        + "\n"
        + FIM_PREFIX
        + "<filename>"
        + filename
        + "\n"
        + code_before
        + MARKER_1
        + "\n"
        + region
        + CURSOR
        + "\n"
        + MARKER_2
        + "\n"
        + FIM_MIDDLE
    )
    return prompt, region


def extract(text, original_region):
    """Pull the rewritten region out of the model output and strip the echoed input."""
    if MARKER_1 in text:
        text = text.split(MARKER_1, 1)[1]
    if MARKER_2 in text:
        text = text.split(MARKER_2, 1)[0]
    text = text.replace(CURSOR, "")
    if text.startswith("\n"):
        text = text[1:]
    if original_region and text.startswith(original_region):
        text = text[len(original_region) :]
    return text


def upstream(prompt, max_tokens, stop):
    body = {
        "prompt": prompt,
        "max_tokens": max_tokens,
        "temperature": 0,
        "stop": [MARKER_2] + list(stop),
    }
    req = urllib.request.Request(
        UPSTREAM_URL,
        data=json.dumps(body).encode(),
        headers={
            "content-type": "application/json",
            "authorization": "Bearer " + UPSTREAM_KEY,
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.load(resp)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # noqa: A002
        pass

    def _send(self, code, payload):
        data = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.rstrip("/") == "/health":
            self._send(200, {"status": "ok"})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        if AUTH_TOKEN:
            supplied = (
                self.headers.get("authorization", "").removeprefix("Bearer ").strip()
            )
            if supplied != AUTH_TOKEN:
                self._send(401, {"error": "unauthorized"})
                return
        try:
            length = int(self.headers.get("content-length", "0"))
            req = json.loads(self.rfile.read(length) or b"{}")
            prefix, suffix = split_fim(req.get("prompt", ""))
            zeta_prompt, region = build_prompt(
                prefix, suffix, req.get("file", "current_file")
            )
            max_tokens = min(int(req.get("max_tokens", 256)), 1024)
            stop = req.get("stop") or []
            if isinstance(stop, str):
                stop = [stop]
            result = upstream(zeta_prompt, max_tokens, stop)
            text = extract(result["choices"][0]["text"], region)
            self._send(
                200, {"choices": [{"text": text, "index": 0, "finish_reason": "stop"}]}
            )
        except Exception as exc:  # noqa: BLE001
            self._send(500, {"error": str(exc)})


def self_test():
    prefix = "def add(a, b):\n    return a"
    suffix = " + b\n"
    prompt, region = build_prompt(prefix, suffix, "math.py")
    assert prompt.startswith(FIM_SUFFIX + "\n + b\n")
    assert MARKER_1 in prompt and region == "    return a"
    out = extract(MARKER_1 + region + " + b\n" + MARKER_2 + "\n", region)
    assert out == " + b\n", repr(out)
    assert split_fim(FIM_PREFIX + prefix + FIM_SUFFIX + suffix + FIM_MIDDLE) == (
        prefix,
        suffix,
    )
    print("zeta-adapter self-test ok")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler).serve_forever()
