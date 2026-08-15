#!/usr/bin/env python3
"""Decompress AI overlays that survive ZIP lib restore."""
from pathlib import Path
import base64
import zlib

ROOT = Path(__file__).resolve().parent

def load_zb64(stem: str) -> bytes:
    full = ROOT / f"{stem}.zb64"
    if full.exists() and full.stat().st_size > 100:
        raw = full.read_text().strip()
    else:
        p1 = ROOT / f"{stem}.zb64.p1"
        p2 = ROOT / f"{stem}.zb64.p2"
        raw = (p1.read_text() + p2.read_text()).replace("\n", "").strip()
    return zlib.decompress(base64.b64decode(raw))

def expand(stem: str, rel: str):
    data = load_zb64(stem)
    for base in (ROOT / "overlays" / "lib", Path("lib")):
        dest = base / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"expand: {dest} ({len(data)} bytes)")

expand("gemini_overlay", "services/gemini_service.dart")
expand("ai_chat_overlay", "screens/ai_chat_screen.dart")
print("expand_ai_overlay done")
