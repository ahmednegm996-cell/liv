#!/usr/bin/env python3
from pathlib import Path
import base64
d = Path("ci/chunks_ai")
parts = []
for p in sorted(d.glob("*.txt")):
    parts.append(p.read_text().strip())
data = base64.b64decode("".join(parts))
for dest in ['lib/screens/ai_chat_screen.dart', 'ci/overlays/lib/screens/ai_chat_screen.dart']:
    path = Path(dest)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    print("wrote", path, len(data))
