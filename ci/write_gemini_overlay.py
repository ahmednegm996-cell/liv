#!/usr/bin/env python3
from pathlib import Path
import base64
d = Path("ci/chunks_gemini")
parts = []
for p in sorted(d.glob("*.txt")):
    parts.append(p.read_text().strip())
data = base64.b64decode("".join(parts))
for dest in ['lib/services/gemini_service.dart', 'ci/overlays/lib/services/gemini_service.dart']:
    path = Path(dest)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    print("wrote", path, len(data))
