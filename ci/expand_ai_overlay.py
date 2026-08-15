#!/usr/bin/env python3
"""Expand AI overlays that survive ZIP lib restore."""
from pathlib import Path
import base64
import sys

ROOT = Path(__file__).resolve().parent
out_root = ROOT / "overlays" / "lib"

def write(rel: str, b64_name: str):
    b64_path = ROOT / b64_name
    if not b64_path.exists():
        print(f"expand_ai_overlay: missing {b64_path}")
        return False
    data = base64.b64decode(b64_path.read_text().strip())
    dest = out_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    print(f"expand_ai_overlay: wrote {dest} ({len(data)} bytes)")
    return True

ok1 = write("services/gemini_service.dart", "gemini_overlay.b64")
ok2 = write("screens/ai_chat_screen.dart", "ai_chat_overlay.b64")
if not (ok1 and ok2):
    sys.exit(1)
print("expand_ai_overlay done")
