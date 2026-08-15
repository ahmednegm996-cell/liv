#!/usr/bin/env python3
"""Safely expand AI overlays that survive ZIP lib restore.

Prefer already-committed non-empty overlay .dart files under ci/overlays/lib.
Only fall back to zb64 when the overlay file is missing/empty.
Never raise on corrupt zb64 — print and continue so the build can finish
and feature_patch can still apply the good sources.
"""
from pathlib import Path
import base64
import zlib

ROOT = Path(__file__).resolve().parent


def try_load_zb64(stem: str):
    """Return decompressed bytes or None on any failure."""
    try:
        full = ROOT / f"{stem}.zb64"
        if full.exists() and full.stat().st_size > 100:
            raw = full.read_text(encoding="utf-8", errors="replace").strip()
        else:
            p1 = ROOT / f"{stem}.zb64.p1"
            p2 = ROOT / f"{stem}.zb64.p2"
            if not p1.exists() or not p2.exists():
                print(f"zb64: missing parts for {stem}")
                return None
            if p1.stat().st_size < 50 or p2.stat().st_size < 50:
                print(f"zb64: empty/too-small parts for {stem}")
                return None
            raw = (p1.read_text(encoding="utf-8", errors="replace") +
                   p2.read_text(encoding="utf-8", errors="replace")).replace("\n", "").strip()
        if not raw:
            return None
        return zlib.decompress(base64.b64decode(raw))
    except Exception as e:
        print(f"zb64 load failed for {stem}: {type(e).__name__}: {e}")
        return None


def expand(stem: str, rel: str, required_markers):
    """required_markers: list of strings that must appear in a valid source."""
    if isinstance(required_markers, str):
        required_markers = [required_markers]

    overlay_path = ROOT / "overlays" / "lib" / rel
    lib_path = Path("lib") / rel

    # 1) Prefer existing good committed overlay file
    if overlay_path.exists() and overlay_path.stat().st_size > 500:
        try:
            text = overlay_path.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            print(f"expand: cannot read {overlay_path}: {e}")
            text = ""
        if all(m in text for m in required_markers):
            # Extra safety for gemini: require a method that the incomplete
            # stub was missing, so we do not overwrite the full ZIP version.
            if rel.endswith("gemini_service.dart") and "generateDreamSteps" not in text:
                print(f"expand: overlay {overlay_path} is incomplete (no generateDreamSteps) — keeping ZIP version")
            else:
                print(f"expand: using existing good overlay {overlay_path} ({overlay_path.stat().st_size} bytes)")
                lib_path.parent.mkdir(parents=True, exist_ok=True)
                lib_path.write_text(text, encoding="utf-8")
                return
        else:
            print(f"expand: overlay {overlay_path} missing markers {required_markers}")

    # 2) Fall back to zb64
    data = try_load_zb64(stem)
    if data is None:
        print(f"expand: no valid zb64 for {stem} — skipping (ZIP / feature_patch will provide)")
        return

    try:
        text = data.decode("utf-8")
    except Exception as e:
        print(f"expand: zb64 for {stem} is not valid utf-8: {e}")
        return

    if not all(m in text for m in required_markers):
        print(f"expand: decompressed {stem} missing markers {required_markers} — skipping")
        return

    if rel.endswith("gemini_service.dart") and "generateDreamSteps" not in text:
        print(f"expand: zb64 {stem} incomplete (no generateDreamSteps) — skipping")
        return

    for base in (ROOT / "overlays" / "lib", Path("lib")):
        dest = base / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"expand: wrote {dest} ({len(data)} bytes)")


expand("gemini_overlay", "services/gemini_service.dart", ["personalityInsight", "generateText"])
expand("ai_chat_overlay", "screens/ai_chat_screen.dart", ["addHabit", "_pendingAction"])
print("expand_ai_overlay done")
