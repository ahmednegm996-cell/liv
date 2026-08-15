#!/usr/bin/env python3
"""Decompress AI overlays that survive ZIP lib restore."""
from pathlib import Path
import base64
import zlib

ROOT = Path(__file__).resolve().parent

def expand(zb64_name: str, rel: str):
    p = ROOT / zb64_name
    data = zlib.decompress(base64.b64decode(p.read_text().strip()))
    for base in (ROOT / "overlays" / "lib", Path("lib")):
        dest = base / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"expand: {dest} ({len(data)} bytes)")

expand("gemini_overlay.zb64", "services/gemini_service.dart")
expand("ai_chat_overlay.zb64", "screens/ai_chat_screen.dart")
print("expand_ai_overlay done")
