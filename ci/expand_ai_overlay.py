#!/usr/bin/env python3
"""Expand AI overlays that survive ZIP lib restore."""
from pathlib import Path
import base64
import sys

ROOT = Path(__file__).resolve().parent
out_root = ROOT / "overlays" / "lib"

def load_b64(stem: str) -> bytes:
    full = ROOT / f"{stem}.b64"
    if full.exists():
        return base64.b64decode(full.read_text().strip())
    p1 = ROOT / f"{stem}.b64.part1"
    p2 = ROOT / f"{stem}.b64.part2"
    if p1.exists() and p2.exists():
        return base64.b64decode((p1.read_text() + p2.read_text()).replace("\n", "").strip())
    raise FileNotFoundError(stem)

def write(rel: str, stem: str):
    data = load_b64(stem)
    dest = out_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    lib_dest = Path("lib") / rel
    lib_dest.parent.mkdir(parents=True, exist_ok=True)
    lib_dest.write_bytes(data)
    print(f"expand_ai_overlay: wrote {dest} and {lib_dest} ({len(data)} bytes)")

write("services/gemini_service.dart", "gemini_overlay")
write("screens/ai_chat_screen.dart", "ai_chat_overlay")
print("expand_ai_overlay done")
